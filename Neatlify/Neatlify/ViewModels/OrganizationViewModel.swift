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

    private let apiService = ClaudeAPIService()
    private let fileService = FileService.shared
    private let permissionsService = PermissionsService.shared

    private var scannedFiles: [FileItem] = []
    private var selectedFolderURL: URL?

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

    func executeOrganization() async {
        guard let plan = organizationPlan,
              let folderURL = selectedFolderURL else {
            return
        }

        currentStep = .organizingFiles
        statusMessage = "Organizing files..."

        do {
            // Create organized folder with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let timestamp = dateFormatter.string(from: Date())

            let organizedFolderURL = folderURL.appendingPathComponent("Organized_\(timestamp)")
            try FileManager.default.createDirectory(at: organizedFolderURL, withIntermediateDirectories: true)

            // Create category folders
            let folderMap = try await fileService.createFolders(plan.categories, in: organizedFolderURL)

            // Move files
            try await fileService.organizeFiles(scannedFiles, plan: plan, folderMap: folderMap) { processed, total in
                self.processedFiles = processed
                self.totalFiles = total
                self.progress = Double(processed) / Double(total)
                self.statusMessage = "Moving files... \(processed)/\(total)"
            }

            // Record cleanup
            let session = UserSession.load()
            session.recordCleanup()
            session.save()

            // Complete
            currentStep = .completed
            statusMessage = "Organization complete! \(processedFiles) files organized."

            // Log usage
            APIKeyManager.logUsage(fileCount: processedFiles, tokensUsed: 0)

        } catch {
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

        currentStep = .analyzingFiles
        statusMessage = "Analyzing files with AI..."
        progress = 0.4

        var fileAssignments: [UUID: String] = [:]
        var categoryCounts: [String: Int] = [:]

        // Initialize category counts
        for category in plan.categories {
            categoryCounts[category] = 0
        }

        // Separate images and PDFs
        let images = scannedFiles.filter { $0.fileType == .image }
        let pdfs = scannedFiles.filter { $0.fileType == .pdf }

        // Process images in batches of 20
        if !images.isEmpty {
            statusMessage = "Analyzing \(images.count) images..."

            let imageBatches = images.chunked(into: 20)

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
                statusMessage = "Analyzing images... \((index + 1) * 20)/\(images.count)"
            }
        }

        // Process PDFs in batches of 10
        if !pdfs.isEmpty {
            statusMessage = "Analyzing \(pdfs.count) PDFs..."

            let pdfBatches = pdfs.chunked(into: 10)

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
                statusMessage = "Analyzing PDFs... \((index + 1) * 10)/\(pdfs.count)"
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
        currentStep = .awaitingConfirmation
        statusMessage = "Review organization plan"
        progress = 1.0
        showPreview = true
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
