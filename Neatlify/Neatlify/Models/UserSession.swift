//
//  UserSession.swift
//  Neatlify
//
//  User state and settings model
//

import Foundation

class UserSession: ObservableObject, Codable {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var freeTrialCleanupsRemaining: Int = 3
    @Published var hasActiveSubscription: Bool = false
    @Published var subscriptionType: SubscriptionType?
    @Published var subscriptionExpiryDate: Date?
    @Published var lastCleanupDate: Date?
    @Published var totalCleanupsPerformed: Int = 0
    @Published var cleanupLimitReachedForMonth: Bool = false

    enum SubscriptionType: String, Codable {
        case monthly
        case lifetime
    }

    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case freeTrialCleanupsRemaining
        case hasActiveSubscription
        case subscriptionType
        case subscriptionExpiryDate
        case lastCleanupDate
        case totalCleanupsPerformed
        case cleanupLimitReachedForMonth
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        freeTrialCleanupsRemaining = try container.decode(Int.self, forKey: .freeTrialCleanupsRemaining)
        hasActiveSubscription = try container.decode(Bool.self, forKey: .hasActiveSubscription)
        subscriptionType = try container.decodeIfPresent(SubscriptionType.self, forKey: .subscriptionType)
        subscriptionExpiryDate = try container.decodeIfPresent(Date.self, forKey: .subscriptionExpiryDate)
        lastCleanupDate = try container.decodeIfPresent(Date.self, forKey: .lastCleanupDate)
        totalCleanupsPerformed = try container.decode(Int.self, forKey: .totalCleanupsPerformed)
        cleanupLimitReachedForMonth = try container.decode(Bool.self, forKey: .cleanupLimitReachedForMonth)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(freeTrialCleanupsRemaining, forKey: .freeTrialCleanupsRemaining)
        try container.encode(hasActiveSubscription, forKey: .hasActiveSubscription)
        try container.encode(subscriptionType, forKey: .subscriptionType)
        try container.encode(subscriptionExpiryDate, forKey: .subscriptionExpiryDate)
        try container.encode(lastCleanupDate, forKey: .lastCleanupDate)
        try container.encode(totalCleanupsPerformed, forKey: .totalCleanupsPerformed)
        try container.encode(cleanupLimitReachedForMonth, forKey: .cleanupLimitReachedForMonth)
    }

    func canPerformCleanup() -> Bool {
        if freeTrialCleanupsRemaining > 0 {
            return true
        }

        if hasActiveSubscription {
            if subscriptionType == .lifetime {
                return true
            }

            // For monthly subscription, check if limit reached
            if cleanupLimitReachedForMonth {
                return false
            }

            // Check if subscription is still valid
            if let expiryDate = subscriptionExpiryDate, expiryDate > Date() {
                return true
            }
        }

        return false
    }

    func recordCleanup() {
        if freeTrialCleanupsRemaining > 0 {
            freeTrialCleanupsRemaining -= 1
        }

        lastCleanupDate = Date()
        totalCleanupsPerformed += 1

        // Check monthly limit (3 cleanups per month on subscription)
        if hasActiveSubscription && subscriptionType == .monthly {
            let calendar = Calendar.current
            if let lastDate = lastCleanupDate {
                let components = calendar.dateComponents([.month, .year], from: lastDate)
                let currentComponents = calendar.dateComponents([.month, .year], from: Date())

                if components.month == currentComponents.month && components.year == currentComponents.year {
                    // Same month, check count
                    // This is simplified - in production, you'd track per-month counts properly
                    if totalCleanupsPerformed % 3 == 0 {
                        cleanupLimitReachedForMonth = true
                    }
                } else {
                    // New month, reset limit
                    cleanupLimitReachedForMonth = false
                }
            }
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "UserSession")
        }
    }

    static func load() -> UserSession {
        if let data = UserDefaults.standard.data(forKey: "UserSession"),
           let session = try? JSONDecoder().decode(UserSession.self, from: data) {
            return session
        }
        return UserSession()
    }
}
