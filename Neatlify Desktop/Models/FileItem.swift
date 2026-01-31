//
//  FileItem.swift
//  Neatlify
//
//  File metadata model
//

import Foundation

struct FileItem: Identifiable, Codable {
    let id: UUID
    let url: URL
    let name: String
    let fileType: FileType
    let size: Int64
    let creationDate: Date
    let modificationDate: Date
    var category: String?

    enum FileType: String, Codable {
        case image
        case pdf
        case document
        case video
        case audio
        case other

        static func from(pathExtension: String) -> FileType {
            switch pathExtension.lowercased() {
            case "jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff":
                return .image
            case "pdf":
                return .pdf
            case "doc", "docx", "txt", "rtf", "pages":
                return .document
            case "mp4", "mov", "avi", "mkv", "m4v":
                return .video
            case "mp3", "m4a", "wav", "aac", "flac":
                return .audio
            default:
                return .other
            }
        }
    }

    init(id: UUID = UUID(), url: URL, name: String, fileType: FileType, size: Int64, creationDate: Date, modificationDate: Date, category: String? = nil) {
        self.id = id
        self.url = url
        self.name = name
        self.fileType = fileType
        self.size = size
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.category = category
    }
}
