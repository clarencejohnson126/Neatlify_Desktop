//
//  PaymentService.swift
//  Neatlify
//
//  Stripe payment integration for subscriptions
//

import Foundation
import AppKit

class PaymentService {
    static let shared = PaymentService()

    // Stripe checkout URLs (replace with your actual Stripe links)
    private let monthlySubscriptionURL = "https://buy.stripe.com/YOUR_MONTHLY_LINK"
    private let lifetimeSubscriptionURL = "https://buy.stripe.com/YOUR_LIFETIME_LINK"

    private init() {}

    // MARK: - Purchase Methods

    @MainActor
    func purchaseMonthlySubscription() {
        openCheckout(url: monthlySubscriptionURL)
    }

    @MainActor
    func purchaseLifetimeSubscription() {
        openCheckout(url: lifetimeSubscriptionURL)
    }

    private func openCheckout(url: String) {
        guard let checkoutURL = URL(string: url) else {
            Logger.shared.error("Invalid checkout URL")
            return
        }

        NSWorkspace.shared.open(checkoutURL)
        Logger.shared.info("Opened Stripe checkout")
    }

    // MARK: - Subscription Management

    func activateSubscription(type: UserSession.SubscriptionType, receiptData: String? = nil) {
        let session = UserSession.load()
        session.hasActiveSubscription = true
        session.subscriptionType = type

        if type == .monthly {
            // Set expiry to 1 month from now
            session.subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        } else {
            // Lifetime has no expiry
            session.subscriptionExpiryDate = nil
        }

        session.save()
        Logger.shared.info("Subscription activated: \(type.rawValue)")
    }

    func checkSubscriptionStatus() -> Bool {
        let session = UserSession.load()

        if !session.hasActiveSubscription {
            return false
        }

        // Lifetime subscriptions never expire
        if session.subscriptionType == .lifetime {
            return true
        }

        // Check if monthly subscription is still valid
        if let expiryDate = session.subscriptionExpiryDate {
            return expiryDate > Date()
        }

        return false
    }

    func renewSubscription() {
        let session = UserSession.load()

        if session.subscriptionType == .monthly {
            session.subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
            session.cleanupLimitReachedForMonth = false
            session.save()
            Logger.shared.info("Subscription renewed")
        }
    }

    func cancelSubscription() {
        let session = UserSession.load()
        session.hasActiveSubscription = false
        session.subscriptionType = nil
        session.subscriptionExpiryDate = nil
        session.save()
        Logger.shared.info("Subscription cancelled")
    }

    // MARK: - Pricing Information

    struct PricingOption {
        let title: String
        let price: String
        let description: String
        let features: [String]
        let type: UserSession.SubscriptionType
    }

    static let pricingOptions: [PricingOption] = [
        PricingOption(
            title: "Monthly",
            price: "$19.99/month",
            description: "Perfect for regular organizing",
            features: [
                "3 cleanups per month",
                "Unlimited files per cleanup",
                "AI-powered categorization",
                "Undo within 7 days"
            ],
            type: .monthly
        ),
        PricingOption(
            title: "Lifetime",
            price: "$99",
            description: "Best value - pay once, use forever",
            features: [
                "Unlimited cleanups",
                "Unlimited files per cleanup",
                "AI-powered categorization",
                "Undo within 7 days",
                "Priority support"
            ],
            type: .lifetime
        )
    ]
}
