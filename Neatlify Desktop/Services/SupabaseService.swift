//
//  SupabaseService.swift
//  Neatlify Desktop
//
//  Server-side credit validation via Supabase
//

import Foundation

class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL = "https://nlvlwrhayrvberdyjgjx.supabase.co/functions/v1"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sdmx3cmhheXJ2YmVyZHlqZ2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2MDIwMDksImV4cCI6MjA4NDE3ODAwOX0.qKpkkOI2BC6yww8ZV7VFl6tMLNx_VyZifUPPFAciyws"

    private init() {}

    // MARK: - Helper to add auth to requests

    private func addAuthHeaders(to request: inout URLRequest) {
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = AuthSessionStorage.shared.getAccessToken() {
            // Check if token is valid (not expired) before adding it
            do {
                let payload = try decodeJWTPayload(token)
                let now = Int(Date().timeIntervalSince1970)
                let timeUntilExpiry = (payload.exp ?? now) - now

                if timeUntilExpiry > 0 {
                    // Token is still valid
                    let tokenPrefix = String(token.prefix(20))
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    Logger.shared.info("✅ Authorization header added with token: \(tokenPrefix)...")
                } else {
                    // Token is expired - don't send it, rely on apikey instead
                    Logger.shared.warning("⚠️ Access token expired (\(timeUntilExpiry)s), using apikey only")
                }
            } catch {
                Logger.shared.warning("⚠️ Could not validate token, using apikey only: \(error)")
            }
        }
    }

    private func logSupabaseErrorResponse(
        context: String,
        statusCode: Int,
        httpResponse: HTTPURLResponse,
        data: Data
    ) {
        let sbRequestId = httpResponse.value(forHTTPHeaderField: "sb-request-id") ?? "n/a"
        let denoExecutionId = httpResponse.value(forHTTPHeaderField: "x-deno-execution-id") ?? "n/a"
        let debugIds = "sb-request-id=\(sbRequestId) x-deno-execution-id=\(denoExecutionId)"

        if let body = String(data: data, encoding: .utf8), !body.isEmpty {
            Logger.shared.error("\(context) error: \(statusCode) (\(debugIds)) body=\(body)")
        } else {
            Logger.shared.error("\(context) error: \(statusCode) (\(debugIds)) body=<empty or non-utf8>")
        }
    }

    // MARK: - Token Management

    /// Check if token is near expiration and refresh if needed
    func validateSessionAndRefreshIfNeeded() async {
        // Decode access token to check expiration
        if let token = AuthSessionStorage.shared.getAccessToken() {
            do {
                let payload = try decodeJWTPayload(token)

                let now = Int(Date().timeIntervalSince1970)
                let timeUntilExpiry = (payload.exp ?? now) - now

                // Refresh if expiring within 5 minutes
                if timeUntilExpiry < 300 {
                    Logger.shared.warning("Token expiring in \(timeUntilExpiry)s, refreshing...")
                    await refreshAccessToken()
                }
            } catch {
                Logger.shared.error("Failed to validate token: \(error)")
            }
        }
    }

    private func refreshAccessToken() async {
        guard let refreshToken = AuthSessionStorage.shared.getRefreshToken() else {
            Logger.shared.error("No refresh token available")
            return
        }

        do {
            let result = try await AuthenticationService.shared.refreshToken(refreshToken)

            if let newAccessToken = result.accessToken ?? result.session?.accessToken {
                AuthSessionStorage.shared.saveAccessToken(newAccessToken)
                // Refresh-token rotation is enabled on this project, so the refresh call
                // returns a NEW refresh token and revokes the old one. Persist it, otherwise
                // the next refresh (and the delete-account 401 fallback) uses a revoked token.
                if let newRefreshToken = result.refreshToken ?? result.session?.refreshToken {
                    AuthSessionStorage.shared.saveRefreshToken(newRefreshToken)
                }
                Logger.shared.info("✅ Access token refreshed")
            }
        } catch {
            Logger.shared.error("Failed to refresh token: \(error)")
        }
    }

    private func decodeJWTPayload(_ token: String) throws -> (exp: Int?, iat: Int?) {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { throw SupabaseError.invalidResponse }

        let payloadPart = String(parts[1])
        let padding = 4 - (payloadPart.count % 4)
        let paddedPayload = payloadPart + String(repeating: "=", count: padding)

        guard let payloadData = Data(base64Encoded: paddedPayload) else {
            throw SupabaseError.invalidResponse
        }

        struct Payload: Decodable {
            let exp: Int?
            let iat: Int?
        }

        let decoder = JSONDecoder()
        let payload = try decoder.decode(Payload.self, from: payloadData)
        return (exp: payload.exp, iat: payload.iat)
    }

    // MARK: - Credit Checking

    /// Check if user has enough credits (server-side validation)
    func checkCredits(userEmail: String, fileCount: Int) async throws -> CreditCheckResult {
        guard let url = URL(string: "\(baseURL)/check-credits") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(to: &request)

        let body: [String: Any] = [
            "user_email": userEmail,
            "file_count": fileCount,
            "action": "check"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            logSupabaseErrorResponse(
                context: "Supabase check-credits",
                statusCode: httpResponse.statusCode,
                httpResponse: httpResponse,
                data: data
            )
            throw SupabaseError.apiError(statusCode: httpResponse.statusCode)
        }

        let result: CreditCheckResponse
        do {
            result = try JSONDecoder().decode(CreditCheckResponse.self, from: data)
        } catch {
            Logger.shared.error("Failed to decode check-credits response: \(error)")
            if let body = String(data: data, encoding: .utf8) {
                Logger.shared.error("Raw check-credits response body: \(body)")
            }
            throw error
        }

        if result.allowed {
            return .allowed(
                creditsAvailable: result.creditsAvailable ?? 0,
                creditsAfter: result.creditsAfter ?? 0
            )
        } else {
            return .denied(
                reason: result.error ?? "Insufficient credits",
                creditsAvailable: result.creditsAvailable ?? 0,
                creditsNeeded: result.creditsNeeded ?? fileCount
            )
        }
    }

    /// Deduct credits after successful organization (server-side)
    func deductCredits(userEmail: String, fileCount: Int) async throws -> CreditDeductResult {
        // CRITICAL: Refresh token if needed before making API call
        await validateSessionAndRefreshIfNeeded()

        guard let url = URL(string: "\(baseURL)/check-credits") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(to: &request)

        let body: [String: Any] = [
            "user_email": userEmail,
            "file_count": fileCount,
            "action": "deduct"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            logSupabaseErrorResponse(
                context: "Supabase deduct credits",
                statusCode: httpResponse.statusCode,
                httpResponse: httpResponse,
                data: data
            )
            throw SupabaseError.apiError(statusCode: httpResponse.statusCode)
        }

        let result: CreditDeductResponse
        do {
            result = try JSONDecoder().decode(CreditDeductResponse.self, from: data)
        } catch {
            Logger.shared.error("Failed to decode deduct response: \(error)")
            if let body = String(data: data, encoding: .utf8) {
                Logger.shared.error("Raw deduct response body: \(body)")
            }
            throw error
        }

        if result.allowed {
            return .success(
                creditsDeducted: result.creditsDeducted ?? fileCount,
                creditsRemaining: result.creditsRemaining ?? 0
            )
        } else {
            return .failed(reason: result.error ?? "Failed to deduct credits")
        }
    }

    /// Fetch current credit balance for a user
    func getCredits(userEmail: String) async throws -> Int {
        // CRITICAL: Refresh token if needed before making API call
        await validateSessionAndRefreshIfNeeded()

        let result = try await checkCredits(userEmail: userEmail, fileCount: 0)

        switch result {
        case .allowed(let creditsAvailable, _):
            return creditsAvailable
        case .denied(_, let creditsAvailable, _):
            return creditsAvailable
        }
    }

    // MARK: - Types

    enum CreditCheckResult {
        case allowed(creditsAvailable: Int, creditsAfter: Int)
        case denied(reason: String, creditsAvailable: Int, creditsNeeded: Int)
    }

    enum CreditDeductResult {
        case success(creditsDeducted: Int, creditsRemaining: Int)
        case failed(reason: String)
    }

    enum SupabaseError: LocalizedError {
        case invalidURL
        case invalidResponse
        case apiError(statusCode: Int)
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Supabase URL"
            case .invalidResponse: return "Invalid response from server"
            case .apiError(let code): return "Server error: \(code)"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            }
        }
    }

    struct CreditCheckResponse: Codable {
        let allowed: Bool
        let error: String?
        let creditsAvailable: Int?
        let creditsNeeded: Int?
        let creditsAfter: Int?

        enum CodingKeys: String, CodingKey {
            case allowed
            case error
            case creditsAvailable = "credits_available"
            case creditsNeeded = "credits_needed"
            case creditsAfter = "credits_after"
        }
    }

    struct CreditDeductResponse: Codable {
        let allowed: Bool
        let error: String?
        let creditsDeducted: Int?
        let creditsRemaining: Int?

        enum CodingKeys: String, CodingKey {
            case allowed
            case error
            case creditsDeducted = "credits_deducted"
            case creditsRemaining = "credits_remaining"
        }
    }

    // MARK: - Promo Code Redemption

    /// Redeem a promo code and add credits to user's account
    func redeemPromoCode(code: String, userEmail: String) async throws -> PromoCodeResult {
        // CRITICAL: Refresh token if needed before making API call
        await validateSessionAndRefreshIfNeeded()

        guard let url = URL(string: "\(baseURL)/redeem-promo-code") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(to: &request)

        let body: [String: Any] = [
            "promo_code": code,
            "user_email": userEmail
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        let result = try JSONDecoder().decode(PromoCodeResponse.self, from: data)

        if result.success {
            return .success(
                creditsAdded: result.creditsAdded ?? 0,
                creditsTotal: result.creditsTotal ?? 0,
                message: result.message ?? "Promo code redeemed!"
            )
        } else {
            return .failed(reason: result.error ?? "Failed to redeem promo code")
        }
    }

    enum PromoCodeResult {
        case success(creditsAdded: Int, creditsTotal: Int, message: String)
        case failed(reason: String)
    }

    struct PromoCodeResponse: Codable {
        let success: Bool
        let error: String?
        let creditsAdded: Int?
        let creditsTotal: Int?
        let message: String?

        enum CodingKeys: String, CodingKey {
            case success
            case error
            case creditsAdded = "credits_added"
            case creditsTotal = "credits_total"
            case message
        }
    }

    // MARK: - Apple Transaction Verification

    /// Verify an Apple StoreKit 2 transaction with the Supabase backend.
    /// The backend records the transaction and grants credits if valid.
    func verifyAppleTransaction(
        transactionId: String,
        originalTransactionId: String,
        productId: String,
        purchaseDate: Date,
        userEmail: String
    ) async throws -> AppleTransactionResult {
        // CRITICAL: Refresh token if needed before making API call
        await validateSessionAndRefreshIfNeeded()

        guard let url = URL(string: "\(baseURL)/verify-apple-transaction") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeaders(to: &request)

        let body: [String: Any] = [
            "transaction_id": transactionId,
            "original_transaction_id": originalTransactionId,
            "product_id": productId,
            "purchase_date": purchaseDate.timeIntervalSince1970 * 1000, // milliseconds
            "user_email": userEmail
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let responseBody = String(data: data, encoding: .utf8) ?? "no body"
            Logger.shared.error("Apple transaction verification error: \(httpResponse.statusCode) - \(responseBody)")
            throw SupabaseError.apiError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(AppleTransactionResponse.self, from: data)

        if result.success {
            return AppleTransactionResult(
                creditsAdded: result.creditsAdded ?? 0,
                // Pass through nil when the server omitted the field (e.g. profile lookup
                // missed). Callers must NOT treat a missing total as "balance is 0".
                creditsTotal: result.creditsTotal
            )
        } else {
            let errorMsg = result.error ?? "Transaction verification failed"
            Logger.shared.error("Apple transaction verification rejected: \(errorMsg)")
            throw SupabaseError.apiError(statusCode: 400)
        }
    }

    struct AppleTransactionResponse: Codable {
        let success: Bool
        let error: String?
        let creditsAdded: Int?
        let creditsTotal: Int?

        enum CodingKeys: String, CodingKey {
            case success
            case error
            case creditsAdded = "credits_added"
            case creditsTotal = "credits_total"
        }
    }

    struct AppleTransactionResult {
        let creditsAdded: Int
        let creditsTotal: Int?
    }
}
