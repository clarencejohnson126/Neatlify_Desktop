//
//  OrganizationRecord.swift
//  Neatlify
//
//  History record for file organization activities
//

import Foundation

struct OrganizationRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let mode: OrganizationMode
    let sourceFolder: String
    let totalFiles: Int
    let filesProcessed: Int
    let categories: [String]
    let creditsUsed: Int
    let status: Status

    enum Status: String, Codable {
        case completed
        case failed
        case cancelled
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mode: OrganizationMode,
        sourceFolder: String,
        totalFiles: Int,
        filesProcessed: Int,
        categories: [String] = [],
        creditsUsed: Int = 0,
        status: Status = .completed
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mode = mode
        self.sourceFolder = sourceFolder
        self.totalFiles = totalFiles
        self.filesProcessed = filesProcessed
        self.categories = categories
        self.creditsUsed = creditsUsed
        self.status = status
    }

    var displayStatus: String {
        switch status {
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }

    var displayMode: String {
        mode == .organize ? "Organized" : "Labeled"
    }

    var folderName: String {
        URL(fileURLWithPath: sourceFolder).lastPathComponent
    }
}
