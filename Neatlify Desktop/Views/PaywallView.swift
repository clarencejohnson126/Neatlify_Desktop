//
//  PaywallView.swift
//  Neatlify
//
//  Credit pack purchase view - Matching landing page design
//

import SwiftUI

#if APPSTORE
import StoreKit
#endif

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

    #if APPSTORE
    @ObservedObject var storeKit = StoreKitManager.shared
    #endif

    @State private var promoCode: String = ""
    @State private var isRedeemingCode: Bool = false
    @State private var promoMessage: String = ""
    @State private var promoSuccess: Bool = false
    @State private var showPromoSection: Bool = false
    @State private var showAccountRequiredAlert: Bool = false
    @State private var showLinkSheet: Bool = false
    @State private var checkoutError: String = ""
    @State private var showCheckoutError: Bool = false
    @State private var testAlert: String = ""
    @State private var showTestAlert: Bool = false

    var body: some View {
        ZStack {
            // Background
            Color.neatlifyBg.ignoresSafeArea()

            ScrollView {
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

                // Info: Credits sync automatically
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.neatlifyGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Credits sync automatically")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.neatlifyDark)
                        Text("Your purchases appear on web and desktop instantly")
                            .font(.caption2)
                            .foregroundColor(.neatlifyDark.opacity(0.6))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.neatlifyGreen.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.neatlifyDark, lineWidth: 2)
                )

                // Credit packs
                #if APPSTORE
                storeKitSection
                #else
                stripePacksSection
                #endif

                // Promo Code Section
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation {
                            showPromoSection.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "ticket.fill")
                                .foregroundColor(.neatlifyGreen)
                            Text("Have a promo code?")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.neatlifyGreen)
                            Image(systemName: showPromoSection ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.neatlifyGreen)
                        }
                    }
                    .buttonStyle(.plain)

                    if showPromoSection {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                TextField("Enter promo code", text: $promoCode)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.neatlifyDark, lineWidth: 2)
                                    )
                                    .textCase(.uppercase)
                                    .disabled(isRedeemingCode)

                                Button(action: {
                                    redeemPromoCode()
                                }) {
                                    if isRedeemingCode {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .frame(width: 80, height: 40)
                                    } else {
                                        Text("Redeem")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 80, height: 40)
                                    }
                                }
                                .background(promoCode.isEmpty ? Color.gray : Color.neatlifyGreen)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.neatlifyDark, lineWidth: 2)
                                )
                                .disabled(promoCode.isEmpty || isRedeemingCode)
                                .buttonStyle(.plain)
                            }

                            // Promo message feedback
                            if !promoMessage.isEmpty {
                                HStack {
                                    Image(systemName: promoSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(promoSuccess ? .neatlifyGreen : .neatlifyRed)
                                    Text(promoMessage)
                                        .font(.caption)
                                        .foregroundColor(promoSuccess ? .neatlifyGreen : .neatlifyRed)
                                }
                                .padding(8)
                                .background(promoSuccess ? Color.neatlifyGreen.opacity(0.1) : Color.neatlifyRed.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding(16)
                        .background(Color.neatlifyYellow.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.neatlifyDark.opacity(0.3), lineWidth: 1)
                        )
                    }
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
        }
        .frame(width: 420, height: 720)
        .alert("Account Required", isPresented: $showAccountRequiredAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please sign in or create an account before purchasing credits. Visit neatlify.com to create your account.")
        }
        .alert("Button Test", isPresented: $showTestAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(testAlert)
        }
        .sheet(isPresented: $showLinkSheet) {
            LinkAccountView(userSession: userSession, isPresented: $showLinkSheet)
        }
    }

    #if APPSTORE
    private func purchaseWithStoreKit(_ product: StoreKit.Product) {
        // Require account to be linked before purchasing
        guard userSession.isAccountLinked else {
            showAccountRequiredAlert = true
            return
        }
        Task {
            _ = await storeKit.purchase(product)
        }
    }
    #else
    private func purchasePack(_ pack: PaymentService.CreditPack) {
        // Allow purchase to proceed - email will be requested at payment
        let email = userSession.userEmail ?? "NO EMAIL SET"
        testAlert = "Clicked: \(pack.title)\nEmail: \(email)\nCredits: \(userSession.fileCredits)"
        showTestAlert = true
        print("DEBUG: purchasePack called for \(pack.title), email: \(email)")
        PaymentService.shared.purchasePack(pack)
    }
    #endif

    private func redeemPromoCode() {
        guard !promoCode.isEmpty else { return }

        // Get user email (required for promo code redemption)
        guard let email = userSession.userEmail, !email.isEmpty else {
            promoMessage = "Please link your account first to use promo codes"
            promoSuccess = false
            return
        }

        isRedeemingCode = true
        promoMessage = ""

        Task {
            do {
                let result = try await SupabaseService.shared.redeemPromoCode(
                    code: promoCode,
                    userEmail: email
                )

                await MainActor.run {
                    switch result {
                    case .success(let creditsAdded, _, let message):
                        promoMessage = message
                        promoSuccess = true
                        promoCode = ""

                        // Update local credits
                        userSession.fileCredits += creditsAdded
                        userSession.save()

                        // Also sync from server to be sure
                        Task {
                            await userSession.syncCreditsFromServer()
                        }

                        // Close paywall after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isPresented = false
                        }

                    case .failed(let reason):
                        promoMessage = reason
                        promoSuccess = false
                    }
                    isRedeemingCode = false
                }
            } catch {
                await MainActor.run {
                    promoMessage = "Failed to redeem code. Please try again."
                    promoSuccess = false
                    isRedeemingCode = false
                }
            }
        }
    }

