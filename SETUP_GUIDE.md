# Neatlify Setup Guide

Complete step-by-step instructions to get Neatlify running on your Mac.

## Prerequisites

Before you begin, ensure you have:

- ✅ macOS Sequoia 15.0 or later
- ✅ Xcode 16.0 or later installed
- ✅ Anthropic API account (get one at https://console.anthropic.com/)
- ✅ Basic familiarity with Xcode

## Step 1: Verify Xcode Installation

```bash
xcode-select --version
# Should output: xcode-select version 2406 or higher

xcodebuild -version
# Should output: Xcode 16.0 or higher
```

If Xcode is not installed:
1. Open App Store
2. Search for "Xcode"
3. Download and install (may take 30+ minutes)

## Step 2: Create Xcode Project

### Option A: Create New Project (Recommended)

1. **Open Xcode**
2. **Create a new Xcode project**
3. **Select Template:**
   - Platform: macOS
   - Application: App
   - Click "Next"

4. **Configure Project:**
   - Product Name: `Neatlify`
   - Team: (Select your Apple Developer account or Personal Team)
   - Organization Identifier: `com.neatlify`
   - Bundle Identifier: `com.neatlify.desktop` (auto-generated)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - Click "Next"

5. **Choose Location:**
   - Navigate to: `/Users/clarence/Desktop/Neatlify Desktop/`
   - Create folder if it doesn't exist
   - Click "Create"

6. **Delete Default Files:**
   - Delete `ContentView.swift` (we have our own)
   - Keep `NeatlifyApp.swift` but we'll replace it

### Option B: Import Existing Files

If you already have the source files:

1. Open Xcode
2. File > New > Project
3. Follow steps above
4. Drag all folders from Finder into Xcode project

## Step 3: Add Source Files

1. **In Xcode Project Navigator:**
   - Right-click on `Neatlify` folder (blue icon)
   - Select "Add Files to Neatlify..."

2. **Add Models Folder:**
   - Navigate to: `Neatlify/Neatlify/Models/`
   - Select the entire `Models` folder
   - Check ✅ "Copy items if needed"
   - Check ✅ "Create groups"
   - Target: Neatlify (checked)
   - Click "Add"

3. **Repeat for other folders:**
   - `Views/`
   - `ViewModels/`
   - `Services/`
   - `Utilities/`

4. **Verify Structure:**
   Your Project Navigator should look like:
   ```
   Neatlify
   ├── NeatlifyApp.swift
   ├── Models
   │   ├── ChatMessage.swift
   │   ├── FileItem.swift
   │   ├── OrganizationPlan.swift
   │   └── UserSession.swift
   ├── Views
   │   ├── ContentView.swift
   │   ├── ChatView.swift
   │   ├── ProgressView.swift
   │   ├── OnboardingView.swift
   │   ├── PaywallView.swift
   │   └── SettingsView.swift
   ├── ViewModels
   │   ├── ChatViewModel.swift
   │   └── OrganizationViewModel.swift
   ├── Services
   │   ├── ClaudeAPIService.swift
   │   ├── FileService.swift
   │   ├── PermissionsService.swift
   │   └── PaymentService.swift
   └── Utilities
       ├── APIKeyManager.swift
       ├── ImageProcessor.swift
       ├── PDFProcessor.swift
       └── Logger.swift
   ```

## Step 4: Configure Info.plist

1. **Select Project** (blue icon at top)
2. **Select Target:** Neatlify
3. **Go to:** Info tab
4. **Right-click** in the plist area
5. **Select:** "Open As > Source Code"
6. **Replace entire content** with provided `Info.plist` file

Or manually add these keys:

| Key | Type | Value |
|-----|------|-------|
| NSDesktopFolderUsageDescription | String | "Neatlify needs access to your Desktop folder to organize your files." |
| NSDocumentsFolderUsageDescription | String | "Neatlify needs access to your Documents folder to organize your files." |
| NSDownloadsFolderUsageDescription | String | "Neatlify needs access to your Downloads folder to organize your files." |
| LSMinimumSystemVersion | String | "15.0" |

## Step 5: Configure App Sandbox & Entitlements

1. **Select Project** > **Neatlify Target**
2. **Go to:** Signing & Capabilities tab
3. **Click:** + Capability (top left)

4. **Add App Sandbox:**
   - Search: "App Sandbox"
   - Double-click to add
   - Under "App Sandbox", check:
     - ✅ Outgoing Connections (Network)

5. **Configure File Access:**
   - Under "App Sandbox" > "File Access"
   - Check:
     - ✅ User Selected File (Read/Write)

6. **Or Copy Entitlements File:**
   - Drag `Neatlify.entitlements` into project
   - Xcode will automatically use it

## Step 6: Set Deployment Target

1. **Select Project** > **Neatlify Target**
2. **Go to:** General tab
3. **Set Minimum Deployments:**
   - macOS: **15.0**

## Step 7: Configure Claude API Key

### Method 1: Environment Variable (Recommended for Development)

```bash
# In Terminal
export ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"

# Launch Xcode from terminal
cd "/Users/clarence/Desktop/Neatlify Desktop"
open Neatlify.xcodeproj
```

### Method 2: Hard-code in APIKeyManager

1. Open `Utilities/APIKeyManager.swift`
2. Find line:
   ```swift
   private static let obfuscatedKey = "YOUR_ANTHROPIC_API_KEY_HERE"
   ```
3. Replace with your key:
   ```swift
   private static let obfuscatedKey = "sk-ant-api03-your-actual-key"
   ```

**⚠️ Warning:** Do not commit API keys to version control!

### Getting an API Key

1. Go to: https://console.anthropic.com/
2. Sign up or log in
3. Navigate to: Settings > API Keys
4. Click "Create Key"
5. Copy the key (starts with `sk-ant-api03-`)
6. Store it securely

## Step 8: Build the Project

1. **Select Run Destination:**
   - Top bar: "My Mac" or your Mac's name

2. **Clean Build Folder:**
   - Menu: Product > Clean Build Folder (Shift+Cmd+K)

3. **Build:**
   - Menu: Product > Build (Cmd+B)
   - Wait for build to complete

4. **Check for Errors:**
   - If errors appear, check:
     - All files are added to target
     - Deployment target is set correctly
     - Swift version is correct (should auto-detect)

## Step 9: Run the App

1. **Run:**
   - Press: Cmd+R
   - Or: Product > Run

2. **First Launch:**
   - App should open
   - Onboarding screen appears
   - Click through tutorial

3. **Grant Permissions:**
   - When organizing files, system will prompt
   - Click "OK" to grant folder access

## Step 10: Test Basic Functionality

### Test 1: Chat Interface
1. Type a message: "Hello"
2. Should receive response from Claude

### Test 2: File Organization
1. Create test folder with 5-10 images
2. In Neatlify, type: "Organize my test folder by color"
3. Select folder when prompted
4. Review preview
5. Click "Proceed"
6. Verify files are organized

## Common Build Errors

### Error: "Cannot find type 'ChatMessage'"
**Fix:** Ensure all Model files are added to target
- Select file > File Inspector > Target Membership > ✅ Neatlify

### Error: "No such module 'AppKit'"
**Fix:** This is a system framework, should auto-import
- Check deployment target is macOS 15.0+

### Error: "Command PhaseScriptExecution failed"
**Fix:** Clean build folder and rebuild
- Product > Clean Build Folder
- Product > Build

### Error: "Signing for Neatlify requires a development team"
**Fix:** Select your team in Signing & Capabilities
- Signing & Capabilities > Team > (Select your Apple ID)

### Error: "Build input file cannot be found"
**Fix:** File reference is broken
- Remove file from project
- Re-add using "Add Files to Neatlify..."

## Verification Checklist

Before considering setup complete:

- [ ] App launches without crash
- [ ] Onboarding flow works
- [ ] Chat interface accepts input
- [ ] Can select folder via file picker
- [ ] Claude API responds (test with simple message)
- [ ] File scanning works (shows file count)
- [ ] Organization preview appears
- [ ] Files can be moved successfully
- [ ] Settings panel opens
- [ ] No console errors (critical ones)

## Performance Optimization

For best performance:

1. **Enable Hardened Runtime:**
   - Signing & Capabilities > Hardened Runtime
   - Check all options

2. **Optimize Build Settings:**
   - Build Settings > Optimization Level > "Optimize for Speed"

3. **Disable Debug Logging (Production):**
   - Edit scheme > Run > Info > Build Configuration > "Release"

## Next Steps

- Test with various file types
- Configure Stripe for payments
- Customize app icon
- Prepare for distribution

## Troubleshooting

### App won't launch
- Check Console app for crash logs
- Verify deployment target matches your macOS version

### Permissions not working
- System Settings > Privacy & Security > Files and Folders
- Grant access manually if needed

### Claude API errors
- Verify API key is correct
- Check API key has credits
- Test API key with curl:
  ```bash
  curl https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":1024,"messages":[{"role":"user","content":"Hello"}]}'
  ```

## Support

If you encounter issues:
1. Check Xcode console for error messages
2. Review Logger output in Console app
3. Verify all prerequisites are met
4. Check file permissions

For additional help: support@neatlify.com

---

**Estimated Setup Time:** 30-45 minutes

**Difficulty:** Intermediate (requires Xcode knowledge)
