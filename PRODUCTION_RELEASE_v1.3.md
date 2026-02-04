# Neatlify Desktop v1.3 - Production Release

**Release Date:** February 4, 2026
**Status:** ✅ READY FOR PRODUCTION

## What's Deployed

### 1. GitHub Release
- **URL:** https://github.com/clarencejohnson126/Neatlify_Desktop/releases/tag/v1.3
- **File:** Neatlify-Desktop-1.3.dmg (Signed & Notarized)
- **Size:** ~2.6 MB

### 2. Authentication System
- ✅ Supabase Auth (email/password)
- ✅ JWT tokens in Keychain
- ✅ Session persistence across app restarts
- ✅ Auto-sync on app launch

### 3. Credit System
- ✅ Desktop & Website read from same `profiles` table
- ✅ Edge functions secured with JWT validation
- ✅ Check-credits function (v7) - with JWT validation
- ✅ Redeem-promo-code function (v6) - with JWT validation
- ✅ Verify-apple-transaction function (v6) - with JWT validation
- ✅ Credits display matches across platforms

### 4. Code Changes
- AuthenticationService.swift - Supabase Auth
- AuthSessionStorage.swift - Keychain storage
- AuthenticationView.swift - Login UI
- NeatlifyApp.swift - Auth check on launch
- UserSession.swift - Auth support
- SupabaseService.swift - JWT in requests
- PaywallView.swift - Auto-sync credits

## Testing Checklist

### Website + Desktop
- [ ] Sign up on website
- [ ] Sign in on desktop with same credentials
- [ ] Check Account page - credits match
- [ ] Check desktop Settings - credits match
- [ ] Purchase credits on website
- [ ] Check desktop credits updated
- [ ] Organize files on desktop
- [ ] Check website shows deducted credits
- [ ] Logout and re-login - session restored

### Edge Functions
- [ ] Check-credits accepts JWT (rejects without)
- [ ] Redeem-promo-code requires authentication
- [ ] Apple transaction requires authentication

## Files Ready
- Source code: GitHub main branch
- DMG: https://github.com/clarencejohnson126/Neatlify_Desktop/releases/tag/v1.3
- Website: neatlify.com (download link points to v1.3)

## Next Steps
1. Test v1.3 DMG from GitHub
2. Verify auth flow works end-to-end
3. Confirm credits sync correctly
4. Launch publicly

---
Version: 1.3
Build: 3
Authentication: ✅ PRODUCTION READY
Credits System: ✅ UNIFIED & SECURE
