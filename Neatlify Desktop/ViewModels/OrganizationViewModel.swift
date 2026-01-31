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
    private var userSpecifiedFolderPath: String?
    private var conversationHistory: [ChatMessage] = []  // For context memory within session

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

    func startOrganization(userMessage: String, conversationHistory: [ChatMessage] = []) async {
        isOrganizing = true
        progress = 0.0

        // Store conversation history for context
        self.conversationHistory = conversationHistory
        Logger.shared.info("Starting organization with \(conversationHistory.count) messages of context")

        do {
            // Step 1: Parse intent (with conversation history for context)
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

        // Start accessing security-scoped resource
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Branch based on mode
            if plan.mode == .label {
                // LABEL MODE: Rename files in place
                statusMessage = "Renaming files..."

                try await fileService.labelFiles(scannedFiles, plan: plan) { @MainActor processed, total in
                    self.processedFiles = processed
                    self.totalFiles = total
                    self.progress = Double(processed) / Double(total)
                    self.statusMessage = "Renaming files... \(processed)/\(total)"
                }

                statusMessage = "Labeling complete! \(processedFiles) files renamed."

            } else {
                // ORGANIZE MODE: Move files into folders
                statusMessage = "Organizing files..."

                let folderMap: [String: URL]

                if plan.categories.count == 1 {
                    // Single category: create folder directly in source folder
                    let categoryName = plan.categories[0]
                    let categoryURL = folderURL.appendingPathComponent(categoryName)
                    if !FileManager.default.fileExists(atPath: categoryURL.path) {
                        try FileManager.default.createDirectory(at: categoryURL, withIntermediateDirectories: true)
                    }
                    folderMap = [categoryName: categoryURL]
                    Logger.shared.info("Single category mode: creating '\(categoryName)' directly")
                } else {
                    // Multiple categories: create timestamped parent folder
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
                    let timestamp = dateFormatter.string(from: Date())

                    let organizedFolderURL = folderURL.appendingPathComponent("Organized_\(timestamp)")
                    try FileManager.default.createDirectory(at: organizedFolderURL, withIntermediateDirectories: true)

                    folderMap = try await fileService.createFolders(plan.categories, in: organizedFolderURL)
                    Logger.shared.info("Multi-category mode: creating \(plan.categories.count) folders in Organized_\(timestamp)")
                }

                try await fileService.organizeFiles(scannedFiles, plan: plan, folderMap: folderMap) { @MainActor processed, total in
                    self.processedFiles = processed
                    self.totalFiles = total
                    self.progress = Double(processed) / Double(total)
                    self.statusMessage = "Moving files... \(processed)/\(total)"
                }

                statusMessage = "Organization complete! \(processedFiles) files organized."
            }

            // Deduct credits server-side (or mark free trial used locally)
            let session = UserSession.load()
            let fileCount = scannedFiles.count

            if session.isAccountLinked {
                let deductSuccess = await session.deductCreditsServerSide(fileCount: fileCount)
                if !deductSuccess {
                    Logger.shared.error("Warning: Server-side credit deduction failed")
                }
            } else {
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
        userSpecifiedFolderPath = nil
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
        userSpecifiedFolderPath = nil
    }

    // MARK: - Private Methods

    private func parseIntent(_ message: String) async throws {
        currentStep = .parsingIntent
        statusMessage = "Understanding your request..."
        progress = 0.1

        // Pass conversation history to API for context memory
        let intent = try await apiService.parseIntent(message, conversationHistory: conversationHistory)
        Logger.shared.info("Parsed intent: mode=\(intent.mode.rawValue), criteria=\(intent.criteria), folder=\(intent.folder)")

        // Store user-specified folder path if it looks like an absolute path
        if intent.folder.hasPrefix("/") || intent.folder.hasPrefix("~") {
            userSpecifiedFolderPath = intent.folder.replacingOccurrences(of: "~", with: NSHomeDirectory())
            Logger.shared.info("User specified folder path: \(userSpecifiedFolderPath ?? "none")")
        }

        // Store intent for later use
        self.organizationPlan = OrganizationPlan(
            sourceFolder: URL(fileURLWithPath: "/tmp"),
            criteria: intent.criteria,
            categories: intent.suggestedCategories,
            fileAssignments: [:],
            suggestedFolderStructure: [:],
            mode: intent.mode,
            fileLabels: [:]
        )
    }

    private func requestFolderAccess() async throws {
        currentStep = .requestingAccess
        statusMessage = "Requesting folder access..."
        progress = 0.2

        // Determine starting location for folder picker
        var startingURL: URL? = nil
        if let specifiedPath = userSpecifiedFolderPath {
            startingURL = URL(fileURLWithPath: specifiedPath)
            Logger.shared.info("Opening folder picker at: \(specifiedPath)")
        }

        // Create appropriate message based on mode
        let plan = organizationPlan
        let message: String
        if plan?.mode == .label {
            message = "Select the folder containing files to label/rename"
        } else {
            message = "Select the folder you want to organize"
        }

        guard let url = await permissionsService.requestFolderAccess(
            message: message,
            startingAt: startingURL
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
        progress = 0.4

        // Start accessing security-scoped resource
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }

        // Branch based on mode
        if plan.mode == .label {
            try await analyzeFilesForLabeling(plan: plan)
        } else {
            try await analyzeFilesForOrganizing(plan: plan)
        }

        progress = 0.9
    }

    // MARK: - Label Mode Analysis

    private func analyzeFilesForLabeling(plan: OrganizationPlan) async throws {
        statusMessage = "Generating labels with AI vision..."

        var fileLabels: [UUID: String] = [:]

        // Only process images for labeling (PDFs don't get visual labels)
        let images = scannedFiles.filter { $0.fileType == .image }

        if images.isEmpty {
            throw OrganizationError.noFilesFound
        }

        let imageBatches = images.chunked(into: 10)

        for (index, batch) in imageBatches.enumerated() {
            // Encode images
            let encodedImages = try await ImageProcessor.encodeImages(at: batch.map { $0.url })

            // Prepare for API
            let imageData = encodedImages.map { (filename: $0.url.lastPathComponent, base64: $0.base64) }

            // Generate labels
            let results = try await apiService.generateLabels(imageData, labelStyle: plan.criteria)

            // Map results to FileItems
            for file in batch {
                if let label = results[file.name] {
                    fileLabels[file.id] = label
                    Logger.shared.debug("Label for \(file.name): \(label)")
                }
            }

            // Update progress
            let batchProgress = Double(index + 1) / Double(imageBatches.count)
            progress = 0.4 + (batchProgress * 0.5) // 40% to 90%
            let processedCount = min((index + 1) * 10, images.count)
            statusMessage = "Generating labels... \(processedCount)/\(images.count)"

            // Small delay between batches
            if index < imageBatches.count - 1 {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        // Create final plan with labels
        self.organizationPlan = OrganizationPlan(
            sourceFolder: selectedFolderURL!,
            criteria: plan.criteria,
            categories: [],
            fileAssignments: [:],
            suggestedFolderStructure: [:],
            mode: .label,
            fileLabels: fileLabels
        )

        Logger.shared.info("Generated \(fileLabels.count) labels")
    }

    // MARK: - Organize Mode Analysis

    private func analyzeFilesForOrganizing(plan: OrganizationPlan) async throws {
        statusMessage = "Analyzing files with AI..."

        var fileAssignments: [UUID: String] = [:]
        var categoryCounts: [String: Int] = [:]

        // Initialize category counts
        for category in plan.categories {
            categoryCounts[category] = 0
        }

        // Separate images and PDFs
        let images = scannedFiles.filter { $0.fileType == .image }
        let pdfs = scannedFiles.filter { $0.fileType == .pdf }

        // Process images in batches of 10
        if !images.isEmpty {
            statusMessage = "Analyzing \(images.count) images..."

            let imageBatches = images.chunked(into: 10)

            for (index, batch) in imageBatches.enumerated() {
                let encodedImages = try await ImageProcessor.encodeImages(at: batch.map { $0.url })
                let imageData = encodedImages.map { (filename: $0.url.lastPathComponent, base64: $0.base64) }

                let results = try await apiService.analyzeImages(
                    imageData,
                    criteria: plan.criteria,
                    categories: plan.categories
                )

                for file in batch {
                    if let category = results[file.name] {
                        fileAssignments[file.id] = category
                        categoryCounts[category, default: 0] += 1
                    }
                }

                let batchProgress = Double(index + 1) / Double(imageBatches.count)
                progress = 0.4 + (batchProgress * 0.3)
                let processedCount = min((index + 1) * 10, images.count)
                statusMessage = "Analyzing images... \(processedCount)/\(images.count)"

                if index < imageBatches.count - 1 {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }

        // Process PDFs in batches of 5
        if !pdfs.isEmpty {
            statusMessage = "Analyzing \(pdfs.count) PDFs..."

            let pdfBatches = pdfs.chunked(into: 5)

            for (index, batch) in pdfBatches.enumerated() {
                var textData: [(filename: String, content: String)] = []

                for pdf in batch {
                    if let text = PDFProcessor.extractText(from: pdf.url, maxPages: 5) {
                        textData.append((filename: pdf.name, content: text))
                    }
                }

                if !textData.isEmpty {
                    let results = try await apiService.analyzeText(
                        textData,
                        criteria: plan.criteria,
                        categories: plan.categories
                    )

                    for file in batch {
                        if let category = results[file.name] {
                            fileAssignments[file.id] = category
                            categoryCounts[category, default: 0] += 1
                        }
                    }
                }

                let batchProgress = Double(index + 1) / Double(pdfBatches.count)
                progress = 0.7 + (batchProgress * 0.2)
                let processedCount = min((index + 1) * 5, pdfs.count)
                statusMessage = "Analyzing PDFs... \(processedCount)/\(pdfs.count)"

                if index < pdfBatches.count - 1 {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }

        // Create final plan
        self.organizationPlan = OrganizationPlan(
            sourceFolder: selectedFolderURL!,
            criteria: plan.criteria,
            categories: plan.categories,
            fileAssignments: fileAssignments,
            suggestedFolderStructure: categoryCounts,
            mode: .organize,
            fileLabels: [:]
        )
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
