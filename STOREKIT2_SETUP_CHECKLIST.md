# StoreKit 2 Integration - Setup Checklist

## Code Implementation ✅ COMPLETE

- ✅ `DistributionDetector.swift` - Runtime distribution detection
- ✅ `StoreKitManager.swift` - StoreKit 2 manager with full transaction handling
- ✅ `SupabaseService.swift` - Added `verifyAppleTransaction()` method
- ✅ `PaywallView.swift` - Conditional UI for StoreKit vs Stripe
- ✅ `NeatlifyApp.swift` - Initialize StoreKit transaction listener
- ✅ `Neatlify_Desktop.entitlements` - Added in-app purchase capability
- ✅ `verify-apple-transaction.ts` - Edge Function for transaction verification
- ✅ `apple_transactions.sql` - Database migration for transaction tracking

## Next Steps - Backend Setup ⏳

### 1. Deploy Database Migration
```bash
# Run in Supabase SQL editor or via CLI
# File: supabase-migrations/apple_transactions.sql

# This creates the apple_transactions table
# Prevents duplicate credit grants
```

**Action:** Execute the SQL migration in Supabase Dashboard

### 2. Deploy Edge Function
```bash
# Deploy via Supabase CLI
supabase functions deploy verify-apple-transaction

# Or upload manually via Supabase Dashboard
# File: supabase-edge-functions/verify-apple-transaction.ts
```

**Action:** Deploy the Edge Function to verify Apple transactions

**Verify:** Test endpoint returns 200 with sample JWS token

### 3. Update Supabase RPC (if needed)
Verify the `add_credits` RPC exists in your Supabase:
```sql
-- Should exist already (used for Stripe too)
-- Called by: verify-apple-transaction Edge Function
-- Function: add_credits(p_email TEXT, p_credits INT)
```

**Action:** Confirm `add_credits` RPC exists, or create if missing

## Next Steps - App Store Setup ⏳

### 1. Create Products in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your Neatlify app
3. Go to "In-App Purchases"
4. Create 3 consumable products:

| Product ID | Type | Price | Description |
|---|---|---|---|
| `com.neatlify.Desktop.starter` | Consumable | €5 | 100 Files |
| `com.neatlify.Desktop.pro` | Consumable | €30 | 1,000 Files |
| `com.neatlify.Desktop.business` | Consumable | €200 | 10,000 Files |

**Action:** Create all 3 products with exact IDs

### 2. Create Sandbox Test Account
1. In App Store Connect: Accounts → Testers
2. Create test user for sandbox testing
3. Record email and password

**Action:** Create at least one sandbox tester account

### 3. Setup In-App Purchase Certificates
1. In App Store Connect: Certificates, Identifiers & Profiles
2. Ensure `com.neatlify.desktop` identifier has In-App Purchase capability
3. Download/refresh certificates for signing

**Action:** Verify IAP capability is enabled in your App ID

### 4. Update Build Settings (Xcode)
1. Open `Neatlify Desktop.xcodeproj`
2. Select target "Neatlify Desktop"
3. Go to "Signing & Capabilities"
4. Add capability: "In-App Purchases"
5. Verify "Hardened Runtime" is enabled

**Action:** Configure Xcode signing for App Store

## Testing Checklist ⏳

### Before Submission
- [ ] Build app in Debug mode
  - [ ] PaywallView shows Stripe cards (DMG mode)
  - [ ] `DistributionDetector.isAppStoreDistribution` == false

- [ ] Build app with Release scheme
  - [ ] PaywallView shows Stripe cards (no receipt)
  - [ ] `DistributionDetector.isAppStoreDistribution` == false

- [ ] Sandbox testing (requires Apple account)
  - [ ] Sign out of App Store on Mac
  - [ ] Run app from Xcode
  - [ ] Should show "StoreKit products" section if receipts can be simulated
  - [ ] Verify product prices display correctly
  - [ ] Click purchase (sandbox purchase sheet appears)
  - [ ] Use sandbox tester account from App Store Connect
  - [ ] Verify purchase completes successfully
  - [ ] Verify credits appear in app (check Supabase logs)
  - [ ] Verify `apple_transactions` table has new entry

### Regression Testing
- [ ] DMG version still works with Stripe
  - [ ] Purchase via Stripe
  - [ ] Credits appear correctly
  - [ ] Promo codes still work

## Deployment Steps ⏳

### 1. Create App Store Build
```bash
# In Xcode, create archive:
# Product → Archive

# Distribute to App Store Connect
# Choose: Direct Distribution to App Store
```

**Action:** Build and submit to App Store for review

### 2. App Store Review
- Apple reviews IAP setup
- Ensures products are configured correctly
- Verifies in-app purchase eligibility

**Expected time:** 24-48 hours

