---
name: add-language
description: Add localization support for new languages
arguments:
  - name: lang
    description: "Language code to add (e.g., 'ja', 'ko', 'zh')"
    required: true
---

# Localization Support Guide

Add new language support to Neatlify Desktop and Landing Page.

## Current Language Support

### Claude API (ClaudeAPIService.swift)
**Supported:** en, de, es, fr, it, pt, nl (7 languages)

```swift
// Language passed to Claude for responses
let supportedLanguages = ["en", "de", "es", "fr", "it", "pt", "nl"]
```

### Landing Page (translations.ts)
**Supported:** English (en), German (de)

### Swift App UI
**Current state:** Hardcoded English - NO `.strings` files exist

## Adding a New Language

### Step 1: Update Claude API Language Support

```swift
// ClaudeAPIService.swift
let supportedLanguages = ["en", "de", "es", "fr", "it", "pt", "nl", "NEW_LANG"]
```

The AI will respond in the user's language automatically.

### Step 2: Add Landing Page Translations

Edit `translations.ts`:

```typescript
// Current structure
export const translations = {
  en: {
    hero: {
      title: "AI-Powered File Organization",
      subtitle: "Clean up your Mac in seconds",
      // ...
    },
    // ...
  },
  de: {
    hero: {
      title: "KI-gestützte Dateiorganisation",
      subtitle: "Räumen Sie Ihren Mac in Sekunden auf",
      // ...
    },
    // ...
  },
  // ADD NEW LANGUAGE:
  NEW_LANG: {
    hero: {
      title: "...",
      subtitle: "...",
      // Copy all keys from 'en' and translate
    },
    // ...
  }
}
```

### Step 3: Add Swift App Localization (Currently Missing!)

#### 3a. Create Localizable.strings

```
Neatlify Desktop/
└── Neatlify Desktop/
    └── Resources/
        └── en.lproj/
            └── Localizable.strings
        └── de.lproj/
            └── Localizable.strings
        └── NEW_LANG.lproj/
            └── Localizable.strings
```

#### 3b. Create Base Localizable.strings (English)

```strings
/* ContentView */
"scan_button" = "Scan Folder";
"organize_button" = "Organize Files";
"cancel_button" = "Cancel";
"credits_remaining" = "%d credits remaining";

/* PaywallView */
"buy_credits" = "Buy Credits";
"starter_pack" = "Starter Pack";
"pro_pack" = "Pro Pack";
"promo_code_placeholder" = "Enter promo code";

/* OrganizationView */
"scanning" = "Scanning files...";
"organizing" = "Organizing...";
"complete" = "Organization complete!";
"files_organized" = "%d files organized";

/* Errors */
"error_no_permission" = "Please grant folder access permission";
"error_api_failed" = "Failed to analyze files. Please try again.";
"error_insufficient_credits" = "Not enough credits";
```

#### 3c. Update Swift Code to Use Localization

**Before:**
```swift
Button("Scan Folder") { ... }
```

**After:**
```swift
Button(NSLocalizedString("scan_button", comment: "Scan folder button")) { ... }

// Or with SwiftUI:
Button(LocalizedStringKey("scan_button")) { ... }
```

#### 3d. Enable Localization in Xcode

1. Open `project.pbxproj`
2. Add new localization under project settings
3. Create `.lproj` folders for each language

### Step 4: Language Detection

```swift
// UserSession.swift - Add language preference
@AppStorage("preferredLanguage") var preferredLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
```

## Translation Keys Reference

### Landing Page (translations.ts) - 659 lines total

Major sections:
- `hero` - Main banner
- `features` - Feature descriptions
- `pricing` - Credit packs
- `faq` - Questions and answers
- `footer` - Links and copyright

### Swift App - Strings to Extract

| View | Hardcoded Strings |
|------|-------------------|
| ContentView | "Scan Folder", "Select Folder", etc. |
| PaywallView | "Buy Credits", pack names, prices |
| PreviewSheet | "Preview", "Organize Now", etc. |
| ChatView | "Type a message...", "Send" |

## Testing Localization

```swift
// Force a specific language for testing
UserDefaults.standard.set(["de"], forKey: "AppleLanguages")
```

## Language Codes Reference

| Language | Code | Claude API | Landing | Swift App |
|----------|------|------------|---------|-----------|
| English | en | ✅ | ✅ | ✅ (hardcoded) |
| German | de | ✅ | ✅ | ❌ |
| Spanish | es | ✅ | ❌ | ❌ |
| French | fr | ✅ | ❌ | ❌ |
| Italian | it | ✅ | ❌ | ❌ |
| Portuguese | pt | ✅ | ❌ | ❌ |
| Dutch | nl | ✅ | ❌ | ❌ |
| Japanese | ja | ❌ | ❌ | ❌ |
| Korean | ko | ❌ | ❌ | ❌ |
| Chinese | zh | ❌ | ❌ | ❌ |
