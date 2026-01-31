# Neatlify Quick Start Guide

Get Neatlify running in 10 minutes!

## Prerequisites

- macOS Sequoia 15.0+
- Xcode 16.0+
- Anthropic API key from https://console.anthropic.com/

## 5-Step Setup

### 1. Create Xcode Project
```
Open Xcode > New Project > macOS App
Name: Neatlify
Bundle ID: com.neatlify.desktop
Interface: SwiftUI
Save to: /Users/clarence/Desktop/Neatlify Desktop/
```

### 2. Add All Source Files
```
Drag these folders into Xcode:
- Models/
- Views/
- ViewModels/
- Services/
- Utilities/

Check ✅ "Copy items if needed"
```

### 3. Configure Permissions
```
Target > Info > Add Keys:
- NSDesktopFolderUsageDescription
- NSDocumentsFolderUsageDescription
- NSDownloadsFolderUsageDescription

Target > Signing & Capabilities:
+ App Sandbox
  ✅ Outgoing Connections
  ✅ User Selected File (Read/Write)
```

### 4. Add API Key
```bash
export ANTHROPIC_API_KEY="sk-ant-api03-YOUR-KEY-HERE"
cd "/Users/clarence/Desktop/Neatlify Desktop"
open Neatlify.xcodeproj
```

### 5. Build & Run
```
Press Cmd+R
Grant permissions when prompted
Start organizing!
```

## Test It

1. **Create test folder:**
   ```bash
   mkdir ~/Desktop/TestFiles
   # Add 5-10 images
   ```

2. **In Neatlify, type:**
   ```
   "Organize my Desktop/TestFiles by color"
   ```

3. **Follow prompts:**
   - Select folder
   - Review plan
   - Click "Proceed"

4. **Verify:**
   - Check organized files in `TestFiles/Organized_[timestamp]/`

## Common Issues

**API Error?**
- Verify API key is correct
- Check key has credits at console.anthropic.com

**Permission Denied?**
- Grant access when system prompts
- Check System Settings > Privacy > Files and Folders

**Build Errors?**
- Clean: Product > Clean Build Folder (Shift+Cmd+K)
- Rebuild: Product > Build (Cmd+B)

## What's Included

```
Neatlify/
├── Models           # Data structures
├── Views            # SwiftUI interface
├── ViewModels       # Business logic
├── Services         # API & file operations
└── Utilities        # Helper functions
```

## Features

- ✅ Natural language file organization
- ✅ Claude AI vision analysis
- ✅ Image + PDF support
- ✅ Preview before moving
- ✅ 7-day undo
- ✅ Progress tracking
- ✅ Free trial (3 cleanups)

## Pricing (Optional)

To enable payments, update `PaymentService.swift` with your Stripe links:
- Monthly: $19.99/month
- Lifetime: $99 one-time

## Next Steps

- Customize app icon (Assets.xcassets)
- Add app description
- Set up Stripe for payments
- Test with real data
- Prepare for distribution

## Resources

- Full Setup: `SETUP_GUIDE.md`
- Documentation: `README.md`
- Support: support@neatlify.com

---

Built with SwiftUI + Claude AI 🚀
