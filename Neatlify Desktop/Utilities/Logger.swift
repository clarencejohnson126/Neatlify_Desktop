//
//  Logger.swift
//  Neatlify
//
//  Debug logging utility
//

import Foundation
import os.log

class Logger {
    static let shared = Logger()

    private let osLog = OSLog(subsystem: "com.neatlify.desktop", category: "general")

    private init() {}

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        os_log(.debug, log: osLog, "[%{public}@:%{public}d] %{public}@", fileName, line, message)
        #endif
    }

    func info(_ message: String) {
        os_log(.info, log: osLog, "%{public}@", message)
    }

    func warning(_ message: String) {
        os_log(.error, log: osLog, "⚠️ %{public}@", message)
    }

    func error(_ message: String, error: Error? = nil) {
        if let error = error {
            os_log(.error, log: osLog, "❌ %{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: osLog, "❌ %{public}@", message)
        }
    }

    // Log file operations
    func logFileOperation(_ operation: String, path: String) {
        info("File Operation: \(operation) - \(path)")
    }

    // Log API calls
    func logAPICall(_ endpoint: String, tokensUsed: Int? = nil) {
        if let tokens = tokensUsed {
            info("API Call: \(endpoint) - \(tokens) tokens")
        } else {
            info("API Call: \(endpoint)")
        }
    }
}
