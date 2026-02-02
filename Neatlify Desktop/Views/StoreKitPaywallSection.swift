import SwiftUI
import StoreKit

/// Separate view for StoreKit purchases to avoid compiler type-checking issues
struct StoreKitPaywallSection: View {
    @ObservedObject var storeKit: StoreKitManager
    @State private var isRestoring = false
    let onPurchase: (StoreKit.Product) -> Void

    var body: some View {
        VStack(spacing: 16) {
            CreditPackCard(
                title: "Starter",
                files: "100 files",
                price: "€5",
                perFile: "€0.05/file",
                badge: nil,
                color: .neatlifyDark,
                isPopular: false
            ) {
                if let product = storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.starter" }) {
                    onPurchase(product)
                }
            }

            CreditPackCard(
                title: "Pro",
                files: "1,000 files",
                price: "€30",
                perFile: "€0.03/file",
                badge: "Save 40%",
                color: .neatlifyGreen,
                isPopular: true
            ) {
                if let product = storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.pro" }) {
                    onPurchase(product)
                }
            }

            CreditPackCard(
                title: "Business",
                files: "10,000 files",
                price: "€200",
                perFile: "€0.02/file",
                badge: "Save 60%",
                color: .neatlifyRed,
                isPopular: false
            ) {
                if let product = storeKit.products.first(where: { $0.id == "com.neatlify.Desktop.business" }) {
                    onPurchase(product)
                }
            }

            enterpriseButton

            Button(action: { restorePurchases() }) {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.neatlifyGreen)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private var enterpriseButton: some View {
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

    private func restorePurchases() {
        Task {
            await storeKit.restorePurchases()
        }
    }
}
