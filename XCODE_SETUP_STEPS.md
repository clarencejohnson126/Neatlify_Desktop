# Xcode Setup - Step by Step

Follow these exact steps to add source files to your Xcode project.

## Part 1: Create the Xcode Project

1. **Open Xcode**
   - Launch Xcode from Applications folder
   - If you see a welcome screen, click "Create New Project"
   - If Xcode is already open, go to: File > New > Project

2. **Choose Template**
   - Platform: **macOS** (top tabs)
   - Application section: Click **App**
   - Click **Next**

3. **Configure Project**
   Fill in these fields:
   ```
   Product Name: Neatlify
   Team: (Select your Apple ID or "None")
   Organization Identifier: com.neatlify
   Bundle Identifier: com.neatlify.desktop (auto-filled)
   Interface: SwiftUI (IMPORTANT!)
   Language: Swift
   Storage: None
   Include Tests: (uncheck)
   ```
   - Click **Next**

4. **Choose Location**
   - Navigate to: `/Users/clarence/Desktop/Neatlify Desktop/`
   - Make sure you're INSIDE the "Neatlify Desktop" folder
   - Click **Create**

5. **Delete Default Files**
   - In Xcode's left sidebar (Project Navigator)
   - Find and DELETE these files:
     - `ContentView.swift` (we have our own)
     - `NeatlifyApp.swift` (we have our own)
   - Right-click > Delete > "Move to Trash"

## Part 2: Add Source Files to Xcode

**IMPORTANT**: These steps add your Swift files to the Xcode project.

### Method 1: Drag and Drop (Recommended)

1. **Open Finder**
   - Open a new Finder window (Cmd+N)
   - Navigate to: `/Users/clarence/Desktop/Neatlify Desktop/Neatlify/Neatlify/`

2. **Arrange Windows**
   - Place Finder window on the RIGHT side of screen
   - Place Xcode window on the LEFT side of screen
   - You should see both at the same time

3. **In Finder, you should see these folders:**
   ```
   Models/
   Views/
   ViewModels/
   Services/
   Utilities/
   NeatlifyApp.swift
   Info.plist
   ```

4. **Drag Files to Xcode**

   **Step A: Add NeatlifyApp.swift**
   - In Finder: Click on `NeatlifyApp.swift`
   - Drag it to Xcode's Project Navigator
   - Drop it on the "Neatlify" folder (the blue folder icon)
   - A dialog will appear:
     - ✅ Check "Copy items if needed"
     - ✅ Check "Create groups" (should be selected)
     - ✅ Make sure "Neatlify" target is checked
   - Click **Finish**

   **Step B: Add Models folder**
   - In Finder: Click on the `Models` folder
   - Drag it to Xcode's Project Navigator
   - Drop it on the "Neatlify" folder (same place)
   - Dialog appears:
     - ✅ Check "Copy items if needed"
     - ✅ Check "Create groups"
     - ✅ Make sure "Neatlify" target is checked
   - Click **Finish**

   **Step C: Add Views folder**
   - Repeat same process for `Views/` folder
   - Make sure to check "Copy items if needed"

   **Step D: Add ViewModels folder**
   - Repeat for `ViewModels/` folder

   **Step E: Add Services folder**
   - Repeat for `Services/` folder

   **Step F: Add Utilities folder**
   - Repeat for `Utilities/` folder

   **Step G: Add Info.plist**
   - Drag `Info.plist` to the "Neatlify" folder in Xcode
   - Check "Copy items if needed"

   **Step H: Add Neatlify.entitlements**
   - Go up one level in Finder to: `/Users/clarence/Desktop/Neatlify Desktop/Neatlify/`
   - Drag `Neatlify.entitlements` to the "Neatlify" folder in Xcode
   - Check "Copy items if needed"

