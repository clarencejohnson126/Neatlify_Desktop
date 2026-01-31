//
//  OrganizationViewModel.swift
//  Neatlify
//
//  File organization orchestration view model
//

import Foundation
import SwiftUI

@MainActor
class OrganizationViewModel: ObservableObject {
    @Published var isOrganizing: Bool = false
    @Published var currentStep: OrganizationStep = .idle
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var totalFiles: Int = 0
    @Published var processedFiles: Int = 0
    @Published var showPreview: Bool = false
    @Published var organizationPlan: OrganizationPlan?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var pricingInfo: PricingInfo?
    @Published var showPaywall: Bool = false

    private let apiService = ClaudeAPIService()
    private let fileService = FileService.shared
    private let permissionsService = PermissionsService.shared

    private var scannedFiles: [FileItem] = []
    private var selectedFolderURL: URL?

    struct PricingInfo {
        let totalFiles: Int
        let creditsAvailable: Int
        let isFreeTrialEligible: Bool
        let reason: String
    }

    enum OrganizationStep {
        case idle
        case parsingIntent
        case requestingAccess
        case scanningFiles
        case analyzingFiles
        case creatingPlan
        case awaitingConfirmation
        case organizingFiles
        case completed
    }

    func startOrganization(userMessage: String) async {
        isOrganizing = true
        progress = 0.0

        do {
            // Step 1: Parse intent
            try await parseIntent(userMessage)

            // Step 2: Request folder access
            try await requestFolderAccess()

            // Step 3: Scan files
            try await scanFiles()

            // Step 4: Analyze files
            try await analyzeFiles()

            // Step 5: Show preview for confirmation
            showPreviewForConfirmation()

        } catch {
            handleError(error)
        }
    }

    private var isExecuting = false  // Prevent double-execution

