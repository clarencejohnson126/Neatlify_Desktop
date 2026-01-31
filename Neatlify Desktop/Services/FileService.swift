//
//  FileService.swift
//  Neatlify
//
//  File system operations: scanning, moving, organizing
//

import Foundation

class FileService {
    static let shared = FileService()

    private let fileManager = FileManager.default
    private var operationHistory: [FileOperation] = []

    private init() {}

    // MARK: - Scanning

    // Scan folder and return all files
    func scanFolder(_ url: URL, includeSubfolders: Bool = false) async throws -> [FileItem] {
        Logger.shared.info("Scanning folder: \(url.path)")

        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .nameKey
        ]

        var files: [FileItem] = []

        if includeSubfolders {
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            ) else {
                throw FileError.scanFailed
            }

            for case let fileURL as URL in enumerator {
                if let fileItem = try? createFileItem(from: fileURL, keys: keys) {
                    files.append(fileItem)
                }
            }
        } else {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            )

            for fileURL in contents {
                if let fileItem = try? createFileItem(from: fileURL, keys: keys) {
                    files.append(fileItem)
                }
            }
        }

        Logger.shared.info("Found \(files.count) files")
        return files
    }

    // Filter files by type
    func filterFiles(_ files: [FileItem], types: [FileItem.FileType]) -> [FileItem] {
        return files.filter { types.contains($0.fileType) }
    }

    private func createFileItem(from url: URL, keys: [URLResourceKey]) throws -> FileItem? {
        let resourceValues = try url.resourceValues(forKeys: Set(keys))

        guard let isRegularFile = resourceValues.isRegularFile,
              isRegularFile else {
            return nil
        }

        let name = resourceValues.name ?? url.lastPathComponent
        let size = Int64(resourceValues.fileSize ?? 0)
        let creationDate = resourceValues.creationDate ?? Date()
        let modificationDate = resourceValues.contentModificationDate ?? Date()
        let fileType = FileItem.FileType.from(pathExtension: url.pathExtension)

        return FileItem(
            url: url,
            name: name,
            fileType: fileType,
            size: size,
            creationDate: creationDate,
            modificationDate: modificationDate
        )
    }

    // MARK: - Organization

    // Create folder structure based on categories
    func createFolders(_ categories: [String], in parentURL: URL) async throws -> [String: URL] {
        var folderMap: [String: URL] = [:]

        for category in categories {
            let folderURL = parentURL.appendingPathComponent(category)

            if !fileManager.fileExists(atPath: folderURL.path) {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                Logger.shared.logFileOperation("Created folder", path: folderURL.path)
            }

            folderMap[category] = folderURL
        }

        return folderMap
    }

    // Move file to new location
    func moveFile(from sourceURL: URL, to destinationURL: URL) async throws {
        // Check if destination already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            // Generate unique filename
            let uniqueDestination = generateUniqueURL(for: destinationURL)
            try fileManager.moveItem(at: sourceURL, to: uniqueDestination)
            Logger.shared.logFileOperation("Moved (renamed)", path: "\(sourceURL.path) -> \(uniqueDestination.path)")

            // Record operation for undo
            recordOperation(.move(from: uniqueDestination, to: sourceURL))
        } else {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            Logger.shared.logFileOperation("Moved", path: "\(sourceURL.path) -> \(destinationURL.path)")

            // Record operation for undo
            recordOperation(.move(from: destinationURL, to: sourceURL))
        }
    }

    // Organize files according to plan
    func organizeFiles(_ files: [FileItem], plan: OrganizationPlan, folderMap: [String: URL], progressHandler: @escaping @MainActor (Int, Int) -> Void) async throws {
        var movedCount = 0
        var skippedCount = 0

        for file in files {
            guard let category = plan.fileAssignments[file.id],
                  let destinationFolder = folderMap[category] else {
                continue
            }

            // IMPORTANT: Check if source file still exists before trying to move
            guard fileManager.fileExists(atPath: file.url.path) else {
                Logger.shared.info("Skipping already moved file: \(file.name)")
                skippedCount += 1
                continue
            }

            let destinationURL = destinationFolder.appendingPathComponent(file.name)

            do {
                try await moveFile(from: file.url, to: destinationURL)
                movedCount += 1
                // Call progress handler on main thread
                await progressHandler(movedCount, files.count)
            } catch {
                Logger.shared.error("Failed to move file: \(file.name)", error: error)
                // Continue with other files even if one fails
            }
        }

        if skippedCount > 0 {
            Logger.shared.info("Skipped \(skippedCount) already-moved files")
        }
        Logger.shared.info("Organization complete: \(movedCount)/\(files.count) files moved")
    }

    // Generate unique filename if destination exists
    private func generateUniqueURL(for url: URL) -> URL {
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        var counter = 1
        var newURL = url

        while fileManager.fileExists(atPath: newURL.path) {
            let newFilename = "\(filename) \(counter)"
            newURL = directory
                .appendingPathComponent(newFilename)
                .appendingPathExtension(fileExtension)
            counter += 1
        }

        return newURL
    }

    // MARK: - Undo Operations

    private func recordOperation(_ operation: FileOperation) {
        operationHistory.append(operation)

        // Keep only last 1000 operations
        if operationHistory.count > 1000 {
            operationHistory.removeFirst()
        }
    }

    // Undo last N operations
    func undoOperations(count: Int) async throws {
        let operationsToUndo = Array(operationHistory.suffix(count))

        for operation in operationsToUndo.reversed() {
            switch operation {
            case .move(let from, let to):
                if fileManager.fileExists(atPath: from.path) {
                    try fileManager.moveItem(at: from, to: to)
                    Logger.shared.logFileOperation("Undone move", path: "\(from.path) -> \(to.path)")
                }
            }
        }

        // Remove undone operations from history
        operationHistory.removeLast(min(count, operationHistory.count))
    }

    // Clear operation history older than specified days
    func clearOldHistory(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        operationHistory.removeAll { $0.timestamp < cutoffDate }
    }

    // MARK: - Helper Methods

    // Get folder size
    func getFolderSize(_ url: URL) -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }

    // Format file size
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Data Structures

    enum FileOperation {
        case move(from: URL, to: URL)

        var timestamp: Date {
            return Date()
        }
    }

    enum FileError: LocalizedError {
        case scanFailed
        case moveFailed
        case folderCreationFailed
        case accessDenied

        var errorDescription: String? {
            switch self {
            case .scanFailed:
                return "Failed to scan folder"
            case .moveFailed:
                return "Failed to move file"
            case .folderCreationFailed:
                return "Failed to create folder"
            case .accessDenied:
                return "Access denied to folder"
            }
        }
    }
}
