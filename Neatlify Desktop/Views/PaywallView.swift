//
//  PaywallView.swift
//  Neatlify
//
//  Credit pack purchase view - Matching landing page design
//

import SwiftUI

// Brand colors matching the landing page
extension Color {
    static let neatlifyGreen = Color(red: 41/255, green: 171/255, blue: 135/255)  // #29AB87
    static let neatlifyYellow = Color(red: 255/255, green: 217/255, blue: 61/255)  // #FFD93D
    static let neatlifyRed = Color(red: 255/255, green: 107/255, blue: 107/255)    // #FF6B6B
    static let neatlifyDark = Color(red: 45/255, green: 52/255, blue: 54/255)      // #2D3436
    static let neatlifyBg = Color(red: 250/255, green: 250/255, blue: 248/255)     // #FAFAF8
}

struct PaywallView: View {
    @EnvironmentObject var userSession: UserSession
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background
            Color.neatlifyBg.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header with logo
                VStack(spacing: 16) {
                    // Logo
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.neatlifyGreen)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.neatlifyDark, lineWidth: 3)
                                )
                            Text("N")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.white)
                        }
                        Text("Neatlify")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.neatlifyDark)
                    }

                    Text("Get More Credits")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.neatlifyDark)

                    // Credits badge
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.neatlifyYellow)
                        Text("\(userSession.fileCredits) credits remaining")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.neatlifyDark.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.neatlifyYellow.opacity(0.2))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.neatlifyDark, lineWidth: 2)
                    )
                }

                // Credit packs
                VStack(spacing: 16) {
                    // Starter
                    CreditPackCard(
                        title: "Starter",
                        files: "100 files",
                        price: "€5",
                        perFile: "€0.05/file",
                        badge: nil,
                        color: .neatlifyDark,
                        isPopular: false
                    ) {
                        PaymentService.shared.purchasePack(.starter)
                    }

                    // Pro - Popular
                    CreditPackCard(
                        title: "Pro",
                        files: "1,000 files",
                        price: "€30",
                        perFile: "€0.03/file",
                        badge: "Save 40%",
                        color: .neatlifyGreen,
                        isPopular: true
                    ) {
                        PaymentService.shared.purchasePack(.pro)
                    }

                    // Business
                    CreditPackCard(
                        title: "Business",
                        files: "10,000 files",
                        price: "€200",
                        perFile: "€0.02/file",
                        badge: "Save 60%",
                        color: .neatlifyRed,
                        isPopular: false
                    ) {
                        PaymentService.shared.purchasePack(.business)
                    }

                    // Enterprise
                    Button(action: {
                        PaymentService.shared.contactEnterprise()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Enterprise")
                                        .font(.headline)
                                        .fontWeight(.black)
                                    Text("Unlimited")
                                        .font(.caption)
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple)
                                        .cornerRadius(4)
                                }
                                Text("Custom volume pricing for teams")
                                    .font(.caption)
                                    .foregroundColor(.neatlifyDark.opacity(0.6))
                            }
                            Spacer()
                            Text("Contact Us")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.neatlifyDark, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Close button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyDark.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(32)
        }
        .frame(width: 420, height: 620)
    }
}

struct CreditPackCard: View {
    let title: String
    let files: String
    let price: String
    let perFile: String
    let badge: String?
    let color: Color
    let isPopular: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Popular badge
                if isPopular {
                    VStack {
                        HStack {
                            Spacer()
                            Text("⭐ POPULAR")
                                .font(.caption2)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.neatlifyRed)
                                .cornerRadius(8)
                                .offset(x: -8, y: -8)
                        }
                        Spacer()
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.black)
                                .foregroundColor(.neatlifyDark)

                            if let badge = badge {
                                Text(badge)
                                    .font(.caption2)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.neatlifyGreen)
                                    .cornerRadius(4)
                            }
                        }

                        Text("\(files) • \(perFile)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                    }

                    Spacer()

                    Text(price)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(color)
                }
                .padding(20)
            }
            .background(
                isPopular ? Color.neatlifyYellow.opacity(0.3) : Color.white
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.neatlifyDark, lineWidth: isPopular ? 3 : 2)
            )
            .shadow(color: isPopular ? Color.neatlifyDark.opacity(0.2) : .clear, radius: 0, x: 4, y: 4)
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
                .foregroundColor(.neatlifyGreen)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.neatlifyDark)
        }
    }
}
