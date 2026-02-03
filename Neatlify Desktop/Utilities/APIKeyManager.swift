//
//  APIKeyManager.swift
//  Neatlify
//
//  Secure API key storage and management
//

import Foundation

class APIKeyManager {
    // XOR-encoded API key for basic obfuscation
    // To encode a new key, use: encodeKey("your-api-key")
    // IMPORTANT: Create a NEW production key and set spending limits!
    private static let encodedKeyBytes: [UInt8] = [
        // This will be replaced with your encoded key
        // For now, using placeholder that decodes to empty string
    ]

    // XOR cipher key
    private static let cipherKey: [UInt8] = [0x4E, 0x65, 0x61, 0x74, 0x6C, 0x69, 0x66, 0x79, 0x41, 0x49]

    static func getAPIKey() -> String {
        // Check environment variable first (for development and App Store builds)
        if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty {
            return key
        }

        // Try to decode obfuscated key
        if !encodedKeyBytes.isEmpty {
            return decodeKey(encodedKeyBytes)
        }

        // No API key found - this will cause crashes during file analysis
        Logger.shared.error("CRITICAL: Anthropic API key not configured. File organization will fail.")
        return ""
    }

    // XOR decode
    private static func decodeKey(_ encoded: [UInt8]) -> String {
        var decoded: [UInt8] = []
        for (i, byte) in encoded.enumerated() {
            decoded.append(byte ^ cipherKey[i % cipherKey.count])
        }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }

    // Helper to encode a key (run once to get encoded bytes)
    static func encodeKey(_ key: String) -> [UInt8] {
        let keyBytes = Array(key.utf8)
        var encoded: [UInt8] = []
        for (i, byte) in keyBytes.enumerated() {
            encoded.append(byte ^ cipherKey[i % cipherKey.count])
        }
        // Print for copying into encodedKeyBytes
        print("Encoded key bytes: \(encoded)")
        return encoded
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
