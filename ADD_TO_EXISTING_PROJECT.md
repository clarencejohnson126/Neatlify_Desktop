# Adding Source Files to Your Existing "Neatlify Desktop" Project

You already have an Xcode project open. Now we just need to add the source code files to it.

## Step 1: Clean Up Existing Project

First, let's remove the default files you don't need:

In Xcode Project Navigator (left sidebar), **delete these files**:
1. Find `ContentView.swift`
   - Right-click > Delete > **Move to Trash**
2. Find `Neatlify_DesktopApp.swift` (or similar)
   - Right-click > Delete > **Move to Trash**

Keep:
- Assets (or Assets.xcassets)
- Any other existing files are fine

---

## Step 2: Open Finder to the CORRECT Source Folder

**CRITICAL:** You need to navigate to the correct nested folder!

### Option A: Using Finder

1. Open **Finder** (new window)
2. Click **Go** menu > **Go to Folder...** (or press Cmd+Shift+G)
3. **Type EXACTLY:**
   ```
   /Users/clarence/Desktop/Neatlify Desktop/Neatlify/Neatlify/
   ```
4. Press **Enter**

You should now see these folders:
- Models
- Views
- ViewModels
- Services
- Utilities
- NeatlifyApp.swift (file)
- Info.plist (file)

### Option B: Navigate Manually

1. Open **Finder**
2. Go to **Desktop**
3. Open **"Neatlify Desktop"** folder
4. Open **"Neatlify"** folder (first one)
5. Open **"Neatlify"** folder (second one - nested inside!)

You should see Models, Views, etc.

**If you see a `.xcodeproj` file, you're in the WRONG folder! Go one level deeper!**

---

## Step 3: Arrange Your Windows

- **Xcode window** on the LEFT side of screen
- **Finder window** on the RIGHT side of screen
- Both windows visible at the same time

---

## Step 4: Add Files ONE BY ONE

Now drag each item from Finder to Xcode:

### A. Add NeatlifyApp.swift

In Finder:
- Click on `NeatlifyApp.swift` (single file)
- **Drag** it to Xcode Project Navigator
- **Drop** it on "Neatlify Desktop" folder (or main project folder)

**Dialog appears:**
- ✅ **Check "Copy items if needed"**
- ✅ "Create groups" should be selected
- ✅ Target should be checked (Neatlify Desktop or similar)
- Click **Finish**

### B. Add Models Folder

In Finder:
- Click on **Models** folder
- **Drag** to Xcode
- **Drop** on "Neatlify Desktop" folder

**Dialog:**
- ✅ **Check "Copy items if needed"**
- Click **Finish**

### C. Add Views Folder

- Drag **Views** folder
- ✅ Check "Copy items if needed"
- Click **Finish**

### D. Add ViewModels Folder

- Drag **ViewModels** folder
- ✅ Check "Copy items if needed"
- Click **Finish**

### E. Add Services Folder

- Drag **Services** folder
- ✅ Check "Copy items if needed"
- Click **Finish**

### F. Add Utilities Folder

- Drag **Utilities** folder
- ✅ Check "Copy items if needed"
- Click **Finish**

### G. Add Info.plist

- Drag **Info.plist** file
- ✅ Check "Copy items if needed"
- Click **Finish**

---

## Step 5: Add Neatlify.entitlements

This file is in the PARENT folder!

1. In Finder, click the **back arrow** to go up one level
   - You should now be in: `Neatlify Desktop/Neatlify/`
2. Find `Neatlify.entitlements` file
3. **Drag** it to Xcode Project Navigator
4. ✅ Check "Copy items if needed"
5. Click **Finish**

---

## Step 6: Verify Structure

Your Xcode Project Navigator should now show:

```
Neatlify Desktop (or main project name)
├─ NeatlifyApp.swift
├─ Models
│  ├─ ChatMessage.swift
│  ├─ FileItem.swift
│  ├─ OrganizationPlan.swift
│  └─ UserSession.swift
├─ Views
│  ├─ ContentView.swift
│  ├─ ChatView.swift
│  ├─ ProgressView.swift
│  ├─ OnboardingView.swift
│  ├─ PaywallView.swift
│  └─ SettingsView.swift
├─ ViewModels
│  ├─ ChatViewModel.swift
│  └─ OrganizationViewModel.swift
├─ Services
│  ├─ ClaudeAPIService.swift
│  ├─ FileService.swift
│  ├─ PermissionsService.swift
│  └─ PaymentService.swift
├─ Utilities
│  ├─ APIKeyManager.swift
│  ├─ ImageProcessor.swift
│  ├─ PDFProcessor.swift
│  └─ Logger.swift
├─ Info.plist
├─ Neatlify.entitlements
└─ Assets (already there)
```

**Check:** All files should be WHITE/GRAY, not RED!

---

## Step 7: Configure Project Settings

### A. Add App Sandbox

1. Click the **blue project icon** at the very top of Project Navigator
2. Select your **target** (under TARGETS)
3. Click **"Signing & Capabilities"** tab
4. Click **"+ Capability"** button (top left)
5. Search for **"App Sandbox"**
6. Double-click to add it

### B. Configure Sandbox

Under "App Sandbox" section:
- ✅ Check **"Outgoing Connections (Client)"**

Under "File Access":
- Set **"User Selected File"** to **"Read/Write"**

### C. Set Deployment Target

1. Click **"General"** tab
2. Find **"Minimum Deployments"**
3. Set **macOS** to **15.0**

---

## Step 8: Build & Run!

1. Select **"My Mac"** as run destination (top bar)
2. Press **Cmd+B** to build
   - Wait for compilation
   - Should complete without errors
3. Press **Cmd+R** to run
   - App should launch!
   - Onboarding screen appears

---

## ✅ Success Checklist

- [ ] Deleted default ContentView.swift and App.swift
- [ ] Added NeatlifyApp.swift
- [ ] Added all 5 folders (Models, Views, ViewModels, Services, Utilities)
- [ ] Added Info.plist
- [ ] Added Neatlify.entitlements
- [ ] No red files in Project Navigator
- [ ] App Sandbox capability added
- [ ] Outgoing Connections checked
- [ ] User Selected File set to Read/Write
- [ ] Deployment target is macOS 15.0
- [ ] Project builds (Cmd+B)
- [ ] App runs (Cmd+R)

---

## 🚨 Troubleshooting

### "That workspace dialog appears again!"
**You're dragging from the wrong folder!**
- Make sure you're in: `.../Neatlify/Neatlify/` (nested folder)
- You should see Models, Views folders - NOT .xcodeproj

### "Copy items if needed" is grayed out
- That's OK! Files are in the right place. Just click Finish.

### Files appear RED
- Wrong location. Delete and re-add with "Copy items if needed" checked.

### Build error: "Cannot find 'ChatMessage'"
- File not added to target
- Select file > File Inspector (right panel) > Target Membership > ✅ Check your target

### Build error: "No such module 'AppKit'"
- Deployment target too low
- Set to macOS 15.0 in General tab

---

## 🎯 The Key Point

**DON'T drag the whole "Neatlify" folder!**
**DO drag the individual folders inside it (Models, Views, etc.)**

You should drag from:
```
/Users/clarence/Desktop/Neatlify Desktop/Neatlify/Neatlify/
                                                    ↑
                                    (This nested folder!)
```

**Shortcut:** Use "Go to Folder" (Cmd+Shift+G) and paste that path!

---

Ready to try? Start with Step 1!
