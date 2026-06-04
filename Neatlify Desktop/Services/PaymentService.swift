//
//  PaymentService.swift
//  Neatlify
//
//  Stripe payment integration for credit packs
//

import Foundation
import AppKit

class PaymentService {
    static let shared = PaymentService()

    private init() {}

    // MARK: - Credit Packs

    enum CreditPack: CaseIterable {
        case starter    // 100 files - €5
        case pro        // 1000 files - €30
        case business   // 10000 files - €200

        var files: Int {
            switch self {
            case .starter: return 100
            case .pro: return 1000
            case .business: return 10000
            }
        }

        var price: String {
            switch self {
            case .starter: return "€5"
            case .pro: return "€30"
            case .business: return "€200"
            }
        }

        var pricePerFile: String {
            switch self {
            case .starter: return "€0.05/file"
            case .pro: return "€0.03/file"
            case .business: return "€0.02/file"
            }
        }

        var savings: String? {
            switch self {
            case .starter: return nil
            case .pro: return "Save 40%"
            case .business: return "Save 60%"
            }
        }

        var title: String {
            switch self {
            case .starter: return "Starter"
            case .pro: return "Pro"
            case .business: return "Business"
            }
        }

        var description: String {
            switch self {
            case .starter: return "Perfect for trying out"
            case .pro: return "Best for regular use"
            case .business: return "For power users"
            }
        }
    }

    // MARK: - Purchase Methods

    @MainActor
    func purchasePack(_ pack: CreditPack) {
        // Use Supabase Edge Function to create dynamic checkout session
        print("DEBUG: PaymentService.purchasePack called for \(pack.title)")
        Task {
            print("DEBUG: Creating checkout session for \(pack.title)")
            await createCheckoutSession(pack: pack)
        }
    }

    private func createCheckoutSession(pack: CreditPack) async {
        let productType: String
        switch pack {
        case .starter: productType = "starter"
        case .pro: productType = "pro"
        case .business: productType = "business"
        }

        // Get user email from Supabase auth
        let userSession = UserSession.load()
        let userEmail = userSession.userEmail ?? ""

        Logger.shared.info("Creating checkout for \(productType), email: \(userEmail)")

        guard let url = URL(string: "https://nlvlwrhayrvberdyjgjx.supabase.co/functions/v1/create-checkout") else {
            Logger.shared.error("Invalid checkout URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add JWT token if available
        if let token = AuthSessionStorage.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            Logger.shared.debug("Added JWT token to checkout request")
        }

        let body: [String: Any] = [
            "productType": productType,
            "userEmail": userEmail,
            "successUrl": "https://www.neatlify.app/#/success?session_id={CHECKOUT_SESSION_ID}",
            "cancelUrl": "https://www.neatlify.app/#/pricing"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            Logger.shared.debug("Sending checkout request for \(productType)")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Log HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                Logger.shared.debug("Checkout response status: \(httpResponse.statusCode)")
            }

            // Log raw response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.shared.debug("Checkout response body: \(responseString)")
            }

            if let response = try? JSONDecoder().decode(CheckoutResponse.self, from: data),
               let checkoutURL = URL(string: response.url) {
                Logger.shared.info("Got checkout URL, opening in browser")
                await MainActor.run {
                    NSWorkspace.shared.open(checkoutURL)
                }
                Logger.shared.info("Opened Stripe checkout for \(productType)")
            } else {
                Logger.shared.error("Failed to parse checkout response")
                // Try to decode as error response
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data) {
                    Logger.shared.error("Server error: \(errorResponse)")
                }
            }
        } catch {
            Logger.shared.error("Checkout error: \(error.localizedDescription)")
        }
    }

    private struct CheckoutResponse: Codable {
        let url: String
    }

    private func openCheckout(url: String) {
        guard let checkoutURL = URL(string: url) else {
            Logger.shared.error("Invalid checkout URL")
            return
        }

        NSWorkspace.shared.open(checkoutURL)
        Logger.shared.info("Opened Stripe checkout")
    }

    // MARK: - Credit Management

    func addCredits(_ pack: CreditPack) {
        let session = UserSession.load()
        session.fileCredits += pack.files
        session.save()
        Logger.shared.info("Added \(pack.files) credits. Total: \(session.fileCredits)")
    }

    func hasCredits(for fileCount: Int) -> Bool {
        let session = UserSession.load()
        return session.fileCredits >= fileCount || !session.hasUsedFreeCleanup
    }

    func getCreditsRemaining() -> Int {
        return UserSession.load().fileCredits
    }
}
