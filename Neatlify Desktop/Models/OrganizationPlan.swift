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
    let fileAssignments: [UUID: String] // FileItem.id -> category (for organize mode)
    let suggestedFolderStructure: [String: Int] // category -> file count
    let mode: OrganizationMode
    let fileLabels: [UUID: String] // FileItem.id -> new filename (for label mode)

    init(id: UUID = UUID(), timestamp: Date = Date(), sourceFolder: URL, criteria: String, categories: [String], fileAssignments: [UUID: String], suggestedFolderStructure: [String: Int], mode: OrganizationMode = .organize, fileLabels: [UUID: String] = [:]) {
        self.id = id
        self.timestamp = timestamp
        self.sourceFolder = sourceFolder
        self.criteria = criteria
        self.categories = categories
        self.fileAssignments = fileAssignments
        self.suggestedFolderStructure = suggestedFolderStructure
        self.mode = mode
        self.fileLabels = fileLabels
    }

    var totalFiles: Int {
        mode == .label ? fileLabels.count : fileAssignments.count
    }

    var categorySummary: String {
        if mode == .label {
            return "Will rename \(fileLabels.count) files based on content"
        }
        return suggestedFolderStructure
            .sorted { $0.value > $1.value }
            .map { "• \($0.key) (\($0.value) files)" }
            .joined(separator: "\n")
    }

    var labelPreview: String {
        fileLabels.values.prefix(5).map { "• \($0)" }.joined(separator: "\n")
    }
}

struct OrganizationIntent: Codable {
    let folder: String
    let criteria: String
    let suggestedCategories: [String]
    let mode: OrganizationMode

    enum CodingKeys: String, CodingKey {
        case folder
        case criteria
        case suggestedCategories = "suggested_categories"
        case mode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        folder = try container.decode(String.self, forKey: .folder)
        criteria = try container.decode(String.self, forKey: .criteria)
        suggestedCategories = try container.decode([String].self, forKey: .suggestedCategories)
        // Default to organize if mode not specified
        mode = try container.decodeIfPresent(OrganizationMode.self, forKey: .mode) ?? .organize
    }
}

enum OrganizationMode: String, Codable {
    case organize = "organize"  // Move files into category folders
    case label = "label"        // Rename files based on content
}