### 3. After Approval
1. Add version to App Store release
2. Configure pricing/availability
3. Release to production

**Action:** Submit for review, monitor Apple's feedback

## Post-Launch Monitoring ⏳

### Monitor Transaction Success
Check Supabase logs weekly:
```sql
-- Transaction verification success rate
SELECT COUNT(*) as verified_count FROM apple_transactions WHERE created_at > now() - interval '7 days';

-- Check for failed verifications in Edge Function logs
-- Dashboard → Edge Functions → verify-apple-transaction → Logs
```

### Monitor User Adoption
```sql
-- How many users used StoreKit vs Stripe?
-- Would need to track distribution method in analytics
```

### Alert on Failures
- Setup Supabase alert for Edge Function errors
- Monitor credit grant failures
- Watch for duplicate transaction attempts

## Troubleshooting Guide ⏳

### Products Not Loading
**Symptom:** PaywallView shows empty product list in App Store version
**Cause:** Product IDs don't match App Store Connect
**Fix:**
1. Verify product IDs in `StoreKitManager` match App Store Connect exactly
2. Ensure products are "Ready to Submit"
3. Wait a few minutes for propagation
4. Restart app and try again

### Purchase Fails Silently
**Symptom:** User clicks purchase, nothing happens
**Cause:** Network error or JWS verification failed
**Debug:**
1. Check `storeKit.lastError` in code
2. Review Supabase `verify-apple-transaction` Edge Function logs
3. Ensure user is logged in (has email set)
4. Check network connectivity

### Duplicate Credits Appearing
**Symptom:** User purchased once, got credits twice
**Cause:** Duplicate transaction insertion
**Fix:**
1. Check `apple_transactions` table for duplicate `original_transaction_id`
2. Manual cleanup if needed
3. Verify database unique constraint is active
4. Review transaction listener error logs

### App Store Sandbox Not Working
**Symptom:** Can't test with sandbox account
**Cause:** Account not configured correctly
**Fix:**
1. Verify sandbox account created in App Store Connect
2. Sign out of App Store on Mac completely
3. Restart app
4. Try purchase again
5. May need to adjust System Settings → Users & Groups → iCloud

## Configuration Files Created

Files that need to be tracked in git:

```
Neatlify Desktop/
├── Services/
│   ├── DistributionDetector.swift          ✅ NEW
│   ├── StoreKitManager.swift               ✅ NEW
│   └── SupabaseService.swift               ✅ UPDATED
├── Views/
│   └── PaywallView.swift                   ✅ UPDATED
├── Neatlify Desktop/
│   ├── NeatlifyApp.swift                   ✅ UPDATED
│   └── Neatlify_Desktop.entitlements       ✅ UPDATED
├── STOREKIT2_IMPLEMENTATION.md             ✅ NEW (documentation)
├── STOREKIT2_SETUP_CHECKLIST.md            ✅ NEW (this file)
│
supabase-migrations/
├── apple_transactions.sql                  ✅ NEW

supabase-edge-functions/
└── verify-apple-transaction.ts             ✅ NEW
```

## Questions & Support

**Q: Can I test StoreKit on simulator?**
A: Not directly - requires actual Mac with App Store access. For local testing, use `DistributionDetector` debug mode.

**Q: What if product doesn't appear after creation in App Store Connect?**
A: New products need ~30 minutes to propagate. Also verify:
- Product ID matches exactly (case-sensitive)
- Product is in "Ready to Submit" status
- App has in-app purchase capability enabled

**Q: How do I verify JWS token format is correct?**
A: In Xcode debugger:
```swift
// In StoreKitManager.purchase():
print("JWS Token: \(transaction.jwsRepresentation)")
// Copy and decode at https://jwt.io to inspect payload
```

**Q: Should I remove Stripe completely?**
A: No! Keep both:
- App Store version uses StoreKit
- DMG version uses Stripe
- Single codebase with runtime detection
- Easy to switch between distributions

**Q: What if credit granting fails for one payment method?**
A: User sees error message. On next app launch:
- `onReceive(NSApplication.didBecomeActiveNotification)` triggers
- Calls `userSession.syncCreditsFromServer()`
- Fetches latest balance from Supabase
- Catches up any missed credits

---

## Estimated Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| A | Code Implementation | ✅ Complete | Done |
| B | Deploy Supabase | 15-30 min | ⏳ Next |
| C | Create App Store Products | 30-60 min | ⏳ Next |
| D | Testing in Sandbox | 1-2 hours | ⏳ Next |
| E | App Store Submission | 10 min submit, 24-48h review | ⏳ Next |
| F | Post-Launch Monitoring | Ongoing | ⏳ After approval |

**Total Implementation Time:** ~4-6 hours from now

---

Last updated: 2026-02-02
Implementation complete. Ready for backend setup and App Store configuration.
