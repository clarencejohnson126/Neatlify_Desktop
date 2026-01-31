//
//  PermissionsService.swift
//  Neatlify
//
//  macOS folder access permissions management
//

import Foundation
import AppKit

class PermissionsService {
    static let shared = PermissionsService()

    private init() {}

    // Request folder access from user using NSOpenPanel
    @MainActor
    func requestFolderAccess(message: String = "Select a folder to organize") async -> URL? {
        let panel = NSOpenPanel()
        panel.message = message
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        let response = panel.runModal()

        if response == .OK, let url = panel.url {
            // Save security-scoped bookmark for persistent access
            saveBookmark(for: url)
            Logger.shared.info("Folder access granted: \(url.path)")
            return url
        }

        return nil
    }

    // Request access to common folders
    @MainActor
    func requestCommonFolderAccess(for folder: CommonFolder) async -> URL? {
        let url = folder.url

        let panel = NSOpenPanel()
        panel.message = "Grant access to \(folder.displayName)"
        panel.directoryURL = url
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        let response = panel.runModal()

        if response == .OK, let selectedURL = panel.url {
            saveBookmark(for: selectedURL)
            Logger.shared.info("Access granted to \(folder.displayName)")
            return selectedURL
        }

        return nil
    }

    // Save security-scoped bookmark for persistent access
    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            var bookmarks = getSavedBookmarks()
            bookmarks[url.path] = bookmarkData
            UserDefaults.standard.set(bookmarks, forKey: "FolderBookmarks")

            Logger.shared.debug("Saved bookmark for: \(url.path)")
        } catch {
            Logger.shared.error("Failed to save bookmark", error: error)
        }
    }

    // Get saved bookmarks
    private func getSavedBookmarks() -> [String: Data] {
        return UserDefaults.standard.dictionary(forKey: "FolderBookmarks") as? [String: Data] ?? [:]
    }

    // Restore access to previously granted folder
    func restoreAccess(to path: String) -> URL? {
        let bookmarks = getSavedBookmarks()

        guard let bookmarkData = bookmarks[path] else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                Logger.shared.warning("Bookmark is stale for: \(path)")
                return nil
            }

            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                Logger.shared.warning("Failed to access security-scoped resource: \(path)")
                return nil
            }

            return url
        } catch {
            Logger.shared.error("Failed to restore bookmark", error: error)
            return nil
        }
    }

    // Check if we have access to a folder
    func hasAccess(to url: URL) -> Bool {
        let fileManager = FileManager.default
        return fileManager.isReadableFile(atPath: url.path) &&
               fileManager.isWritableFile(atPath: url.path)
    }

    // Common folder locations
    enum CommonFolder {
        case downloads
        case desktop
        case documents

        var url: URL {
            let fileManager = FileManager.default
            switch self {
            case .downloads:
                return fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            case .desktop:
                return fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
            case .documents:
                return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            }
        }

        var displayName: String {
            switch self {
            case .downloads:
                return "Downloads"
            case .desktop:
                return "Desktop"
            case .documents:
                return "Documents"
            }
        }
    }
}
