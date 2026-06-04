---
name: release
description: Build, sign, notarize, and package Neatlify Desktop for release
arguments:
  - name: version
    description: "Version number (e.g., '1.2.0')"
    required: true
---

# Neatlify Desktop Release Workflow

Complete workflow for releasing Neatlify Desktop.

> ⚠️ **TWO DISTRIBUTION CHANNELS — DO NOT MIX THEM.**
> The schemes named `Neatlify Desktop` / config `Release` referenced in the old DMG steps below are **NOT** for the App Store. The submitted App Store binary MUST come from the **`Neatlify Desktop AppStore`** scheme + **`AppStore`** config (which defines `SWIFT_ACTIVE_COMPILATION_CONDITIONS = APPSTORE`). Building the App Store upload from the `Release` config is what caused the build-13 Guideline 3.1.1 rejection.
>
> | Channel | Scheme | Config | Signing | Export plist |
> |---------|--------|--------|---------|--------------|
> | **A. App Store (IAP)** | `Neatlify Desktop AppStore` | `AppStore` | Apple Distribution (automatic) | `Neatlify Desktop/export-appstore.plist` (method=app-store-connect, destination=upload) |
> | **B. Direct DMG** | `Neatlify Desktop DMG` | `Release` | Developer ID Application | `export-options.plist` (method=developer-id) |

## Channel A — App Store submission (App Store Connect)

Use this for every App Store review/resubmission. Uploads straight to ASC, no Xcode.app.

### A0. Pre-flight (do these or the submission fails review)
- [ ] Bump build: `CFBundleVersion` in **both** `Neatlify Desktop/Info.plist` AND all `CURRENT_PROJECT_VERSION` in `project.pbxproj` (the build-version trap — they must match and exceed the last rejected build).
- [ ] Move any stale `*.xcarchive` out of `build/` so Organizer/CLI can't pick an old one.
- [ ] Verify the demo account in App Review Information can actually sign in on THIS binary.

### A1. Archive (AppStore scheme + AppStore config)
```bash
cd "/Users/clarence/Desktop/Neatlify Desktop/Neatlify Desktop"
rm -rf /tmp/neatlify-appstore.xcarchive
xcodebuild archive \
  -project "Neatlify Desktop.xcodeproj" \
  -scheme "Neatlify Desktop AppStore" \
  -configuration AppStore \
  -archivePath /tmp/neatlify-appstore.xcarchive \
  -destination 'generic/platform=macOS'
```

### A2. Verify the archive BEFORE upload
```bash
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" \
  /tmp/neatlify-appstore.xcarchive/Products/Applications/"Neatlify Desktop.app"/Contents/Info.plist   # must be the new build number
strings /tmp/neatlify-appstore.xcarchive/Products/Applications/"Neatlify Desktop.app"/Contents/MacOS/"Neatlify Desktop" \
  | grep -E "delete-account|Delete Account"   # must print both — proves the deletion feature is in the binary
```

### A3. Export + upload to App Store Connect
```bash
xcodebuild -exportArchive \
  -archivePath /tmp/neatlify-appstore.xcarchive \
  -exportPath /tmp/neatlify-appstore-export \
  -exportOptionsPlist "/Users/clarence/Desktop/Neatlify Desktop/Neatlify Desktop/export-appstore.plist"
```
`export-appstore.plist` has `destination=upload`, so this validates and uploads the build to App Store Connect. Then in ASC: select build, paste App Review Notes (with working demo credentials), attach the account-deletion screen recording, and submit.

---

## Channel B — Direct DMG distribution (notarized, outside the store)

> The steps below are for the **DMG** channel only. They were originally written with the wrong scheme name; use **`Neatlify Desktop DMG`** / `Release` config here. Never upload a DMG-channel build to the App Store.

## Apple Developer Credentials

| Field | Value |
|-------|-------|
| Team ID | YH8992LT9F |
| Apple ID | thinkbig@rebelz-ai.com |
| Bundle ID | com.neatlify.desktop |
| Notarization Profile | `neatlify` (stored in keychain) |
| API Key | AuthKey_R776AP4V4Q.p8 |
| Issuer ID | 3dc151f6-8ecc-4f87-bca9-2cb851a82785 |

## Pre-Release Checklist

- [ ] All tests pass
- [ ] Version number updated in Xcode
- [ ] Build number incremented
- [ ] Changelog updated
- [ ] Privacy policy current

