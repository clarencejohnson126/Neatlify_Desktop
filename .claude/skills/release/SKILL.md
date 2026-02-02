---
name: release
description: Build, sign, notarize, and package Neatlify Desktop for release
arguments:
  - name: version
    description: "Version number (e.g., '1.2.0')"
    required: true
---

# Neatlify Desktop Release Workflow

Complete workflow for releasing a signed and notarized macOS app.

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
xcodebuild clean -project "Neatlify Desktop.xcodeproj" -scheme "Neatlify Desktop" -configuration Release

# Build archive
xcodebuild archive \
  -project "Neatlify Desktop.xcodeproj" \
  -scheme "Neatlify Desktop" \
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
  -scheme "Neatlify Desktop" \
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