5. **Verify Structure**

   Your Xcode Project Navigator should now look like this:
   ```
   Neatlify (blue icon)
   ├── NeatlifyApp.swift
   ├── Models (folder)
   │   ├── ChatMessage.swift
   │   ├── FileItem.swift
   │   ├── OrganizationPlan.swift
   │   └── UserSession.swift
   ├── Views (folder)
   │   ├── ContentView.swift
   │   ├── ChatView.swift
   │   ├── ProgressView.swift
   │   ├── OnboardingView.swift
   │   ├── PaywallView.swift
   │   └── SettingsView.swift
   ├── ViewModels (folder)
   │   ├── ChatViewModel.swift
   │   └── OrganizationViewModel.swift
   ├── Services (folder)
   │   ├── ClaudeAPIService.swift
   │   ├── FileService.swift
   │   ├── PermissionsService.swift
   │   └── PaymentService.swift
   ├── Utilities (folder)
   │   ├── APIKeyManager.swift
   │   ├── ImageProcessor.swift
   │   ├── PDFProcessor.swift
   │   └── Logger.swift
   ├── Info.plist
   └── Assets.xcassets (already there)
   ```

### Method 2: Right-Click Menu (Alternative)

If drag-and-drop isn't working:

1. In Xcode Project Navigator
2. Right-click on "Neatlify" folder (blue icon)
3. Select "Add Files to Neatlify..."
4. Navigate to: `/Users/clarence/Desktop/Neatlify Desktop/Neatlify/Neatlify/`
5. Select ALL folders and files:
   - Hold Cmd and click: Models, Views, ViewModels, Services, Utilities, NeatlifyApp.swift, Info.plist
6. Make sure these are checked:
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ "Neatlify" target
7. Click **Add**

## Part 3: Configure Entitlements

1. **Select Project**
   - Click the blue "Neatlify" icon at the very top of Project Navigator

2. **Select Target**
   - In the main area, under "TARGETS", click "Neatlify"

3. **Go to Signing & Capabilities**
   - Click the "Signing & Capabilities" tab at the top

4. **Add App Sandbox**
   - Click the **+ Capability** button (top left)
   - Search for "App Sandbox"
   - Double-click to add it

5. **Configure Sandbox**
   Under "App Sandbox" section that appears:
   - ✅ Check "Outgoing Connections (Client)" under Network

6. **Configure File Access**
   Still under "App Sandbox":
   - Expand "File Access" section
   - ✅ Check "User Selected File" to "Read/Write"

## Part 4: Set Deployment Target

1. **Still in Target > General tab**
2. Find "Minimum Deployments"
3. Set **macOS** to **15.0**

## Part 5: Configure API Key

Your API key is ready to be configured. I'll create a setup script for you.

## Common Issues & Solutions

### Issue: "Copy items if needed" is grayed out
**Solution**: The files are already in the right location. Just click Add.

### Issue: Files appear red in Xcode
**Solution**:
1. Select the red file
2. In right sidebar (File Inspector), find "Location"
3. Click the folder icon and locate the file

### Issue: Build fails with "No such module"
**Solution**:
1. Product > Clean Build Folder (Shift+Cmd+K)
2. Product > Build (Cmd+B)

### Issue: "Neatlify.entitlements not found"
**Solution**:
1. Make sure you dragged the .entitlements file from the correct location
2. It should be at: `/Users/clarence/Desktop/Neatlify Desktop/Neatlify/Neatlify.entitlements`

## Next Steps

After completing these steps:
1. Configure your API key (see CONFIGURE_API_KEY.md)
2. Build the project (Cmd+B)
3. Run the app (Cmd+R)

## Visual Checklist

- [ ] Xcode project created in correct location
- [ ] All folders added to Xcode (Models, Views, ViewModels, Services, Utilities)
- [ ] NeatlifyApp.swift added
- [ ] Info.plist added
- [ ] Neatlify.entitlements added
- [ ] App Sandbox capability enabled
- [ ] Deployment target set to macOS 15.0
- [ ] All files appear blue (not red) in Project Navigator
- [ ] Ready to configure API key

---

**Time Required**: 10-15 minutes
**Difficulty**: Beginner-friendly with step-by-step instructions
