import Foundation
import StoreKit

/// Manages StoreKit 2 in-app purchases for Mac App Store distribution.
/// Handles product loading, purchases, transaction verification, and server sync.
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // Product IDs matching App Store Connect configuration
    private static let starterProductId = "com.neatlify.Desktop.starter"
    private static let proProductId = "com.neatlify.Desktop.pro"
    private static let businessProductId = "com.neatlify.Desktop.business"

    @Published var products: [Product] = []
    @Published var isLoadingProducts = false
    @Published var purchaseInProgress = false
    @Published var lastError: String?

    private var transactionListenerTask: Task<Void, Never>?

    // Retry configuration
    private let maxRetries = 3
    private let initialBackoffSeconds = 1.0
    private let maxBackoffSeconds = 32.0

    private init() {
        // Start listening for transactions immediately
        transactionListenerTask = Task {
            await listenForTransactions()
        }

        // Load products on initialization
        Task {
            await loadProducts()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Product Loading

    /// Loads all StoreKit products from App Store Connect.
    /// Automatically retries on transient network failures.
    @MainActor
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let productIds = [
                Self.starterProductId,
                Self.proProductId,
                Self.businessProductId
            ]

            let products = try await executeWithRetry {
                try await Product.products(for: productIds)
            }

            self.products = products.sorted { a, b in
                // Sort by display order: starter, pro, business
                let order = [Self.starterProductId, Self.proProductId, Self.businessProductId]
                let aIndex = order.firstIndex(of: a.id) ?? 0
                let bIndex = order.firstIndex(of: b.id) ?? 0
                return aIndex < bIndex
            }
        } catch {
            lastError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase Flow

    /// Initiates a purchase for the given product.
    /// Returns the transaction if successful, nil otherwise.
    func purchase(_ product: Product) async -> Transaction? {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await syncTransactionWithServer(transaction)
                await transaction.finish()
                return transaction

            case .userCancelled:
                lastError = nil
                return nil

            case .pending:
                // "Ask to Buy" pending approval - listener will handle later
                lastError = nil
                return nil

            @unknown default:
                lastError = "Unknown purchase result"
                return nil
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Transaction Listener

    /// Listens for transaction updates in the background.
    /// Handles delayed/pending purchases and account changes.
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)

                // Skip if transaction is not an entitlement (e.g., refund)
                if transaction.revocationDate == nil {
                    await syncTransactionWithServer(transaction)
                }

                await transaction.finish()
            } catch {
                // Log but continue listening
                print("Transaction listener error: \(error)")
            }
        }
    }

    // MARK: - Server Sync

    /// Syncs a verified transaction with the Supabase backend.
    /// Verifies the JWS signature and grants credits.
    /// Automatically retries on transient network failures.
    private func syncTransactionWithServer(_ transaction: Transaction) async {
        guard let userSession = await getUserSession() else {
            print("Cannot sync transaction: no user session")
            return
        }

        guard let userEmail = userSession.userEmail else {
            print("Cannot sync transaction: user not logged in")
            return
        }

        do {
            let result = try await executeWithRetry {
                try await SupabaseService.shared.verifyAppleTransaction(
                    transactionId: String(transaction.id),
                    originalTransactionId: String(transaction.originalID),
                    productId: transaction.productID,
                    purchaseDate: transaction.purchaseDate,
                    userEmail: userEmail
                )
            }

            // Update local user session
            userSession.fileCredits = result.creditsTotal
            userSession.save()

            // Post notification for UI updates
            NotificationCenter.default.post(name: .creditsDidChange, object: nil)
        } catch {
            print("Failed to sync Apple transaction with server: \(error)")
        }
    }

    // MARK: - Restoration

    /// Restores previously purchased products from the user's account.
    /// Called when user reinstalls the app or signs into a new device.
    /// Automatically retries on transient network failures.
    func restorePurchases() async {
        guard let userSession = await getUserSession() else {
            print("Cannot restore purchases: no user session")
            return
        }

        guard let userEmail = userSession.userEmail else {
            print("Cannot restore purchases: user not logged in")
            return
        }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            var creditsGranted = 0

            // Query all current entitlements for this user
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)

                    // Only process non-revoked transactions
                    if transaction.revocationDate == nil {
                        let syncResult = try await executeWithRetry {
                            try await SupabaseService.shared.verifyAppleTransaction(
                                transactionId: String(transaction.id),
                                originalTransactionId: String(transaction.originalID),
                                productId: transaction.productID,
                                purchaseDate: transaction.purchaseDate,
                                userEmail: userEmail
                            )
                        }
                        creditsGranted += syncResult.creditsAdded
                        await transaction.finish()
                    }
                } catch {
                    print("Error processing entitlement: \(error)")
                }
            }

            if creditsGranted > 0 {
                await userSession.syncCreditsFromServer()
                NotificationCenter.default.post(name: .creditsDidChange, object: nil)
            }
        }
    }

    // MARK: - Verification

    /// Validates that a transaction's JWS signature is valid.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unverifiedTransaction
        case .verified(let transaction):
            return transaction
        }
    }

    // MARK: - Helpers

    private func getUserSession() async -> UserSession? {
        // In a real app, you'd access the UserSession from your app's environment
        // For now, we'll load it from storage
        return UserSession.load()
    }

    /// Determines if an error is transient and should be retried.
    private func isTransientError(_ error: Error) -> Bool {
        if let error = error as? URLError {
            switch error.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }

    /// Executes an async operation with exponential backoff retry logic.
    /// Automatically retries on transient errors up to maxRetries times.
    private func executeWithRetry<T>(_ operation: () async throws -> T) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry if error is not transient or this was the last attempt
                guard isTransientError(error) && attempt < maxRetries - 1 else {
                    throw error
                }

                // Calculate exponential backoff with jitter
                let backoff = pow(2.0, Double(attempt)) * initialBackoffSeconds
                let jitter = Double.random(in: 0..<0.1) * backoff
                let delaySeconds = min(backoff + jitter, maxBackoffSeconds)

                print("Transient error (attempt \(attempt + 1)/\(maxRetries)): \(error.localizedDescription). Retrying in \(String(format: "%.1f", delaySeconds))s")

                // Sleep before retrying
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }

        throw lastError ?? StoreKitError.retryExhausted
    }
}

// MARK: - Error Handling

enum StoreKitError: LocalizedError {
    case unverifiedTransaction
    case retryExhausted

    var errorDescription: String? {
        switch self {
        case .unverifiedTransaction:
            return "Transaction verification failed"
        case .retryExhausted:
            return "Failed after maximum retry attempts. Please check your network connection."
        }
    }
}

// MARK: - StoreKit Product Extensions

extension Product {
    /// Credit count for this product based on product ID
    var creditCount: Int {
        switch id {
        case "com.neatlify.Desktop.starter":
            return 100
        case "com.neatlify.Desktop.pro":
            return 1_000
        case "com.neatlify.Desktop.business":
            return 10_000
        default:
            return 0
        }
    }

    /// Display name for this product (short form)
    var shortDisplayName: String {
        switch id {
        case "com.neatlify.Desktop.starter":
            return "Starter"
        case "com.neatlify.Desktop.pro":
            return "Pro"
        case "com.neatlify.Desktop.business":
            return "Business"
        default:
            return self.displayName
        }
    }
}
