//
//  APIKeyManager.swift
//  Neatlify
//
//  Secure API key storage and management
//

import Foundation

class APIKeyManager {
    // Obfuscated API key - in production, use more sophisticated obfuscation
    // Set via environment variable ANTHROPIC_API_KEY
    private static let obfuscatedKey = "YOUR_ANTHROPIC_API_KEY"

    // XOR cipher key (device-specific in production)
    private static let cipherKey: [UInt8] = [0x42, 0x4E, 0x65, 0x61, 0x74, 0x6C, 0x69, 0x66, 0x79]

    static func getAPIKey() -> String {
        // In production, implement proper obfuscation/encryption
        // For now, return the key directly (replace with your actual key)
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] {
            return key
        }
        return obfuscatedKey
    }

    // Track usage per user to prevent abuse
    static func logUsage(fileCount: Int, tokensUsed: Int) {
        let usage = UsageRecord(
            timestamp: Date(),
            fileCount: fileCount,
            tokensUsed: tokensUsed
        )

        var history = getUsageHistory()
        history.append(usage)

        // Keep last 30 days only
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        history = history.filter { $0.timestamp > thirtyDaysAgo }

        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "UsageHistory")
        }
    }

    static func getUsageHistory() -> [UsageRecord] {
        guard let data = UserDefaults.standard.data(forKey: "UsageHistory"),
              let history = try? JSONDecoder().decode([UsageRecord].self, from: data) else {
            return []
        }
        return history
    }

    static func getTotalTokensThisMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let history = getUsageHistory()

        return history
            .filter { calendar.isDate($0.timestamp, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.tokensUsed }
    }

    struct UsageRecord: Codable {
        let timestamp: Date
        let fileCount: Int
        let tokensUsed: Int
    }
}
