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
    @Published var skippedFiles: [(file: FileItem, reason: String)] = []
    @Published var totalSkipped: Int = 0

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
        let isFreeTrialEligible: Bool  // Deprecated - always false now
        let reason: String
        let sampleFileNames: [String]  // First few file names for preview
        let categoryCounts: [String: Int]  // Category -> file count breakdown
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
                Logger.shared.info("Starting label mode: renaming \(scannedFiles.count) files")

                try await fileService.labelFiles(scannedFiles, plan: plan) { @MainActor processed, total in
                    self.processedFiles = processed
                    self.totalFiles = total
                    self.progress = Double(processed) / Double(total)
                    self.statusMessage = "Renaming files... \(processed)/\(total)"
                }

                statusMessage = "Labeling complete! \(processedFiles) files renamed."
                Logger.shared.info("Label mode complete: \(processedFiles)/\(scannedFiles.count) files renamed")

            } else {
                // ORGANIZE MODE: Move files into folders
                statusMessage = "Organizing files..."
                Logger.shared.info("Starting organize mode: \(scannedFiles.count) files, \(plan.categories.count) categories")

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
                Logger.shared.info("Organize mode complete: \(processedFiles)/\(scannedFiles.count) files moved")
            }

            // Deduct credits server-side
            let fileCount = scannedFiles.count
            let session = UserSession.load()

            if let userEmail = session.userEmail, !userEmail.isEmpty {
                // Deduct credits on server
                do {
                    let result = try await SupabaseService.shared.deductCredits(
                        userEmail: userEmail,
                        fileCount: fileCount
                    )

                    switch result {
                    case .success(let deducted, let remaining):
                        Logger.shared.info("Server deducted \(deducted) credits. Remaining: \(remaining)")
                        // Update local cache
                        session.fileCredits = remaining
                        session.save()

                    case .failed(let reason):
                        Logger.shared.error("Server credit deduction failed: \(reason)")
                    }
                } catch {
                    Logger.shared.error("Credit deduction error: \(error)")
                }
            } else {
                // Local deduction for unlinked accounts
                session.fileCredits = max(0, session.fileCredits - fileCount)
                session.save()
                Logger.shared.info("Local credit deduction: \(fileCount)")
            }

            // Update local stats
            session.totalCleanupsPerformed += 1
            session.totalFilesProcessed += fileCount
            session.lastCleanupDate = Date()

            // Save organization record to history
            let record = OrganizationRecord(
                timestamp: Date(),
                mode: plan.mode,
                sourceFolder: selectedFolderURL?.path ?? "Unknown",
                totalFiles: fileCount,
                filesProcessed: fileCount,
                categories: plan.categories,
                creditsUsed: fileCount,
                status: .completed
            )
            session.saveOrganizationRecord(record)
            session.save()

            // Notify UI to refresh credits from saved state
            NotificationCenter.default.post(name: .creditsDidChange, object: nil)

            // Complete
            currentStep = .completed
            isExecuting = false

            // Post notification for chat to show summary
            let successMessage = """
            Organization complete!
            ✅ Organized: \(processedFiles) files
            📁 Folders created: \(organizationPlan?.suggestedFolderStructure.count ?? 0)
            ⏭️ Skipped: \(totalSkipped) files
            """

            NotificationCenter.default.post(
                name: Notification.Name("OrganizationCompleted"),
                object: nil,
                userInfo: [
                    "message": successMessage,
                    "totalOrganized": processedFiles,
                    "totalSkipped": totalSkipped,
                    "categoryCounts": organizationPlan?.suggestedFolderStructure ?? [:]
                ]
            )

            // Log usage
            APIKeyManager.logUsage(fileCount: processedFiles, tokensUsed: 0)

        } catch {
            isExecuting = false
            handleError(error)
        }
    }

    func cancelOrganization() {
        // Record cancelled organization
        if let plan = organizationPlan, let folderURL = selectedFolderURL {
            let session = UserSession.load()
            let record = OrganizationRecord(
                timestamp: Date(),
                mode: plan.mode,
                sourceFolder: folderURL.path,
                totalFiles: scannedFiles.count,
                filesProcessed: 0,
                categories: plan.categories,
                creditsUsed: 0,
                status: .cancelled
            )
            session.saveOrganizationRecord(record)
        }

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

        Logger.shared.info("Detected language: \(intent.language)")

        // Store intent for later use
        self.organizationPlan = OrganizationPlan(
            sourceFolder: URL(fileURLWithPath: "/tmp"),
            criteria: intent.criteria,
            categories: intent.suggestedCategories,
            fileAssignments: [:],
            suggestedFolderStructure: [:],
            mode: intent.mode,
            fileLabels: [:],
            language: intent.language
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
        Logger.shared.info("Starting label generation for \(scannedFiles.count) files")

        var fileLabels: [UUID: String] = [:]
        var totalSkippedLabeling = 0

        // Only process images for labeling (PDFs don't get visual labels)
        let images = scannedFiles.filter { $0.fileType == .image }

        if images.isEmpty {
            throw OrganizationError.noFilesFound
        }

        // Use larger batches (50 images) to minimize API calls while respecting token limits
        // This is a balance: fewer API calls (better performance, lower cost) vs token limits
        let imageBatches = images.chunked(into: 50)
        Logger.shared.info("Processing \(images.count) images in \(imageBatches.count) batches")

        for (index, batch) in imageBatches.enumerated() {
            statusMessage = "Encoding images batch \(index + 1)/\(imageBatches.count)..."

            // Encode batch images
            let encodedImages = try await ImageProcessor.encodeImages(at: batch.map { $0.url })
            let imageData = encodedImages.map { (filename: $0.url.lastPathComponent, base64: $0.base64) }
            Logger.shared.info("Batch \(index + 1): encoded \(imageData.count)/\(batch.count) images")

            statusMessage = "Generating labels... (batch \(index + 1)/\(imageBatches.count))"

            // Generate labels for this batch (still much more efficient than 1 API call per image)
            let results = try await apiService.generateLabels(imageData, labelStyle: plan.criteria, language: plan.language)

            // Map results to FileItems
            for file in batch {
                if let label = results[file.name] {
                    fileLabels[file.id] = label
                    Logger.shared.debug("Label for \(file.name): \(label)")
                } else {
                    totalSkippedLabeling += 1
                    Logger.shared.warning("No label generated for \(file.name)")
                }
            }

            // Update progress
            let batchProgress = Double(index + 1) / Double(imageBatches.count)
            progress = 0.4 + (batchProgress * 0.5)  // 40% to 90%

            // Small delay between batches to avoid overwhelming the system
            if index < imageBatches.count - 1 {
                try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second delay
            }
        }

        progress = 0.9
        Logger.shared.info("Label generation complete: \(fileLabels.count) labeled, \(totalSkippedLabeling) skipped")

        // Create final plan with labels
        self.organizationPlan = OrganizationPlan(
            sourceFolder: selectedFolderURL!,
            criteria: plan.criteria,
            categories: [],
            fileAssignments: [:],
            suggestedFolderStructure: [:],
            mode: .label,
            fileLabels: fileLabels,
            language: plan.language
        )

        self.totalSkipped = totalSkippedLabeling
    }

    // MARK: - Organize Mode Analysis

    private func analyzeFilesForOrganizing(plan: OrganizationPlan) async throws {
        statusMessage = "Analyzing files with AI..."
        Logger.shared.info("Starting organization analysis: \(scannedFiles.count) files, criteria: \(plan.criteria)")

        var fileAssignments: [UUID: String] = [:]
        var categoryCounts: [String: Int] = [:]

        // Initialize category counts
        for category in plan.categories {
            categoryCounts[category] = 0
        }

        // Separate images and PDFs
        let images = scannedFiles.filter { $0.fileType == .image }
        let pdfs = scannedFiles.filter { $0.fileType == .pdf }

        Logger.shared.info("File breakdown: \(images.count) images, \(pdfs.count) PDFs")

        guard !images.isEmpty || !pdfs.isEmpty else {
            throw OrganizationError.noFilesFound
        }

        // Encode all images upfront
        var allImageData: [(filename: String, base64: String)] = []
        if !images.isEmpty {
            statusMessage = "Encoding \(images.count) images..."
            let encodedImages = try await ImageProcessor.encodeImages(at: images.map { $0.url })
            allImageData = encodedImages.map { (filename: $0.url.lastPathComponent, base64: $0.base64) }
            Logger.shared.info("Successfully encoded \(allImageData.count) images")
        }

        // Extract text from all PDFs upfront
        var allTextData: [(filename: String, content: String)] = []
        if !pdfs.isEmpty {
            statusMessage = "Extracting text from \(pdfs.count) PDFs..."
            var extractedCount = 0
            for pdf in pdfs {
                if let text = PDFProcessor.extractText(from: pdf.url, maxPages: 5) {
                    allTextData.append((filename: pdf.name, content: text))
                    extractedCount += 1
                }
            }
            Logger.shared.info("Successfully extracted text from \(extractedCount)/\(pdfs.count) PDFs")
        }

        statusMessage = "Analyzing \(images.count) images and \(pdfs.count) documents..."
        progress = 0.4

        // CRITICAL OPTIMIZATION: Process ALL files in a single API call instead of batching
        // This reduces from potentially many calls down to just 1-2 calls max
        Logger.shared.info("Sending \(allImageData.count + allTextData.count) files to Claude for categorization")
        let results = try await apiService.analyzeMixedFiles(
            images: allImageData,
            texts: allTextData,
            criteria: plan.criteria,
            categories: plan.categories
        )

        Logger.shared.info("Claude returned categories for \(results.count) files")

        // Map results back to file IDs
        for file in scannedFiles {
            if let category = results[file.name] {
                fileAssignments[file.id] = category
                categoryCounts[category, default: 0] += 1
            } else {
                // Track skipped files and assign fallback category
                skippedFiles.append((file: file, reason: "No category assigned by AI"))
                totalSkipped += 1
                Logger.shared.warning("File '\(file.name)' has no category from Claude, using fallback")

                // Assign to "Uncategorized" folder as fallback
                let fallbackCategory = "Uncategorized"
                fileAssignments[file.id] = fallbackCategory
                categoryCounts[fallbackCategory, default: 0] += 1
            }
        }

        Logger.shared.info("Category assignment complete: \(fileAssignments.count) assigned, \(totalSkipped) skipped")
        for (category, count) in categoryCounts.sorted(by: { $0.key < $1.key }) {
            Logger.shared.debug("  \(category): \(count) files")
        }

        progress = 0.9
        statusMessage = "Categorization complete"

        // Create final plan
        self.organizationPlan = OrganizationPlan(
            sourceFolder: selectedFolderURL!,
            criteria: plan.criteria,
            categories: plan.categories,
            fileAssignments: fileAssignments,
            suggestedFolderStructure: categoryCounts,
            mode: .organize,
            fileLabels: [:],
            language: plan.language
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

        // Prepare preview data (sample file names and category breakdown)
        let sampleNames = Array(scannedFiles.prefix(5).map { $0.name })
        let categoryCounts = organizationPlan?.suggestedFolderStructure ?? [:]

        // If user has enough local credits, allow organization
        if userSession.fileCredits >= totalCount {
            Logger.shared.info("Local credits sufficient: \(userSession.fileCredits) >= \(totalCount)")
            pricingInfo = PricingInfo(
                totalFiles: totalCount,
                creditsAvailable: userSession.fileCredits,
                isFreeTrialEligible: false,
                reason: "Will use \(totalCount) of \(userSession.fileCredits) credits",
                sampleFileNames: sampleNames,
                categoryCounts: categoryCounts
            )
            currentStep = .awaitingConfirmation
            statusMessage = "Review organization plan"
            progress = 1.0
            showPreview = true
            return
        }

        // If account is linked, try server check
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
                            reason: serverReason ?? "Credits verified",
                            sampleFileNames: sampleNames,
                            categoryCounts: categoryCounts
                        )
                        self.currentStep = .awaitingConfirmation
                        self.statusMessage = "Review organization plan"
                        self.progress = 1.0
                        self.showPreview = true
                    } else {
                        // Server denied - show preview with paywall option
                        Logger.shared.info("Server denied: \(serverReason ?? "unknown")")
                        self.pricingInfo = PricingInfo(
                            totalFiles: totalCount,
                            creditsAvailable: userSession.fileCredits,
                            isFreeTrialEligible: false,
                            reason: serverReason ?? "Credits required",
                            sampleFileNames: sampleNames,
                            categoryCounts: categoryCounts
                        )
                        self.currentStep = .awaitingConfirmation
                        self.statusMessage = "Subscribe to organize"
                        self.progress = 1.0
                        self.showPreview = true
                    }
                }
            }
        } else {
            // No account linked and no credits - show preview with paywall option
            Logger.shared.info("No account linked, no credits - showing preview with subscribe option")
            pricingInfo = PricingInfo(
                totalFiles: totalCount,
                creditsAvailable: 0,
                isFreeTrialEligible: false,
                reason: "Subscribe to organize your files",
                sampleFileNames: sampleNames,
                categoryCounts: categoryCounts
            )
            currentStep = .awaitingConfirmation
            statusMessage = "Subscribe to organize"
            progress = 1.0
            showPreview = true
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
