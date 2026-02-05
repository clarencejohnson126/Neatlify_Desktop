//
//  UserSession.swift
//  Neatlify
//
//  User state and settings model
//

import Foundation
import Security

// MARK: - Organization Record Model

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

class UserSession: ObservableObject, Codable {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var fileCredits: Int = 0  // Local cache of credits (server is source of truth)
    @Published var lastCleanupDate: Date?
    @Published var totalCleanupsPerformed: Int = 0
    @Published var totalFilesProcessed: Int = 0
    @Published var userEmail: String? = nil  // Linked account email for server-side credit checking
    @Published var userFullName: String? = nil  // User's full name for display
    @Published var organizationHistory: [OrganizationRecord] = []  // Max 500 records
    @Published var isAuthenticatedWithSupabase: Bool = false  // True if logged in via Supabase Auth

    // Pricing constants
    static let freeCleanupFileLimit = 0  // Free trial disabled - scan free, organize paid
    static let maxFilesPerCleanup = 10000  // Hard cap per cleanup

    // Keychain key for trial tracking (persists across reinstalls)
    private static let keychainTrialKey = "com.neatlify.desktop.trialUsed"
    private static let keychainDeviceKey = "com.neatlify.desktop.deviceId"
    private static let keychainEmailKey = "com.neatlify.desktop.userEmail"

    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case fileCredits
        case lastCleanupDate
        case totalCleanupsPerformed
        case totalFilesProcessed
        case userEmail
        case userFullName
        case organizationHistory
        case isAuthenticatedWithSupabase
    }

    init() {}

    // MARK: - Cache Cleanup

    /// CRITICAL: Clean up all stale UserDefaults that don't match current user
    /// Must be called early in app lifecycle, even before checking auth status
    static func cleanupStaleCache() {
        // If a user is authenticated, verify cached data matches them
        if let currentEmail = AuthSessionStorage.shared.getUserEmail() {
            let currentKey = "UserSession_\(currentEmail.replacingOccurrences(of: "@", with: "_at_"))"

            // Check generic key - if it's for a different user, delete it
            if let genericData = UserDefaults.standard.data(forKey: "UserSession"),
               let genericSession = try? JSONDecoder().decode(UserSession.self, from: genericData),
               let genericEmail = genericSession.userEmail,
               genericEmail != currentEmail {
                Logger.shared.warning("CLEANUP: Removing generic key with stale user data (\(genericEmail)). Current user: \(currentEmail)")
                UserDefaults.standard.removeObject(forKey: "UserSession")
            }

            // Also check if we have a user-specific key and generic key with DIFFERENT users
            if let currentData = UserDefaults.standard.data(forKey: currentKey),
               let currentSession = try? JSONDecoder().decode(UserSession.self, from: currentData) {
                Logger.shared.info("CLEANUP: Found user-specific key for \(currentEmail)")

                // Delete generic key since we have the right user-specific key
                UserDefaults.standard.removeObject(forKey: "UserSession")
            }
        }
    }

    // MARK: - User-Specific Cache Key

    private var userDefaultsKey: String {
        if let email = userEmail {
            return "UserSession_\(email.replacingOccurrences(of: "@", with: "_at_"))"
        }
        return "UserSession"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        fileCredits = try container.decodeIfPresent(Int.self, forKey: .fileCredits) ?? 0
        lastCleanupDate = try container.decodeIfPresent(Date.self, forKey: .lastCleanupDate)
        totalCleanupsPerformed = try container.decodeIfPresent(Int.self, forKey: .totalCleanupsPerformed) ?? 0
        totalFilesProcessed = try container.decodeIfPresent(Int.self, forKey: .totalFilesProcessed) ?? 0
        userEmail = try container.decodeIfPresent(String.self, forKey: .userEmail) ?? Self.getKeychainString(key: Self.keychainEmailKey)
        userFullName = try container.decodeIfPresent(String.self, forKey: .userFullName)
        organizationHistory = try container.decodeIfPresent([OrganizationRecord].self, forKey: .organizationHistory) ?? []
        isAuthenticatedWithSupabase = try container.decodeIfPresent(Bool.self, forKey: .isAuthenticatedWithSupabase) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(fileCredits, forKey: .fileCredits)
        try container.encode(lastCleanupDate, forKey: .lastCleanupDate)
        try container.encode(totalCleanupsPerformed, forKey: .totalCleanupsPerformed)
        try container.encode(totalFilesProcessed, forKey: .totalFilesProcessed)
        try container.encode(userEmail, forKey: .userEmail)
        try container.encodeIfPresent(userFullName, forKey: .userFullName)
        try container.encode(organizationHistory, forKey: .organizationHistory)
        try container.encode(isAuthenticatedWithSupabase, forKey: .isAuthenticatedWithSupabase)
    }

    // MARK: - History Management

    /// Save an organization record to history (max 500 records)
    func saveOrganizationRecord(_ record: OrganizationRecord) {
        organizationHistory.insert(record, at: 0)  // Insert at beginning for newest first
        if organizationHistory.count > 500 {
            organizationHistory.removeLast()
        }
        save()
    }

    // MARK: - Account Linking

    /// Link account with email for server-side credit validation
    func linkAccount(email: String) {
        userEmail = email
        Self.setKeychainString(key: Self.keychainEmailKey, value: email)
        save()
    }

    /// Check if account is linked (either via Supabase Auth or manual linking)
    var isAccountLinked: Bool {
        return (userEmail != nil && !userEmail!.isEmpty) || isAuthenticatedWithSupabase
    }

    /// Check auth status from storage and update session
    func checkAuthStatus() {
        if let email = AuthSessionStorage.shared.getUserEmail(),
           let _ = AuthSessionStorage.shared.getAccessToken() {

            // CRITICAL: User is switching accounts - clear ALL old user data
            // This handles the case where AuthSessionStorage was already updated but UserDefaults still has old user
            if let currentEmail = userEmail, currentEmail != email {
                Logger.shared.warning("🔄 USER SWITCH DETECTED! Old: \(currentEmail) → New: \(email)")

                // Clear the old user's UserDefaults key
                let oldKey = "UserSession_\(currentEmail.replacingOccurrences(of: "@", with: "_at_"))"
                UserDefaults.standard.removeObject(forKey: oldKey)
                Logger.shared.info("Removed old UserDefaults key: \(oldKey)")

                // Clear in-memory data
                fileCredits = 0
                organizationHistory = []
            }

            // CRITICAL: Clear generic key if it contains different user's data
            // This prevents stale cached data from previous installs/users
            if let genericData = UserDefaults.standard.data(forKey: "UserSession"),
               let genericSession = try? JSONDecoder().decode(UserSession.self, from: genericData),
               let genericEmail = genericSession.userEmail,
               genericEmail != email {
                Logger.shared.warning("Clearing generic key - contains different user's data (\(genericEmail)). Stale credits: \(genericSession.fileCredits)")
                UserDefaults.standard.removeObject(forKey: "UserSession")
            }

            userEmail = email
            isAuthenticatedWithSupabase = true
            save()  // ✅ IMPORTANT: Save to UserDefaults so other views can see it
            Logger.shared.info("User authenticated: \(email), fileCredits: \(fileCredits)")

            // Sync credits from server (source of truth)
            Task {
                await syncCreditsFromServer()
            }
        } else {
            Logger.shared.info("No active authentication")

            // Clear cached credits if no valid session
            if fileCredits > 0 {
                Logger.shared.warning("Clearing cached credits - no valid session")
                fileCredits = 0
                save()
            }
        }
    }

    /// Authenticate from landing page deep link
    /// Called when user logs in on web and clicks "Open in Desktop App"
    func authenticateFromDeepLink(
        accessToken: String,
        refreshToken: String,
        userEmail: String,
        expiresAt: Int
    ) {
        Logger.shared.info("🔐 Authenticating from deep link: \(userEmail)")

        // Check if switching users
        if let currentEmail = self.userEmail, currentEmail != userEmail {
            Logger.shared.warning("Account switch via deep link: \(currentEmail) → \(userEmail)")
        }

        // Use switchAccount to handle clearing old session
        AuthSessionStorage.shared.switchAccount(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userEmail: userEmail
        )

        // Update local session
        checkAuthStatus()

        Logger.shared.info("✅ Authenticated from web login")
    }

    /// Unlink account (both manual linking and Supabase Auth)
    func unlinkAccount() {
        let emailForCleanup = userEmail

        // Clear in-memory state FIRST
        userEmail = nil
        fileCredits = 0
        userFullName = nil
        organizationHistory = []
        isAuthenticatedWithSupabase = false

        // Clear auth session
        AuthSessionStorage.shared.clearSession()
        AuthenticationService.shared.signOut()

        // Remove user-specific UserDefaults
        if let email = emailForCleanup {
            let emailKey = "UserSession_\(email.replacingOccurrences(of: "@", with: "_at_"))"
            UserDefaults.standard.removeObject(forKey: emailKey)
            Logger.shared.info("Removed UserDefaults for: \(email)")
        }

        // Clear generic key for safety
        UserDefaults.standard.removeObject(forKey: "UserSession")

        // Clear email from keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: Self.keychainEmailKey,
            kSecAttrService as String: "com.neatlify.desktop"
        ]
        SecItemDelete(query as CFDictionary)

        UserDefaults.standard.synchronize()
        Logger.shared.info("Account unlinked - all data cleared")
    }

    /// Sync credits from server
    func syncCreditsFromServer() async {
        guard let email = userEmail else { return }
        do {
            let serverCredits = try await SupabaseService.shared.getCredits(userEmail: email)
            await MainActor.run {
                // DEFENSIVE: Verify email still matches before updating
                guard self.userEmail == email else {
                    Logger.shared.warning("Email changed during sync - ignoring stale result")
                    return
                }
                self.fileCredits = serverCredits
                self.save()
            }
        } catch {
            Logger.shared.error("Failed to sync credits: \(error)")
        }
    }

    // MARK: - Keychain-based Trial Tracking (Persists Across Reinstalls)

    /// Check if free trial has been used (stored in Keychain)
    var hasUsedFreeCleanup: Bool {
        get {
            return Self.getKeychainBool(key: Self.keychainTrialKey) ?? false
        }
        set {
            Self.setKeychainBool(key: Self.keychainTrialKey, value: newValue)
        }
    }

    /// Get or create a persistent device identifier
    static func getDeviceId() -> String {
        if let existingId = getKeychainString(key: keychainDeviceKey) {
            return existingId
        }

        let newId = UUID().uuidString
        setKeychainString(key: keychainDeviceKey, value: newId)
        return newId
    }

    // MARK: - Keychain Helpers

    private static func setKeychainBool(key: String, value: Bool) {
        let data = Data([value ? 1 : 0])
        setKeychainData(key: key, data: data)
    }

    private static func getKeychainBool(key: String) -> Bool? {
        guard let data = getKeychainData(key: key), let byte = data.first else {
            return nil
        }
        return byte == 1
    }

    private static func setKeychainString(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        setKeychainData(key: key, data: data)
    }

    private static func getKeychainString(key: String) -> String? {
        guard let data = getKeychainData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func setKeychainData(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.neatlify.desktop"
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(newItem as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            Logger.shared.error("Keychain write failed: \(status)")
        }
    }

    private static func getKeychainData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.neatlify.desktop",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }

    /// Local check for credits (quick validation before server check)
    func canPerformCleanup(fileCount: Int) -> (allowed: Bool, reason: String?) {
        // Check hard cap
        if fileCount > UserSession.maxFilesPerCleanup {
            return (false, "Maximum \(UserSession.maxFilesPerCleanup) files per cleanup. Please select fewer files.")
        }

        // If account is linked, use cached credits (server will be final check)
        if isAccountLinked {
            if fileCredits >= fileCount {
                return (true, "Will use \(fileCount) of \(fileCredits) credits")
            }

            if fileCredits > 0 {
                return (false, "You have \(fileCredits) credits but need \(fileCount). Please purchase more credits.")
            }

            return (false, "No credits remaining. Please purchase a credit pack to continue.")
        }

        // Not linked - require subscription
        return (false, "Subscribe to organize your files.")
    }

    /// Server-side credit check (async - must be called before organization)
    func canPerformCleanupServerSide(fileCount: Int) async -> (allowed: Bool, reason: String?) {
        // Check hard cap first
        if fileCount > UserSession.maxFilesPerCleanup {
            return (false, "Maximum \(UserSession.maxFilesPerCleanup) files per cleanup.")
        }

        // Account must be linked for paid usage
        guard let email = userEmail else {
            return (false, "Subscribe to organize your files.")
        }

        // Server-side validation
        do {
            let result = try await SupabaseService.shared.checkCredits(userEmail: email, fileCount: fileCount)

            switch result {
            case .allowed(let available, let after):
                // Update local cache
                await MainActor.run {
                    self.fileCredits = available
                    self.save()
                }
                return (true, "Will use \(fileCount) of \(available) credits. \(after) remaining after.")

            case .denied(let reason, let available, _):
                // Update local cache
                await MainActor.run {
                    self.fileCredits = available
                    self.save()
                }
                return (false, reason)
            }
        } catch {
            Logger.shared.error("Server credit check failed: \(error)")
            // Fall back to local check if server is unreachable
            return canPerformCleanup(fileCount: fileCount)
        }
    }

    /// Deduct credits server-side after successful organization
    func deductCreditsServerSide(fileCount: Int) async -> Bool {
        guard let email = userEmail else {
            // If no account, mark free trial as used locally
            if !hasUsedFreeCleanup {
                hasUsedFreeCleanup = true
                save()
                return true
            }
            return false
        }

        do {
            let result = try await SupabaseService.shared.deductCredits(userEmail: email, fileCount: fileCount)

            switch result {
            case .success(_, let remaining):
                await MainActor.run {
                    self.fileCredits = remaining
                    self.save()
                }
                Logger.shared.info("Credits deducted. Remaining: \(remaining)")
                return true

            case .failed(let reason):
                Logger.shared.error("Failed to deduct credits: \(reason)")
                return false
            }
        } catch {
            Logger.shared.error("Server credit deduction failed: \(error)")
            return false
        }
    }

    func recordCleanup(fileCount: Int) {
        if !hasUsedFreeCleanup {
            // First cleanup uses free trial
            hasUsedFreeCleanup = true
        } else {
            // Deduct credits
            fileCredits = max(0, fileCredits - fileCount)
        }

        lastCleanupDate = Date()
        totalCleanupsPerformed += 1
        totalFilesProcessed += fileCount
    }

    func getCreditsSummary() -> String {
        if fileCredits > 0 {
            return "\(fileCredits) credits remaining"
        }
        return "Subscribe to get credits"
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            Logger.shared.info("Session saved with key: \(userDefaultsKey)")
        }
    }

    static func load() -> UserSession {
        // CRITICAL: Clean up stale cached data before loading
        cleanupStaleCache()

        // Try user-specific key first
        if let email = AuthSessionStorage.shared.getUserEmail() {
            let key = "UserSession_\(email.replacingOccurrences(of: "@", with: "_at_"))"
            if let data = UserDefaults.standard.data(forKey: key),
               let session = try? JSONDecoder().decode(UserSession.self, from: data) {
                Logger.shared.info("Loaded session for: \(email)")
                return session
            }
        }

        // Fallback to generic key ONLY if it's for the same authenticated user
        if let data = UserDefaults.standard.data(forKey: "UserSession"),
           let session = try? JSONDecoder().decode(UserSession.self, from: data) {
            // CRITICAL: Don't load generic key if it's for a different user
            if let currentEmail = AuthSessionStorage.shared.getUserEmail(),
               let genericEmail = session.userEmail,
               currentEmail != genericEmail {
                Logger.shared.warning("Generic key has different user (\(genericEmail)). Not loading stale data.")
                UserDefaults.standard.removeObject(forKey: "UserSession")
                return UserSession()
            }
            Logger.shared.info("Loaded session from generic key (backward compatibility)")
            return session
        }

        return UserSession()
    }
}
