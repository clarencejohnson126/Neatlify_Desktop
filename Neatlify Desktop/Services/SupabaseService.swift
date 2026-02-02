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

    private init() {}

    // MARK: - Credit Checking

    /// Check if user has enough credits (server-side validation)
    func checkCredits(userEmail: String, fileCount: Int) async throws -> CreditCheckResult {
        guard let url = URL(string: "\(baseURL)/check-credits") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
            Logger.shared.error("Supabase API error: \(httpResponse.statusCode)")
            throw SupabaseError.apiError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(CreditCheckResponse.self, from: data)

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
        guard let url = URL(string: "\(baseURL)/check-credits") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
            Logger.shared.error("Supabase deduct error: \(httpResponse.statusCode)")
            throw SupabaseError.apiError(statusCode: httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(CreditDeductResponse.self, from: data)

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
        guard let url = URL(string: "\(baseURL)/redeem-promo-code") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
}
