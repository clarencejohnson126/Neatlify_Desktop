//
//  PaywallView.swift
//  Neatlify
//
//  Subscription paywall view
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var userSession: UserSession
    @Binding var isPresented: Bool
    @State private var selectedOption: UserSession.SubscriptionType = .lifetime

    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Upgrade to Neatlify Pro")
                    .font(.title)
                    .fontWeight(.bold)

                Text("You've used your 3 free cleanups")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Pricing options
            VStack(spacing: 16) {
                ForEach(PaymentService.pricingOptions, id: \.type.rawValue) { option in
                    PricingOptionCard(
                        option: option,
                        isSelected: selectedOption == option.type
                    ) {
                        selectedOption = option.type
                    }
                }
            }

            // Purchase button
            Button(action: purchase) {
                Text("Subscribe")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // Close button
            Button("Maybe Later") {
                isPresented = false
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 600, height: 700)
    }

    private func purchase() {
        switch selectedOption {
        case .monthly:
            PaymentService.shared.purchaseMonthlySubscription()
        case .lifetime:
            PaymentService.shared.purchaseLifetimeSubscription()
        }

        // In production, wait for webhook confirmation
        // For now, simulate activation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            PaymentService.shared.activateSubscription(type: selectedOption)
            isPresented = false
        }
    }
}

struct PricingOptionCard: View {
    let option: PaymentService.PricingOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.headline)

                        Text(option.price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }

                Text(option.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(option.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.green)

                            Text(feature)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
