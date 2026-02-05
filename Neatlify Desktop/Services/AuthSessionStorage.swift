//
//  AuthSessionStorage.swift
//  Neatlify Desktop
//
//  Secure storage of auth tokens and session data using Keychain
//

import Foundation
import Security

class AuthSessionStorage {
    static let shared = AuthSessionStorage()

    private let keychainServiceName = "com.neatlify.desktop"
    private let accessTokenKey = "auth_access_token"
    private let refreshTokenKey = "auth_refresh_token"
    private let userIdKey = "auth_user_id"
    private let userEmailKey = "auth_user_email"

    private init() {}

    // MARK: - Access Token

    func saveAccessToken(_ token: String) {
        saveToKeychain(token, forKey: accessTokenKey)
    }

    func getAccessToken() -> String? {
        return getFromKeychain(accessTokenKey)
    }

    func clearAccessToken() {
        deleteFromKeychain(accessTokenKey)
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ token: String) {
        saveToKeychain(token, forKey: refreshTokenKey)
    }

    func getRefreshToken() -> String? {
        return getFromKeychain(refreshTokenKey)
    }

    func clearRefreshToken() {
        deleteFromKeychain(refreshTokenKey)
    }

    // MARK: - User ID

    func saveUserId(_ userId: String) {
        saveToKeychain(userId, forKey: userIdKey)
    }

    func getUserId() -> String? {
        return getFromKeychain(userIdKey)
    }

    func clearUserId() {
        deleteFromKeychain(userIdKey)
    }

    // MARK: - User Email

    func saveUserEmail(_ email: String) {
        saveToKeychain(email, forKey: userEmailKey)
    }

    func getUserEmail() -> String? {
        return getFromKeychain(userEmailKey)
    }

    func clearUserEmail() {
        deleteFromKeychain(userEmailKey)
    }

    // MARK: - Session Management

    func saveSession(_ session: AuthenticationService.Session, userId: String, email: String) {
        saveAccessToken(session.accessToken)
        saveRefreshToken(session.refreshToken)
        saveUserId(userId)
        saveUserEmail(email)
        Logger.shared.info("Session saved for user: \(email)")
    }

    func clearSession() {
        clearAccessToken()
        clearRefreshToken()
        clearUserId()
        clearUserEmail()
        Logger.shared.info("Session cleared from Keychain")
    }

    func isSessionValid() -> Bool {
        return getAccessToken() != nil && getUserEmail() != nil
    }

    // MARK: - Account Switching

    /// Switch to a different user account
    /// Clears old session and saves new one
    func switchAccount(
        accessToken: String,
        refreshToken: String,
        userEmail: String
    ) {
        let oldEmail = getUserEmail()

        // Log the switch
        if let oldEmail = oldEmail, oldEmail != userEmail {
            Logger.shared.warning("🔄 Switching accounts: \(oldEmail) → \(userEmail)")
        }

        // Clear old session completely
        clearSession()

        // Save new session
        saveAccessToken(accessToken)
        saveRefreshToken(refreshToken)
        saveUserEmail(userEmail)

        Logger.shared.info("✅ Switched to account: \(userEmail)")

        // Notify app of account switch
        NotificationCenter.default.post(
            name: NSNotification.Name("AccountDidSwitch"),
            object: nil,
            userInfo: ["email": userEmail, "previousEmail": oldEmail]
        )
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: keychainServiceName
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(newItem as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            Logger.shared.error("Failed to save to Keychain: \(status)")
        }
    }

    private func getFromKeychain(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: keychainServiceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            if let data = result as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    private func deleteFromKeychain(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: keychainServiceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Logger.shared.error("Failed to delete from Keychain: \(status)")
        }
    }
}