    func executeOrganization() async {
        // Prevent double-execution
        guard !isExecuting else {
            Logger.shared.info("Organization already in progress, ignoring duplicate call")
            return
        }

        guard let plan = organizationPlan,
              let folderURL = selectedFolderURL else {
            return
        }

        isExecuting = true
        showPreview = false  // Hide preview immediately
        currentStep = .organizingFiles
        statusMessage = "Organizing files..."

        // Start accessing security-scoped resource
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Create organized folder with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let timestamp = dateFormatter.string(from: Date())

            let organizedFolderURL = folderURL.appendingPathComponent("Organized_\(timestamp)")
            try FileManager.default.createDirectory(at: organizedFolderURL, withIntermediateDirectories: true)

            // Create category folders
            let folderMap = try await fileService.createFolders(plan.categories, in: organizedFolderURL)

            // Move files (progress handler is @MainActor)
            try await fileService.organizeFiles(scannedFiles, plan: plan, folderMap: folderMap) { @MainActor processed, total in
                self.processedFiles = processed
                self.totalFiles = total
                self.progress = Double(processed) / Double(total)
                self.statusMessage = "Moving files... \(processed)/\(total)"
            }

            // Deduct credits server-side (or mark free trial used locally)
            let session = UserSession.load()
            let fileCount = scannedFiles.count

            if session.isAccountLinked {
                // Server-side credit deduction
                let deductSuccess = await session.deductCreditsServerSide(fileCount: fileCount)
                if !deductSuccess {
                    Logger.shared.error("Warning: Server-side credit deduction failed")
                    // Continue anyway - files are already moved
                }
            } else {
                // Local free trial tracking
                session.recordCleanup(fileCount: fileCount)
                session.save()
            }

            // Update local stats
            session.totalCleanupsPerformed += 1
            session.totalFilesProcessed += fileCount
            session.lastCleanupDate = Date()
            session.save()

            // Complete
            currentStep = .completed
            statusMessage = "Organization complete! \(processedFiles) files organized."
            isExecuting = false

            // Log usage
            APIKeyManager.logUsage(fileCount: processedFiles, tokensUsed: 0)

        } catch {
            isExecuting = false
            handleError(error)
        }
    }

    func cancelOrganization() {
        isOrganizing = false
        currentStep = .idle
        showPreview = false
        organizationPlan = nil
        scannedFiles.removeAll()
        selectedFolderURL = nil
    }

    func reset() {
        isOrganizing = false
        isExecuting = false
        currentStep = .idle
        progress = 0.0
        statusMessage = ""
        totalFiles = 0
        processedFiles = 0
        showPreview = false
        organizationPlan = nil
        scannedFiles.removeAll()
        selectedFolderURL = nil
    }

    // MARK: - Private Methods

    private func parseIntent(_ message: String) async throws {
        currentStep = .parsingIntent
        statusMessage = "Understanding your request..."
        progress = 0.1

        let intent = try await apiService.parseIntent(message)
        Logger.shared.info("Parsed intent: \(intent.criteria)")

        // Store intent for later use
        self.organizationPlan = OrganizationPlan(
            sourceFolder: URL(fileURLWithPath: "/tmp"),
            criteria: intent.criteria,
            categories: intent.suggestedCategories,
            fileAssignments: [:],
            suggestedFolderStructure: [:]
        )
    }

    private func requestFolderAccess() async throws {
        currentStep = .requestingAccess
        statusMessage = "Requesting folder access..."
        progress = 0.2

        guard let url = await permissionsService.requestFolderAccess(
            message: "Select the folder you want to organize"
        ) else {
            throw OrganizationError.accessDenied
        }

        selectedFolderURL = url
        Logger.shared.info("Folder selected: \(url.path)")
    }

    private func scanFiles() async throws {
        guard let folderURL = selectedFolderURL else {
            throw OrganizationError.noFolderSelected
        }

        currentStep = .scanningFiles
        statusMessage = "Scanning files..."
        progress = 0.3

        // Start accessing security-scoped resource
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        scannedFiles = try await fileService.scanFolder(folderURL, includeSubfolders: false)

        // Filter to only images and PDFs
        scannedFiles = fileService.filterFiles(scannedFiles, types: [.image, .pdf])

        guard !scannedFiles.isEmpty else {
            throw OrganizationError.noFilesFound
        }

        totalFiles = scannedFiles.count
        statusMessage = "Found \(totalFiles) files to organize"

        Logger.shared.info("Scanned \(scannedFiles.count) files")
    }

    private func analyzeFiles() async throws {
        guard let plan = organizationPlan else {
            throw OrganizationError.noPlan
        }

        guard let folderURL = selectedFolderURL else {
            throw OrganizationError.noFolderSelected
        }

        currentStep = .analyzingFiles
        statusMessage = "Analyzing files with AI..."
        progress = 0.4

        // Start accessing security-scoped resource
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        var fileAssignments: [UUID: String] = [:]
        var categoryCounts: [String: Int] = [:]

        // Initialize category counts
        for category in plan.categories {
            categoryCounts[category] = 0
        }

        // Separate images and PDFs
        let images = scannedFiles.filter { $0.fileType == .image }
        let pdfs = scannedFiles.filter { $0.fileType == .pdf }

        // Process images in batches of 10 (reduced to avoid rate limits)
        if !images.isEmpty {
            statusMessage = "Analyzing \(images.count) images..."

            let imageBatches = images.chunked(into: 10)

            for (index, batch) in imageBatches.enumerated() {
                // Encode images
                let encodedImages = try await ImageProcessor.encodeImages(at: batch.map { $0.url })

                // Prepare for API
                let imageData = encodedImages.map { (filename: $0.url.lastPathComponent, base64: $0.base64) }

                // Analyze batch
                let results = try await apiService.analyzeImages(
                    imageData,
                    criteria: plan.criteria,
                    categories: plan.categories
                )

                // Map results to FileItems
                for file in batch {
                    if let category = results[file.name] {
                        fileAssignments[file.id] = category
                        categoryCounts[category, default: 0] += 1
                    }
                }

                // Update progress
                let batchProgress = Double(index + 1) / Double(imageBatches.count)
                progress = 0.4 + (batchProgress * 0.3) // 40% to 70%
                let processedCount = min((index + 1) * 10, images.count)
                statusMessage = "Analyzing images... \(processedCount)/\(images.count)"

                // Small delay between batches to avoid rate limits
                if index < imageBatches.count - 1 {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                }
            }
        }

        // Process PDFs in batches of 5 (reduced to avoid rate limits)
        if !pdfs.isEmpty {
            statusMessage = "Analyzing \(pdfs.count) PDFs..."

            let pdfBatches = pdfs.chunked(into: 5)

            for (index, batch) in pdfBatches.enumerated() {
                // Extract text from PDFs
                var textData: [(filename: String, content: String)] = []

                for pdf in batch {
                    if let text = PDFProcessor.extractText(from: pdf.url, maxPages: 5) {
                        textData.append((filename: pdf.name, content: text))
                    }
                }

                if !textData.isEmpty {
                    // Analyze batch
                    let results = try await apiService.analyzeText(
                        textData,
                        criteria: plan.criteria,
                        categories: plan.categories
                    )

                    // Map results to FileItems
                    for file in batch {
                        if let category = results[file.name] {
                            fileAssignments[file.id] = category
                            categoryCounts[category, default: 0] += 1
                        }
                    }
                }

                // Update progress
                let batchProgress = Double(index + 1) / Double(pdfBatches.count)
                progress = 0.7 + (batchProgress * 0.2) // 70% to 90%
                let processedCount = min((index + 1) * 5, pdfs.count)
                statusMessage = "Analyzing PDFs... \(processedCount)/\(pdfs.count)"

                // Small delay between batches
                if index < pdfBatches.count - 1 {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                }
            }
        }

        // Create final plan
        self.organizationPlan = OrganizationPlan(
            sourceFolder: selectedFolderURL!,
            criteria: plan.criteria,
            categories: plan.categories,
            fileAssignments: fileAssignments,
            suggestedFolderStructure: categoryCounts
        )

        progress = 0.9
    }

    private func showPreviewForConfirmation() {
        let totalCount = scannedFiles.count
        let userSession = UserSession.load()

        // Check hard cap first
        if totalCount > UserSession.maxFilesPerCleanup {
            errorMessage = "Maximum \(UserSession.maxFilesPerCleanup) files per cleanup. Please select fewer files."
            showError = true
            isOrganizing = false
            currentStep = .idle
            return
        }

        // SIMPLE CHECK: If user has enough local credits, allow it
        // This prevents paywall from showing when user clearly has credits
        if userSession.fileCredits >= totalCount {
            Logger.shared.info("Local credits sufficient: \(userSession.fileCredits) >= \(totalCount)")
            pricingInfo = PricingInfo(
                totalFiles: totalCount,
                creditsAvailable: userSession.fileCredits,
                isFreeTrialEligible: false,
                reason: "Will use \(totalCount) of \(userSession.fileCredits) credits"
            )
            currentStep = .awaitingConfirmation
            statusMessage = "Review organization plan"
            progress = 1.0
            showPreview = true
            return
        }

        // Free trial check (if never used and within limit)
        if !userSession.hasUsedFreeCleanup && totalCount <= UserSession.freeCleanupFileLimit {
            Logger.shared.info("Free trial eligible: \(totalCount) files")
            pricingInfo = PricingInfo(
                totalFiles: totalCount,
                creditsAvailable: userSession.fileCredits,
                isFreeTrialEligible: true,
                reason: "Free trial: \(totalCount) of \(UserSession.freeCleanupFileLimit) files"
            )
            currentStep = .awaitingConfirmation
            statusMessage = "Review organization plan"
            progress = 1.0
            showPreview = true
            return
        }

        // If account is linked, try server check (but with fallback)
        if userSession.isAccountLinked {
            Task {
                statusMessage = "Verifying credits..."

                let (serverAllowed, serverReason) = await userSession.canPerformCleanupServerSide(fileCount: totalCount)

                await MainActor.run {
                    if serverAllowed {
                        // Server approved
                        self.pricingInfo = PricingInfo(
                            totalFiles: totalCount,
                            creditsAvailable: userSession.fileCredits,
                            isFreeTrialEligible: false,
                            reason: serverReason ?? "Credits verified"
                        )
                        self.currentStep = .awaitingConfirmation
                        self.statusMessage = "Review organization plan"
                        self.progress = 1.0
                        self.showPreview = true
                    } else {
                        // Server denied - show paywall
                        Logger.shared.info("Server denied: \(serverReason ?? "unknown")")
                        self.showPaywall = true
                        self.isOrganizing = false
                        self.currentStep = .idle
                    }
                }
            }
        } else {
            // No account linked and no credits - show paywall
            Logger.shared.info("No account linked, no credits, trial used")
            showPaywall = true
            isOrganizing = false
            currentStep = .idle
        }
    }

    private func handleError(_ error: Error) {
        Logger.shared.error("Organization error", error: error)

        errorMessage = error.localizedDescription
        showError = true
        isOrganizing = false
        currentStep = .idle
    }

    enum OrganizationError: LocalizedError {
        case accessDenied
        case noFolderSelected
        case noFilesFound
        case noPlan
        case analysisFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Folder access was denied"
            case .noFolderSelected:
                return "No folder selected"
            case .noFilesFound:
                return "No image or PDF files found in the selected folder"
            case .noPlan:
                return "No organization plan available"
            case .analysisFailed:
                return "Failed to analyze files"
            }
        }
    }
}

// Helper extension to chunk arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
