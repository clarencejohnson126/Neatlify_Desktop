//
//  PaywallView.swift
//  Neatlify
//
//  Credit pack purchase view
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var userSession: UserSession
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("Get More Credits")
                    .font(.title)
                    .fontWeight(.bold)

                Text(userSession.getCreditsSummary())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Credit packs
            VStack(spacing: 12) {
                ForEach(PaymentService.CreditPack.allCases, id: \.title) { pack in
                    CreditPackRow(pack: pack)
                }

                // Enterprise option
                EnterpriseRow()
            }

            // Close button
            Button("Maybe Later") {
                isPresented = false
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .padding(.top, 8)
        }
        .padding(32)
        .frame(width: 500)
    }
}

struct CreditPackRow: View {
    let pack: PaymentService.CreditPack

    var body: some View {
        Button(action: {
            PaymentService.shared.purchasePack(pack)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pack.title)
                            .font(.headline)

                        if let savings = pack.savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    Text("\(pack.files) files • \(pack.pricePerFile)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(pack.price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EnterpriseRow: View {
    var body: some View {
        Button(action: {
            PaymentService.shared.contactEnterprise()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Enterprise")
                            .font(.headline)

                        Text("Unlimited")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .cornerRadius(4)
                    }

                    Text("Custom volume pricing for teams")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Contact Us")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
        }
    }
}
