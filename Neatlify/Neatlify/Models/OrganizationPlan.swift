//
//  OrganizationPlan.swift
//  Neatlify
//
//  AI-generated organization plan model
//

import Foundation

struct OrganizationPlan: Codable {
    let id: UUID
    let timestamp: Date
    let sourceFolder: URL
    let criteria: String
    let categories: [String]
    let fileAssignments: [UUID: String] // FileItem.id -> category
    let suggestedFolderStructure: [String: Int] // category -> file count

    init(id: UUID = UUID(), timestamp: Date = Date(), sourceFolder: URL, criteria: String, categories: [String], fileAssignments: [UUID: String], suggestedFolderStructure: [String: Int]) {
        self.id = id
        self.timestamp = timestamp
        self.sourceFolder = sourceFolder
        self.criteria = criteria
        self.categories = categories
        self.fileAssignments = fileAssignments
        self.suggestedFolderStructure = suggestedFolderStructure
    }

    var totalFiles: Int {
        fileAssignments.count
    }

    var categorySummary: String {
        suggestedFolderStructure
            .sorted { $0.value > $1.value }
            .map { "• \($0.key) (\($0.value) files)" }
            .joined(separator: "\n")
    }
}

struct OrganizationIntent: Codable {
    let folder: String
    let criteria: String
    let suggestedCategories: [String]
}
