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

    private func restorePurchases() {
        Task {
            await storeKit.restorePurchases()
        }
    }
}
