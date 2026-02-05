//
//  AuthTokenValidator.swift
//  Neatlify Desktop
//
//  Validates authentication tokens received from deep links
//

import Foundation

class AuthTokenValidator {
    enum ValidationError: LocalizedError {
        case invalidFormat
        case expiredToken
        case invalidEmail
        case missingFields
        case decodingError(String)

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Invalid token format"
            case .expiredToken: return "Token has expired"
            case .invalidEmail: return "Invalid email address"
            case .missingFields: return "Missing required fields"
            case .decodingError(let msg): return "Decoding error: \(msg)"
            }
        }
    }

    struct TokenPayload: Decodable {
        let exp: Int?
        let iat: Int?
        let email: String?
        let sub: String?
    }

    // MARK: - JWT Validation

    static func validateAccessToken(_ token: String) -> Result<TokenPayload, ValidationError> {
        guard validateJWTFormat(token) else {
            return .failure(.invalidFormat)
        }

        do {
            let payload = try decodeJWTPayload(token)

            // Check expiration
            let now = Int(Date().timeIntervalSince1970)
            if let exp = payload.exp, exp <= now {
                Logger.shared.warning("Token expired at \(exp), now is \(now)")
                return .failure(.expiredToken)
            }

            // Check issued time (not in future)
            if let iat = payload.iat, iat > now {
                Logger.shared.warning("Token issued in future: \(iat) > \(now)")
                return .failure(.invalidFormat)
            }

            return .success(payload)
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }

    static func validateRefreshToken(_ token: String) -> Result<Void, ValidationError> {
        guard !token.isEmpty else {
            return .failure(.missingFields)
        }
        // Refresh tokens don't have expiration in the same way
        // Just validate they're not empty and reasonable length
        guard token.count > 20 else {
            return .failure(.invalidFormat)
        }
        return .success(())
    }

    static func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    // MARK: - Deep Link Parameter Validation

    struct DeepLinkParams {
        let accessToken: String
        let refreshToken: String
        let userEmail: String
        let expiresAt: Int
        let issuedAt: Int
    }

    static func validateDeepLinkParams(
        accessToken: String?,
        refreshToken: String?,
        userEmail: String?,
        exp: String?,
        iat: String?
    ) -> Result<DeepLinkParams, ValidationError> {
        // Check all required parameters present
        guard let accessToken = accessToken, !accessToken.isEmpty else {
            Logger.shared.error("Missing access token")
            return .failure(.missingFields)
        }

        guard let refreshToken = refreshToken, !refreshToken.isEmpty else {
            Logger.shared.error("Missing refresh token")
            return .failure(.missingFields)
        }

        guard let userEmail = userEmail, !userEmail.isEmpty else {
            Logger.shared.error("Missing user email")
            return .failure(.missingFields)
        }

        guard let expStr = exp, let expiresAt = Int(expStr) else {
            Logger.shared.error("Invalid or missing expiration")
            return .failure(.missingFields)
        }

        guard let iatStr = iat, let issuedAt = Int(iatStr) else {
            Logger.shared.error("Invalid or missing issued-at timestamp")
            return .failure(.missingFields)
        }

        // Validate individual tokens
        let accessTokenResult = validateAccessToken(accessToken)
        if case .failure(let error) = accessTokenResult {
            Logger.shared.error("Access token validation failed: \(error)")
            return .failure(error)
        }

        let refreshTokenResult = validateRefreshToken(refreshToken)
        if case .failure(let error) = refreshTokenResult {
            Logger.shared.error("Refresh token validation failed: \(error)")
            return .failure(error)
        }

        // Validate email format
        guard validateEmail(userEmail) else {
            Logger.shared.error("Invalid email format: \(userEmail)")
            return .failure(.invalidEmail)
        }

        // Check token not issued too far in past (max 1 minute old)
        let now = Int(Date().timeIntervalSince1970)
        if now - issuedAt > 60 {
            Logger.shared.warning("Token issued > 1 minute ago: \(now - issuedAt) seconds")
            // Still allow, but log warning
        }

        Logger.shared.info("Deep link parameters validated successfully for: \(userEmail)")

        return .success(DeepLinkParams(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userEmail: userEmail,
            expiresAt: expiresAt,
            issuedAt: issuedAt
        ))
    }

    // MARK: - Private Helpers

    private static func validateJWTFormat(_ token: String) -> Bool {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 3
    }

    private static func decodeJWTPayload(_ token: String) throws -> TokenPayload {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw ValidationError.invalidFormat
        }

        let payloadPart = String(parts[1])
        // Add padding if needed
        let padding = 4 - (payloadPart.count % 4)
        let paddedPayload = payloadPart + String(repeating: "=", count: padding)

        guard let payloadData = Data(base64Encoded: paddedPayload) else {
            throw ValidationError.decodingError("Failed to decode base64")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(TokenPayload.self, from: payloadData)
    }
}
