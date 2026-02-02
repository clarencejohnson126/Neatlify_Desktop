# Neatlify Desktop - Project Context

## Overview
Neatlify is an AI-powered file organization app for macOS. It scans user files, uses Claude AI to suggest organization, and moves files into categorized folders.

## Architecture

### macOS App (Swift/SwiftUI)
- **Location:** `Neatlify Desktop/`
- **Bundle ID:** `com.neatlify.desktop`
- **URL Scheme:** `neatlify://` (for deep linking from web)

### Landing Page (React/TypeScript)
- **Location:** Root directory (`LandingPage.tsx`, `SuccessPage.tsx`, etc.)
- **Hosted at:** neatlify.com

### Backend (Supabase)
- **Project ID:** `nlvlwrhayrvberdyjgjx`
- **Database:** PostgreSQL with tables for `profiles`, `promo_codes`, `promo_code_redemptions`
- **Edge Functions:** `check-credits`, `verify-payment`, `redeem-promo-code`

## Key Files

### Swift App
- `OrganizationViewModel.swift` - Core file organization logic
- `ContentView.swift` - Main UI with PreviewSheet
- `UserSession.swift` - User state management
- `PaywallView.swift` - Credit purchase UI with promo code support
- `SupabaseService.swift` - Backend communication
- `ClaudeAPIService.swift` - AI integration

### Landing Page
- `LandingPage.tsx` - Main marketing page
- `SuccessPage.tsx` - Post-payment redirect page
- `translations.ts` - i18n support

## Monetization Model
- **Scan:** Free (preview results before paying)
- **Execute:** Paid (1 credit = 1 file organized)
- **Credit Packs:** Starter (100/€5), Pro (1000/€30), Business (10000/€200)
- **Promo Codes:** NEATLIFY-FAMILY-* (100 credits), NEATLIFY-FRIEND-* (50 credits)

## Apple Developer
- **Team ID:** YH8992LT9F
- **Apple ID:** thinkbig@rebelz-ai.com
- **Notarization Profile:** `neatlify` (stored in keychain)
- **API Key:** AuthKey_R776AP4V4Q.p8
- **Issuer ID:** 3dc151f6-8ecc-4f87-bca9-2cb851a82785

## Important Notes
- App requires "Hardened Runtime" capability for notarization
- Signing must use "Developer ID Application" certificate (not Apple Development)
- Credits sync between app and server via `SupabaseService`
- `NotificationCenter.default.post(name: .creditsDidChange)` triggers UI updates
