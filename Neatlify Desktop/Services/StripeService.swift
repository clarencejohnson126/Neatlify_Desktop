//
//  StripeService.swift
//  Neatlify
//
//  Stripe API integration for payment verification
//

import Foundation

class StripeService {
    static let shared = StripeService()

    // Stripe API key (read-only for checkout session verification)
    // Set via environment variable or replace for production
    private let secretKey = ProcessInfo.processInfo.environment["STRIPE_SECRET_KEY"] ?? "YOUR_STRIPE_SECRET_KEY"

    private let baseURL = "https://api.stripe.com/v1"

    // Track used session IDs to prevent replay attacks
    private let usedSessionsKey = "UsedStripeSessions"

    private init() {}

    // MARK: - Verify Checkout Session

    func verifyCheckoutSession(_ sessionId: String) async throws -> VerificationResult {
        // Check if session was already used
        if isSessionUsed(sessionId) {
            return .alreadyUsed
        }

        // Fetch session from Stripe
        guard let url = URL(string: "\(baseURL)/checkout/sessions/\(sessionId)") else {
            throw StripeError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Basic auth with secret key
        let authString = "\(secretKey):"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            Logger.shared.error("Stripe API error: \(httpResponse.statusCode)")
            if let errorBody = String(data: data, encoding: .utf8) {
                Logger.shared.error("Error: \(errorBody)")
            }
            throw StripeError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let session = try JSONDecoder().decode(CheckoutSession.self, from: data)

        // Verify payment status
        guard session.paymentStatus == "paid" else {
            return .notPaid
        }

        // Determine credits based on amount
        let credits = creditsForAmount(session.amountTotal, currency: session.currency)

        if credits > 0 {
            // Mark session as used
            markSessionUsed(sessionId)
            return .success(credits: credits)
        }

        return .unknownProduct
    }

    // MARK: - Credits Mapping

    private func creditsForAmount(_ amount: Int, currency: String) -> Int {
        // Amount is in cents/smallest currency unit
        // EUR pricing: €5 = 100 files, €30 = 1000 files, €200 = 10000 files
        switch amount {
        case 500: return 100      // €5.00 = 100 credits
        case 3000: return 1000    // €30.00 = 1000 credits
        case 20000: return 10000  // €200.00 = 10000 credits
        default:
            // Fallback: calculate based on €0.05 per credit
            return amount / 5
        }
    }

    // MARK: - Session Tracking

    private func isSessionUsed(_ sessionId: String) -> Bool {
        let usedSessions = UserDefaults.standard.stringArray(forKey: usedSessionsKey) ?? []
        return usedSessions.contains(sessionId)
    }

    private func markSessionUsed(_ sessionId: String) {
        var usedSessions = UserDefaults.standard.stringArray(forKey: usedSessionsKey) ?? []
        usedSessions.append(sessionId)

        // Keep only last 100 to prevent unlimited growth
        if usedSessions.count > 100 {
            usedSessions = Array(usedSessions.suffix(100))
        }

        UserDefaults.standard.set(usedSessions, forKey: usedSessionsKey)
    }

    // MARK: - Types

    enum VerificationResult {
        case success(credits: Int)
        case notPaid
        case alreadyUsed
        case unknownProduct
    }

    enum StripeError: LocalizedError {
        case invalidURL
        case invalidResponse
        case apiError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Stripe URL"
            case .invalidResponse: return "Invalid response from Stripe"
            case .apiError(let code): return "Stripe API error: \(code)"
            }
        }
    }

    struct CheckoutSession: Codable {
        let id: String
        let paymentStatus: String
        let amountTotal: Int
        let currency: String

        enum CodingKeys: String, CodingKey {
            case id
            case paymentStatus = "payment_status"
            case amountTotal = "amount_total"
            case currency
        }
    }
}
