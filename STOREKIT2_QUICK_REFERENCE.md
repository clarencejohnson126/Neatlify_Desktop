# StoreKit 2 Integration - Quick Reference Card

## For Developers

### Key Classes

```swift
// Distribution Detection
DistributionDetector.shared.isAppStoreDistribution  // true/false

// StoreKit Management
StoreKitManager.shared.products                     // [Product]
StoreKitManager.shared.lastError                    // String?
StoreKitManager.shared.purchaseInProgress           // Bool

await StoreKitManager.shared.purchase(product)      // Transaction?
await StoreKitManager.shared.restorePurchases()     // Void
```

### Payment Method Switching

```swift
let isAppStore = DistributionDetector.shared.isAppStoreDistribution

if isAppStore {
    // Use StoreKit
    ForEach(storeKit.products) { product in
        StoreKitPackCard(product) { purchaseWithStoreKit(product) }
    }
} else {
    // Use Stripe
    CreditPackCard(...) { purchasePack(.starter) }
}
```

### Backend Communication

```swift
// Verify Apple transaction (called automatically by StoreKitManager)
try await SupabaseService.shared.verifyAppleTransaction(
    jwsToken: transaction.jwsRepresentation,
    productId: transaction.productID,
    userEmail: userSession.userEmail!
)
// Returns: AppleTransactionResult(creditsAdded, creditsTotal)
```

### Product IDs to Memorize

| ID | Credits | Price |
|----|---------|-------|
| `com.neatlify.Desktop.starter` | 100 | €5 |
| `com.neatlify.Desktop.pro` | 1,000 | €30 |
| `com.neatlify.Desktop.business` | 10,000 | €200 |

### Notifications

```swift
// Posted when credits change (both StoreKit and Stripe)
NotificationCenter.default.publisher(for: .creditsDidChange)

// Listen in your view
.onReceive(NotificationCenter.default.publisher(for: .creditsDidChange)) { _ in
    // Refresh UI
}
```

### Common Tasks

#### Test Distribution Detection
```bash
# Debug = always direct
# Release = depends on receipt
xcodebuild -scheme "Neatlify Desktop" -configuration Debug
xcodebuild -scheme "Neatlify Desktop" -configuration Release
```

#### Debug StoreKit Issues
```swift
// In Xcode debugger
po StoreKitManager.shared.products         // See loaded products
po StoreKitManager.shared.lastError        // See error message
po DistributionDetector.shared.method      // See distribution type
```

#### Check Transaction (Sandbox)
1. Sign out of App Store completely
2. Run app from Xcode
3. Go to PaywallView
4. If showing StoreKit products: good (or try `po StoreKitManager.shared.products` in debugger)
5. Click purchase
6. Use sandbox credentials from App Store Connect

#### Monitor Production Issues
```sql
-- Check verified transactions
SELECT COUNT(*) FROM apple_transactions WHERE created_at > now() - interval '24 hours';

-- Check duplicate attempts
SELECT original_transaction_id, COUNT(*) FROM apple_transactions GROUP BY original_transaction_id HAVING COUNT(*) > 1;

-- Check credits granted
SELECT SUM(credits_granted) FROM apple_transactions WHERE created_at > now() - interval '7 days';
```

### Entitlement Configuration

✅ Already in `Neatlify_Desktop.entitlements`:
```xml
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.neatlify.desktop</string>
</array>
```

### App Store Connect Setup

1. **Products** → Create 3 consumables with exact IDs
2. **Identifiers** → Verify in-app purchase capability
3. **Testers** → Create sandbox account
4. **Certificates** → Download signing certificates

### Testing Checklist

- [ ] Debug build shows Stripe (DMG)
- [ ] Release build (no receipt) shows Stripe
- [ ] Sandbox build (with receipt) shows StoreKit
- [ ] Products load with correct prices
- [ ] Purchase completes with sandbox account
- [ ] Credits appear immediately
- [ ] Stripe purchases still work
- [ ] Promo codes work on both paths
- [ ] Restore Purchases button works

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Products not found" | IDs don't match App Store Connect | Verify IDs in StoreKitManager |
| "Unverified transaction" | JWS signature invalid | Check Edge Function logs |
| "Credits not added" | Email not set in UserSession | User must link account first |
| "Duplicate credits" | Transaction processed twice | Check `original_transaction_id` |
| "Purchase hangs" | Network issue | Check Supabase connectivity |

### Key Files for Maintenance

| File | Purpose | When to Change |
|------|---------|---|
| `StoreKitManager.swift` | Core StoreKit logic | New products, payment changes |
| `PaywallView.swift` | Payment UI | UI redesign, new cards |
| `verify-apple-transaction.ts` | Backend verification | Apple API changes, fraud rules |
| `DistributionDetector.swift` | Detection logic | Signing/distribution changes |
| `SupabaseService.swift` | API communication | Backend endpoint changes |

### Performance Notes

- **Product loading**: ~500ms network call, cached in @StateObject
- **Purchase**: 5-10 seconds (system sheet), non-blocking UI
- **Transaction sync**: <1 second (Supabase call)
- **Listener**: Negligible CPU impact (async only on new transactions)

### Security Reminders

1. ✅ JWS verified server-side (never locally)
2. ✅ Duplicates prevented by DB unique constraint
3. ✅ Email validation required (user logged in)
4. ✅ All HTTPS connections
5. ✅ No hardcoded secrets in client code

### Production Rollout Steps

1. Deploy `apple_transactions.sql` to Supabase
2. Deploy `verify-apple-transaction.ts` Edge Function
3. Create products in App Store Connect
4. Build archive for App Store
5. Submit for review (Apple: 24-48 hours)
6. Monitor transaction success rate
7. Alert on errors or fraud

### Support Resources

- Apple StoreKit 2 docs: https://developer.apple.com/storekit/
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- App Store Connect: https://appstoreconnect.apple.com
- Test Flight: https://testflight.apple.com

### Useful Code Snippets

#### Force Product Reload
```swift
Task {
    await StoreKitManager.shared.loadProducts()
}
```

#### Get Credit Count from Product
```swift
let credits = 0 // Use product.creditCount extension

// Add to StoreKit.Product extension:
extension Product {
    var creditCount: Int {
        switch id {
        case "com.neatlify.Desktop.starter": return 100
        case "com.neatlify.Desktop.pro": return 1_000
        case "com.neatlify.Desktop.business": return 10_000
        default: return 0
        }
    }
}
```

#### Manual Credit Sync
```swift
Task {
    await userSession.syncCreditsFromServer()
    NotificationCenter.default.post(name: .creditsDidChange, object: nil)
}
```

#### Check if Payment Required
```swift
func canProceed() -> Bool {
    return userSession.isAccountLinked &&
           userSession.fileCredits > 0
}
```

---

**Bookmark this page for quick reference during development!**

Last updated: 2026-02-02
