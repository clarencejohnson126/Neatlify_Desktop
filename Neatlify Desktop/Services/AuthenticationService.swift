//
//  AuthenticationService.swift
//  Neatlify Desktop
//
//  Handles Supabase Auth integration for user login/signup
//

import Foundation

class AuthenticationService {
    static let shared = AuthenticationService()

    private let baseURL = "https://nlvlwrhayrvberdyjgjx.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sdmx3cmhheXJ2YmVyZHlqZ2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2MDIwMDksImV4cCI6MjA4NDE3ODAwOX0.qKpkkOI2BC6yww8ZV7VFl6tMLNx_VyZifUPPFAciyws"

    private init() {}

    // MARK: - Auth Endpoints

    /// Sign up with email and password
    func signUp(email: String, password: String, fullName: String? = nil) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/v1/signup") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": [
                "full_name": fullName ?? ""
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            return authResponse
        } else {
            let error = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            throw AuthError.signUpFailed(error?.message ?? "Sign up failed")
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            return authResponse
        } else {
            let error = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            throw AuthError.signInFailed(error?.message ?? "Sign in failed")
        }
    }

    /// Refresh access token using refresh token
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=refresh_token") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "refresh_token": refreshToken
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        if httpResponse.statusCode == 200 {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            return authResponse
        } else {
            throw AuthError.tokenRefreshFailed
        }
    }

    /// Sign out (no server call needed, just clear local session)
    func signOut() {
        // Clear stored session from UserDefaults and Keychain
        AuthSessionStorage.shared.clearSession()
    }

    // MARK: - Types

    struct AuthResponse: Codable {
        let user: User?
        let session: Session?

        enum CodingKeys: String, CodingKey {
            case user
            case session
        }
    }

    struct User: Codable {
        let id: String
        let email: String
        let userMetadata: [String: AnyCodable]?

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case userMetadata = "user_metadata"
        }
    }

    struct Session: Codable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let expiresAt: Int?
        let tokenType: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
            case tokenType = "token_type"
        }
    }

    struct AuthErrorResponse: Codable {
        let error: String?
        let errorDescription: String?
        let message: String?

        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "error_description"
            case message
        }
    }

    enum AuthError: LocalizedError {
        case invalidURL
        case invalidResponse
        case signUpFailed(String)
        case signInFailed(String)
        case tokenRefreshFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid authentication URL"
            case .invalidResponse: return "Invalid response from server"
            case .signUpFailed(let msg): return msg
            case .signInFailed(let msg): return msg
            case .tokenRefreshFailed: return "Failed to refresh authentication token"
            }
        }
    }
}

// Helper for encoding/decoding arbitrary JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let null = value as? NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode AnyCodable"))
        }
    }
}