// MARK: - StoreKit Section (App Store)

    #if APPSTORE
    private var storeKitSection: some View {
        VStack(spacing: 16) {
            if storeKit.isLoadingProducts {
                HStack {
                    ProgressView()
                    Text("Loading products...")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyDark.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Starter Pack
                StoreKitPackCard(
                    product: storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.starter" }),
                    title: "Starter",
                    files: "100 files",
                    credits: 100,
                    perFile: "€0.05/file",
                    badge: nil,
                    color: .neatlifyDark,
                    isPopular: false,
                    isLoading: storeKit.purchaseInProgress
                ) {
                    if let product = storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.starter" }) {
                        purchaseWithStoreKit(product)
                    }
                }

                // Pro Pack
                StoreKitPackCard(
                    product: storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.pro" }),
                    title: "Pro",
                    files: "1,000 files",
                    credits: 1000,
                    perFile: "€0.03/file",
                    badge: "Save 40%",
                    color: .neatlifyGreen,
                    isPopular: true,
                    isLoading: storeKit.purchaseInProgress
                ) {
                    if let product = storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.pro" }) {
                        purchaseWithStoreKit(product)
                    }
                }

                // Business Pack
                StoreKitPackCard(
                    product: storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.business" }),
                    title: "Business",
                    files: "10,000 files",
                    credits: 10000,
                    perFile: "€0.02/file",
                    badge: "Save 60%",
                    color: .neatlifyRed,
                    isPopular: false,
                    isLoading: storeKit.purchaseInProgress
                ) {
                    if let product = storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.business" }) {
                        purchaseWithStoreKit(product)
                    }
                }

                enterpriseButton

                // Restore Purchases Button
                Button(action: {
                    Task {
                        await storeKit.restorePurchases()
                    }
                }) {
                    Text("Restore Purchases")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.neatlifyGreen)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }

            if let error = storeKit.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.neatlifyRed)
                    .padding(8)
                    .background(Color.neatlifyRed.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
    #endif

// MARK: - Stripe Section

    #if !APPSTORE
    private var stripePacksSection: some View {
        VStack(spacing: 16) {
            CreditPackCard(
                title: "Starter",
                files: "100 files",
                price: "€5",
                perFile: "€0.05/file",
                badge: nil,
                color: .neatlifyGreen,
                backgroundColor: Color.green.opacity(0.1),
                borderColor: .neatlifyGreen,
                isPopular: false
            ) {
                purchasePack(.starter)
            }

            CreditPackCard(
                title: "Pro",
                files: "1,000 files",
                price: "€30",
                perFile: "€0.03/file",
                badge: "Save 40%",
                color: .neatlifyYellow,
                backgroundColor: Color.yellow.opacity(0.2),
                borderColor: .neatlifyYellow,
                isPopular: true
            ) {
                purchasePack(.pro)
            }

            CreditPackCard(
                title: "Business",
                files: "10,000 files",
                price: "€200",
                perFile: "€0.02/file",
                badge: "Save 60%",
                color: .neatlifyRed,
                backgroundColor: Color.red.opacity(0.1),
                borderColor: .neatlifyRed,
                isPopular: false
            ) {
                purchasePack(.business)
            }

            enterpriseButton
        }
    }
    #endif

    // MARK: - Enterprise Button (shared)

    private var enterpriseButton: some View {
        let blueColor = Color(red: 0.2, green: 0.4, blue: 0.9)
        return Button(action: {
            PaymentService.shared.contactEnterprise()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Enterprise")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.neatlifyDark)
                        Text("Unlimited")
                            .font(.caption)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(blueColor)
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
                    .foregroundColor(blueColor)
            }
            .padding(16)
            .background(blueColor.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(blueColor, lineWidth: 3)
            )
            .shadow(color: blueColor.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#if APPSTORE
struct StoreKitPackCard: View {
    let product: StoreKit.Product?
    let title: String
    let files: String
    let credits: Int
    let perFile: String
    let badge: String?
    let color: Color
    let isPopular: Bool
    let isLoading: Bool
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

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let product = product {
                        VStack(spacing: 2) {
                            Text(product.displayPrice)
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(color)
                        }
                    } else {
                        Text("—")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.gray)
                    }
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
        .disabled(isLoading || product == nil)
    }
}
#endif

#if !APPSTORE
struct CreditPackCard: View {
    let title: String
    let files: String
    let price: String
    let perFile: String
    let badge: String?
    let color: Color
    let backgroundColor: Color
    let borderColor: Color
    let isPopular: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Popular badge - fixed positioning
                if isPopular {
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
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                } else {
                    // Empty space to keep alignment consistent
                    HStack {
                        Spacer()
                        Text("")
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                }

                // Content
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
                                    .background(color)
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
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isPopular ? 4 : 3)
            )
            .shadow(color: borderColor.opacity(0.3), radius: isPopular ? 12 : 6, x: 0, y: isPopular ? 8 : 4)
        }
        .buttonStyle(.plain)
    }
}
#endif

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