## Release Steps

### 1. Version Bump

```bash
# Update version in Xcode project
cd "/Users/clarence/Desktop/Neatlify Desktop/Neatlify Desktop"

# Verify current version
grep -A2 "MARKETING_VERSION" "Neatlify Desktop.xcodeproj/project.pbxproj" | head -5
grep -A2 "CURRENT_PROJECT_VERSION" "Neatlify Desktop.xcodeproj/project.pbxproj" | head -5
```

Or in Xcode: Target → General → Version & Build

### 2. Clean Build

```bash
cd "/Users/clarence/Desktop/Neatlify Desktop/Neatlify Desktop"

# Clean build folder
xcodebuild clean -project "Neatlify Desktop.xcodeproj" -scheme "Neatlify Desktop DMG" -configuration Release

# Build archive
xcodebuild archive \
  -project "Neatlify Desktop.xcodeproj" \
  -scheme "Neatlify Desktop DMG" \
  -configuration Release \
  -archivePath "./build/Neatlify Desktop.xcarchive" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="YH8992LT9F"
```

### 3. Export App

```bash
# Create export options plist
cat > export-options.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YH8992LT9F</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

# Export from archive
xcodebuild -exportArchive \
  -archivePath "./build/Neatlify Desktop.xcarchive" \
  -exportPath "./build/export" \
  -exportOptionsPlist "export-options.plist"
```

### 4. Notarize

```bash
# Using stored credentials (keychain profile 'neatlify')
xcrun notarytool submit "./build/export/Neatlify Desktop.app" \
  --keychain-profile "neatlify" \
  --wait

# Check notarization status
xcrun notarytool history --keychain-profile "neatlify"
```

### 5. Staple Notarization Ticket

```bash
xcrun stapler staple "./build/export/Neatlify Desktop.app"

# Verify stapling
xcrun stapler validate "./build/export/Neatlify Desktop.app"
```

### 6. Create DMG

```bash
# Install create-dmg if needed
# brew install create-dmg

create-dmg \
  --volname "Neatlify Desktop" \
  --volicon "./Neatlify Desktop/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Neatlify Desktop.app" 150 190 \
  --hide-extension "Neatlify Desktop.app" \
  --app-drop-link 450 185 \
  --no-internet-enable \
  "./build/Neatlify-${VERSION}.dmg" \
  "./build/export/Neatlify Desktop.app"
```

### 7. Notarize DMG

```bash
xcrun notarytool submit "./build/Neatlify-${VERSION}.dmg" \
  --keychain-profile "neatlify" \
  --wait

xcrun stapler staple "./build/Neatlify-${VERSION}.dmg"
```

### 8. Verify Final Package

```bash
# Verify code signature
codesign --verify --verbose=4 "./build/export/Neatlify Desktop.app"

# Check notarization
spctl --assess --verbose=4 "./build/export/Neatlify Desktop.app"

# Verify DMG
spctl --assess --verbose=4 --type install "./build/Neatlify-${VERSION}.dmg"
```

## One-Liner Release Script

```bash
VERSION="1.2.0" && \
xcodebuild clean archive \
  -project "Neatlify Desktop.xcodeproj" \
  -scheme "Neatlify Desktop DMG" \
  -configuration Release \
  -archivePath "./build/Neatlify.xcarchive" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="YH8992LT9F" && \
xcodebuild -exportArchive \
  -archivePath "./build/Neatlify.xcarchive" \
  -exportPath "./build/export" \
  -exportOptionsPlist "export-options.plist" && \
xcrun notarytool submit "./build/export/Neatlify Desktop.app" \
  --keychain-profile "neatlify" --wait && \
xcrun stapler staple "./build/export/Neatlify Desktop.app"
```

## Troubleshooting

### "Developer ID Application" certificate not found
```bash
# List available certificates
security find-identity -v -p codesigning
```

### Notarization failed
```bash
# Get detailed log
xcrun notarytool log <submission-id> --keychain-profile "neatlify"
```

### Hardened Runtime issues
Ensure these entitlements are set:
- `com.apple.security.hardened-runtime`
- `com.apple.security.files.user-selected.read-write`

## Post-Release

1. Tag release in git: `git tag v${VERSION} && git push --tags`
2. Update website download link
3. Post changelog
4. Monitor crash reports
