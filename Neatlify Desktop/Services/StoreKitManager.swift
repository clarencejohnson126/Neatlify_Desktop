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

    // UserDefaults key for pending transactions that failed to sync
    private static let pendingTransactionsKey = "com.neatlify.pendingAppleTransactions"

    @Published var products: [Product] = []
    @Published var isLoadingProducts = false
    @Published var purchaseInProgress = false
    @Published var lastError: String?
    @Published var lastPurchaseCredits: Int = 0
    @Published var showPurchaseSuccess = false

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

        // Retry any pending transactions from previous sessions
        Task {
            await syncPendingTransactions()
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
    ///
    /// Credit-grant policy: the moment StoreKit returns a JWS-verified transaction,
    /// the user has paid Apple and we must show success and surface credits in the UI.
    /// We grant locally first, then reconcile with the server in the background.
    /// If server sync fails we keep the transaction unfinished and retry — but the
    /// user never sees "You're all set" without their credits arriving.
    func purchase(_ product: Product) async -> Transaction? {
        purchaseInProgress = true
        lastError = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                let credits = product.creditCount

                // 1. Grant credits locally immediately so the UI reflects the purchase.
                if let userSession = await getUserSession() {
                    userSession.fileCredits += credits
                    userSession.save()
                    NotificationCenter.default.post(name: .creditsDidChange, object: nil)
                }

                // 2. Show success feedback right away.
                lastPurchaseCredits = credits
                showPurchaseSuccess = true

                // 3. Reconcile with the server. The backend dedups by
                //    original_transaction_id so retries are safe.
                let syncSuccess = await syncTransactionWithServer(transaction, applyServerTotal: false)
                if syncSuccess {
                    await transaction.finish()
                } else {
                    // Keep transaction unfinished — Transaction.updates / syncPendingTransactions()
                    // will retry. User already has their credits locally.
                    savePendingTransaction(transaction)
                    Logger.shared.warning("Credits granted locally; server sync failed for \(transaction.originalID), will retry")
                }
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
                    let syncSuccess = await syncTransactionWithServer(transaction)
                    if syncSuccess {
                        await transaction.finish()
                        removePendingTransaction(id: String(transaction.originalID))
                    } else {
                        savePendingTransaction(transaction)
                        Logger.shared.warning("Transaction listener: sync failed for \(transaction.originalID), will retry later")
                    }
                } else {
                    await transaction.finish()
                }
            } catch {
                Logger.shared.error("Transaction listener error: \(error)")
            }
        }
    }

    // MARK: - Server Sync

    /// Syncs a verified transaction with the Supabase backend.
    /// Returns true if sync succeeded, false otherwise.
    /// Automatically retries on transient network failures.
    ///
    /// - Parameter applyServerTotal: when true, overwrites local `fileCredits` with the
    ///   server's authoritative balance. Set to false when credits were already granted
    ///   locally (purchase flow) — the server `credits_total` can be stale or lag, and
    ///   we don't want to ever *reduce* a user's visible balance after a successful purchase.
    @discardableResult
    private func syncTransactionWithServer(_ transaction: Transaction, applyServerTotal: Bool = true) async -> Bool {
        guard let userSession = await getUserSession() else {
            Logger.shared.error("Cannot sync transaction: no user session")
            return false
        }

        guard let userEmail = userSession.userEmail else {
            Logger.shared.error("Cannot sync transaction: user not logged in")
            return false
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

            if applyServerTotal, let serverTotal = result.creditsTotal {
                // Only trust the server total when it's at least as high as what we have
                // locally. Protects against stale reads / profile-lookup misses that would
                // wipe out a user's balance.
                if serverTotal >= userSession.fileCredits {
                    userSession.fileCredits = serverTotal
                    userSession.save()
                    NotificationCenter.default.post(name: .creditsDidChange, object: nil)
                } else {
                    Logger.shared.warning("Server returned lower total (\(serverTotal)) than local (\(userSession.fileCredits)); keeping local")
                }
            }

            Logger.shared.info("Transaction synced: +\(result.creditsAdded) credits, server total: \(result.creditsTotal.map(String.init) ?? "n/a")")
            return true
        } catch {
            Logger.shared.error("Failed to sync Apple transaction with server: \(error)")
            return false
        }
    }

    // MARK: - Restoration

    /// Restores previously purchased products from the user's account.
    /// Processes both unfinished transactions (failed syncs) and current entitlements.
    /// Automatically retries on transient network failures.
    func restorePurchases() async {
        guard let userSession = await getUserSession() else {
            lastError = "Please sign in to restore purchases."
            Logger.shared.error("Cannot restore purchases: no user session")
            return
        }

        guard let userEmail = userSession.userEmail else {
            lastError = "Please sign in to restore purchases."
            Logger.shared.error("Cannot restore purchases: user not logged in")
            return
        }

        purchaseInProgress = true
        lastError = nil
        defer { purchaseInProgress = false }

        var creditsGranted = 0

        // First: process any unfinished transactions (from failed syncs)
        for await result in Transaction.unfinished {
            do {
                let transaction = try checkVerified(result)

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
                    removePendingTransaction(id: String(transaction.originalID))
                    Logger.shared.info("Restored unfinished transaction: +\(syncResult.creditsAdded) credits")
                }
            } catch {
                Logger.shared.error("Error processing unfinished transaction: \(error)")
            }
        }

        // Second: process current entitlements (non-consumables, subscriptions)
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

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
                Logger.shared.error("Error processing entitlement: \(error)")
            }
        }

        // Third: retry any pending transactions saved to UserDefaults
        await syncPendingTransactions()

        // Sync credits from server to get authoritative total
        await userSession.syncCreditsFromServer()
        NotificationCenter.default.post(name: .creditsDidChange, object: nil)

        if creditsGranted > 0 {
            lastPurchaseCredits = creditsGranted
            showPurchaseSuccess = true
            Logger.shared.info("Restore complete: +\(creditsGranted) credits")
        } else {
            lastError = "No purchases to restore."
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

    // MARK: - Pending Transaction Storage

    /// Saved transaction info for retry when server sync fails
    private struct PendingTransaction: Codable {
        let transactionId: String
        let originalTransactionId: String
        let productId: String
        let purchaseDate: Date
        let savedAt: Date
    }

    /// Save a transaction to UserDefaults for later retry
    private func savePendingTransaction(_ transaction: Transaction) {
        var pending = loadPendingTransactions()

        // Don't duplicate
        if pending.contains(where: { $0.originalTransactionId == String(transaction.originalID) }) {
            return
        }

        pending.append(PendingTransaction(
            transactionId: String(transaction.id),
            originalTransactionId: String(transaction.originalID),
            productId: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            savedAt: Date()
        ))

        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: Self.pendingTransactionsKey)
        }
        Logger.shared.info("Saved pending transaction: \(transaction.originalID)")
    }

    /// Remove a successfully synced pending transaction
    private func removePendingTransaction(id: String) {
        var pending = loadPendingTransactions()
        pending.removeAll { $0.originalTransactionId == id }
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: Self.pendingTransactionsKey)
        }
    }

    private func loadPendingTransactions() -> [PendingTransaction] {
        guard let data = UserDefaults.standard.data(forKey: Self.pendingTransactionsKey),
              let pending = try? JSONDecoder().decode([PendingTransaction].self, from: data) else {
            return []
        }
        return pending
    }

    /// Retry syncing any pending transactions that previously failed.
    /// Called on app launch and when app becomes active.
    func syncPendingTransactions() async {
        let pending = loadPendingTransactions()
        guard !pending.isEmpty else { return }

        Logger.shared.info("Retrying \(pending.count) pending transaction(s)...")

        guard let userSession = await getUserSession() else { return }
        guard let userEmail = userSession.userEmail else { return }

        for pendingTx in pending {
            do {
                let result = try await SupabaseService.shared.verifyAppleTransaction(
                    transactionId: pendingTx.transactionId,
                    originalTransactionId: pendingTx.originalTransactionId,
                    productId: pendingTx.productId,
                    purchaseDate: pendingTx.purchaseDate,
                    userEmail: userEmail
                )

                // Success - remove from pending and reconcile credits.
                // Use the server total only if it's at least as high as local, otherwise
                // keep what we have (server may be stale and we already granted locally).
                removePendingTransaction(id: pendingTx.originalTransactionId)
                if let serverTotal = result.creditsTotal, serverTotal >= userSession.fileCredits {
                    userSession.fileCredits = serverTotal
                    userSession.save()
                    NotificationCenter.default.post(name: .creditsDidChange, object: nil)
                }
                Logger.shared.info("Pending transaction synced: +\(result.creditsAdded) credits")

                // Also try to finish the corresponding StoreKit transaction
                for await txResult in Transaction.unfinished {
                    if let tx = try? checkVerified(txResult),
                       String(tx.originalID) == pendingTx.originalTransactionId {
                        await tx.finish()
                        break
                    }
                }
            } catch {
                Logger.shared.error("Pending transaction retry failed for \(pendingTx.originalTransactionId): \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func getUserSession() async -> UserSession? {
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
