# ✅ Ready to Build Neatlify

Your API key has been configured! Follow these steps to get Neatlify running.

## Step-by-Step Guide

### 1. Create Xcode Project (5 minutes)

1. **Open Xcode**
2. **File > New > Project**
3. **Select:**
   - Platform: **macOS**
   - Template: **App**
4. **Configure:**
   ```
   Product Name: Neatlify
   Organization Identifier: com.neatlify
   Interface: SwiftUI ← IMPORTANT!
   Language: Swift
   ```
5. **Save Location:**
   - Navigate to: `/Users/clarence/Desktop/Neatlify Desktop/`
   - Make sure you're INSIDE the "Neatlify Desktop" folder
   - Click **Create**

6. **Delete Default Files:**
   - In Xcode's left sidebar, delete:
     - `ContentView.swift`
     - `NeatlifyApp.swift`
   - Right-click > Delete > Move to Trash

---

### 2. Add Source Files (5 minutes)

**Two Windows Side-by-Side:**

**Finder (Right):**
- Open: `/Users/clarence/Desktop/Neatlify Desktop/Neatlify/Neatlify/`
- You should see: Models, Views, ViewModels, Services, Utilities folders

**Xcode (Left):**
- Project Navigator showing your project

**Drag Each Item:**

1. **Drag `NeatlifyApp.swift`** from Finder to "Neatlify" folder in Xcode
   - ✅ Check "Copy items if needed"
   - Click Finish

2. **Drag `Models` folder** from Finder to "Neatlify" folder in Xcode
   - ✅ Check "Copy items if needed"
   - Click Finish

3. **Drag `Views` folder**
   - ✅ Check "Copy items if needed"

4. **Drag `ViewModels` folder**
   - ✅ Check "Copy items if needed"

5. **Drag `Services` folder**
   - ✅ Check "Copy items if needed"

6. **Drag `Utilities` folder**
   - ✅ Check "Copy items if needed"

7. **Drag `Info.plist`**
   - ✅ Check "Copy items if needed"

8. **Go up one level** in Finder to `/Users/clarence/Desktop/Neatlify Desktop/Neatlify/`
   - **Drag `Neatlify.entitlements`**
   - ✅ Check "Copy items if needed"

**Verify:** Your Xcode should now show all folders with Swift files inside them.

---

### 3. Configure Permissions (2 minutes)

1. **Click** the blue "Neatlify" icon at top of Project Navigator
2. **Under TARGETS**, select "Neatlify"
3. **Click** "Signing & Capabilities" tab
4. **Click** "+ Capability" button (top left)
5. **Add "App Sandbox"**
6. **Under App Sandbox:**
   - ✅ Check "Outgoing Connections (Client)"
7. **Under File Access:**
   - ✅ Set "User Selected File" to "Read/Write"

---

### 4. Set Deployment Target (1 minute)

1. **Still in Target settings**
2. **Click** "General" tab
3. **Find** "Minimum Deployments"
4. **Set macOS** to **15.0**

---

### 5. Build & Run (1 minute)

1. **Select** "My Mac" as run destination (top bar)
2. **Clean:** Product > Clean Build Folder (Shift+Cmd+K)
3. **Build:** Product > Build (Cmd+B)
   - Wait for build to complete
   - Check for any errors (should be none)
4. **Run:** Product > Run (Cmd+R)
   - App should launch!

---

## ✅ What Should Happen

When you run the app:

1. **Onboarding Screen** appears
   - Welcome to Neatlify
   - Click through 4 pages
   - Click "Get Started"

2. **Chat Interface** opens
   - Shows welcome message
   - Text input at bottom

3. **Test the Chat:**
   - Type: "Hello"
   - Press Enter
   - Should get response from Claude AI

4. **Test Organization:**
   - Create a test folder with 5-10 images
   - Type: "Organize my test folder by color"
   - Follow prompts:
     - Grant folder access
     - Select your test folder
     - Review preview
     - Click "Proceed"
   - Files should be organized!

---

## 🔑 API Key Status

✅ **Configured!** Your Claude API key is already set up in the code.

The app will use your API key automatically. No additional configuration needed.

---

## 🚨 Troubleshooting

### Build Error: "Cannot find type 'ChatMessage'"
**Fix:** Files not added to target
1. Select the file in Xcode
2. Right panel > Target Membership
3. ✅ Check "Neatlify"

### Build Error: "No such module 'AppKit'"
**Fix:** Wrong deployment target
1. Target > General
2. Set macOS to 15.0+

### Runtime Error: "Access Denied"
**Fix:** Grant permissions when prompted
- System will show dialog
- Click "OK" to allow folder access

### API Error: "Invalid API Key"
**Fix:** Key might have typo
- Check APIKeyManager.swift:13
- Verify key is correct

### App Won't Launch
**Fix:**
1. Clean: Shift+Cmd+K
2. Rebuild: Cmd+B
3. Try again: Cmd+R

---

## 📋 Quick Reference

| Action | Keyboard Shortcut |
|--------|-------------------|
| Build | Cmd+B |
| Run | Cmd+R |
| Clean | Shift+Cmd+K |
| Stop | Cmd+. |

---

## 🎯 Success Checklist

Before considering setup complete:

- [ ] Xcode project created
- [ ] All folders visible in Project Navigator
- [ ] No red files (all blue/white)
- [ ] App Sandbox enabled in Signing & Capabilities
- [ ] Deployment target set to macOS 15.0
- [ ] Project builds without errors (Cmd+B)
- [ ] App launches (Cmd+R)
- [ ] Onboarding appears
- [ ] Chat interface works
- [ ] Can type and receive responses
- [ ] Folder selection works
- [ ] File organization works

---

## 📞 Need Help?

If you get stuck:

1. **Check Xcode Console** (bottom panel) for error messages
2. **Read XCODE_SETUP_STEPS.md** for detailed instructions
3. **Check PROJECT_STRUCTURE.md** to verify file placement

Common issues are covered in the Troubleshooting section above.

---

## 🎉 You're All Set!

Your Claude API key is configured and ready to use. Just follow the steps above and you'll have Neatlify running in about 15 minutes!

**Start with Step 1** and work through each section carefully. The app is ready to build!
