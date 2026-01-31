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

    // Stripe Payment Links (TEST MODE - switch to live for production)
    // Note: These need to be updated in Stripe Dashboard to redirect to your success page
    // Success page should redirect to: neatlify://activate?session_id={CHECKOUT_SESSION_ID}
    private let starterPackURL = "https://buy.stripe.com/test_cNi9ATdsK9vafN67l06EU00"
    private let proPackURL = "https://buy.stripe.com/test_dRm6oH88qgXC30keNs6EU01"
    private let businessPackURL = "https://buy.stripe.com/test_6oU14nagy7n20ScgVA6EU02"

    // Stripe API for creating checkout sessions with custom redirect
    // Set via environment variable or replace for production
    private let stripeSecretKey = ProcessInfo.processInfo.environment["STRIPE_SECRET_KEY"] ?? "YOUR_STRIPE_SECRET_KEY"

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
        let url: String
        switch pack {
        case .starter: url = starterPackURL
        case .pro: url = proPackURL
        case .business: url = businessPackURL
        }
        openCheckout(url: url)
    }

    @MainActor
    func contactEnterprise() {
        if let url = URL(string: "mailto:support@neatlify.com?subject=Enterprise%20Inquiry") {
            NSWorkspace.shared.open(url)
        }
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
