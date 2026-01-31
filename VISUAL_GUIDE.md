# 👁️ Visual Setup Guide

## Adding Files to Xcode - Visual Walkthrough

### Step 1: Arrange Your Windows

```
┌─────────────────────────────────┬─────────────────────────────────┐
│                                 │                                 │
│         XCODE WINDOW            │       FINDER WINDOW             │
│         (Left Side)             │       (Right Side)              │
│                                 │                                 │
│  Project Navigator:             │  Location:                      │
│  ┌──────────────────┐           │  Neatlify/Neatlify/             │
│  │ Neatlify (blue)  │           │                                 │
│  │  └─ Assets.xca.. │           │  ┌────────────────────┐         │
│  │                  │           │  │ 📁 Models          │         │
│  │                  │           │  │ 📁 Views           │         │
│  │   ⬅ DROP HERE   │  ←───────────│ 📁 ViewModels      │         │
│  │                  │           │  │ 📁 Services        │         │
│  │                  │           │  │ 📁 Utilities       │         │
│  │                  │           │  │ 📄 NeatlifyApp.swi │         │
│  │                  │           │  │ 📄 Info.plist      │         │
│  └──────────────────┘           │  └────────────────────┘         │
│                                 │                                 │
└─────────────────────────────────┴─────────────────────────────────┘
```

### Step 2: Drag Models Folder

**GRAB** the Models folder from Finder:

```
Finder:
  📁 Models  ← Click and hold this
    ├─ ChatMessage.swift
    ├─ FileItem.swift
    ├─ OrganizationPlan.swift
    └─ UserSession.swift
```

**DRAG** it to Xcode and **DROP** on "Neatlify" folder:

```
Xcode Project Navigator:
  Neatlify (blue icon)  ← Drop the folder HERE
    └─ Assets.xcassets
```

### Step 3: Dialog Box Appears

When you drop the folder, you'll see this:

```
┌──────────────────────────────────────────────────────┐
│  Choose options for adding these files:              │
│                                                       │
│  Destination: ☑ Copy items if needed  ← CHECK THIS!  │
│                                                       │
│  Added folders: ⦿ Create groups                      │
│                 ○ Create folder references            │
│                                                       │
│  Add to targets: ☑ Neatlify          ← CHECK THIS!   │
│                                                       │
│              [Cancel]  [Finish]                       │
└──────────────────────────────────────────────────────┘
```

**IMPORTANT:** Always check ✅ "Copy items if needed"

### Step 4: Result

After clicking Finish, your Xcode should look like:

```
Xcode Project Navigator:
  Neatlify (blue icon)
  ├─ Models (📁)
  │  ├─ ChatMessage.swift
  │  ├─ FileItem.swift
  │  ├─ OrganizationPlan.swift
  │  └─ UserSession.swift
  └─ Assets.xcassets
```

### Step 5: Repeat for All Folders

Do the same for:

1. **Views folder**
   ```
   Views (📁)
   ├─ ContentView.swift
   ├─ ChatView.swift
   ├─ ProgressView.swift
   ├─ OnboardingView.swift
   ├─ PaywallView.swift
   └─ SettingsView.swift
   ```

2. **ViewModels folder**
   ```
   ViewModels (📁)
   ├─ ChatViewModel.swift
   └─ OrganizationViewModel.swift
   ```

3. **Services folder**
   ```
   Services (📁)
   ├─ ClaudeAPIService.swift
   ├─ FileService.swift
   ├─ PermissionsService.swift
   └─ PaymentService.swift
   ```

4. **Utilities folder**
   ```
   Utilities (📁)
   ├─ APIKeyManager.swift
   ├─ ImageProcessor.swift
   ├─ PDFProcessor.swift
   └─ Logger.swift
   ```

5. **NeatlifyApp.swift** (single file)

6. **Info.plist** (single file)

7. **Neatlify.entitlements** (from parent folder)

---

## Final Structure

When done, your Xcode Project Navigator should look exactly like this:

```
📦 Neatlify (blue project icon)
│
├─ 📦 Neatlify (blue folder icon)
│  │
│  ├─ 📄 NeatlifyApp.swift
│  │
│  ├─ 📁 Models
│  │  ├─ 📄 ChatMessage.swift
│  │  ├─ 📄 FileItem.swift
│  │  ├─ 📄 OrganizationPlan.swift
│  │  └─ 📄 UserSession.swift
│  │
│  ├─ 📁 Views
│  │  ├─ 📄 ContentView.swift
│  │  ├─ 📄 ChatView.swift
│  │  ├─ 📄 ProgressView.swift
│  │  ├─ 📄 OnboardingView.swift
│  │  ├─ 📄 PaywallView.swift
│  │  └─ 📄 SettingsView.swift
│  │
│  ├─ 📁 ViewModels
│  │  ├─ 📄 ChatViewModel.swift
│  │  └─ 📄 OrganizationViewModel.swift
│  │
│  ├─ 📁 Services
│  │  ├─ 📄 ClaudeAPIService.swift
│  │  ├─ 📄 FileService.swift
│  │  ├─ 📄 PermissionsService.swift
│  │  └─ 📄 PaymentService.swift
│  │
│  ├─ 📁 Utilities
│  │  ├─ 📄 APIKeyManager.swift
│  │  ├─ 📄 ImageProcessor.swift
│  │  ├─ 📄 PDFProcessor.swift
│  │  └─ 📄 Logger.swift
│  │
│  ├─ 📄 Info.plist
│  ├─ 🔒 Neatlify.entitlements
│  └─ 🎨 Assets.xcassets
│
└─ 📁 Products
   └─ 📦 Neatlify.app
```

---

## Color Coding in Xcode

Files appear in different colors:

- **White/Light Gray** = Normal, working file ✅
- **Blue** = Folder or group ✅
- **Red** = Missing file or error ❌
- **Yellow** = Warning, but will build ⚠️

If you see **RED files**, they're not in the right location!

---

## Configuration Settings Visual

### Signing & Capabilities Tab

Should look like this:

```
┌────────────────────────────────────────────────────┐
│  SIGNING & CAPABILITIES                            │
├────────────────────────────────────────────────────┤
│                                                    │
│  ⊕ Signing                                         │
│     Team: Your Apple ID                            │
│     Bundle Identifier: com.neatlify.desktop        │
│                                                    │
│  ⊕ App Sandbox                                     │
│     ☑ App Sandbox                                  │
│                                                    │
│     Network:                                       │
│       ☑ Outgoing Connections (Client) ← CHECK!     │
│       ☐ Incoming Connections (Server)              │
│                                                    │
│     File Access:                                   │
│       User Selected File: Read/Write ← SET THIS!   │
│       Downloads Folder: --                         │
│       Pictures Folder: --                          │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## Build Settings Visual

### General Tab

```
┌────────────────────────────────────────────────────┐
│  GENERAL                                           │
├────────────────────────────────────────────────────┤
│  Display Name: Neatlify                            │
│  Bundle Identifier: com.neatlify.desktop           │
│  Version: 1.0                                      │
│  Build: 1                                          │
│                                                    │
│  Minimum Deployments:                              │
│    macOS: 15.0  ← MUST BE 15.0 OR HIGHER!          │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## Build Process Visual

When you press **Cmd+R** (Run):

```
Step 1: Compiling
┌────────────────────────────────────┐
│ ⚙️  Compiling Swift files...        │
│    ✓ ChatMessage.swift             │
│    ✓ FileItem.swift                │
│    ✓ OrganizationPlan.swift        │
│    ... (all files)                 │
└────────────────────────────────────┘

Step 2: Linking
┌────────────────────────────────────┐
│ 🔗 Linking...                       │
│    ✓ Frameworks linked             │
│    ✓ Resources copied              │
└────────────────────────────────────┘

Step 3: Code Signing
┌────────────────────────────────────┐
│ 🔐 Signing Neatlify.app...          │
│    ✓ Code signed                   │
└────────────────────────────────────┘

Step 4: Launch
┌────────────────────────────────────┐
│ 🚀 Launching Neatlify...            │
│                                    │
│    ✓ App launched successfully!    │
└────────────────────────────────────┘
```

---

## First Run Visual

When app launches for the first time:

```
┌─────────────────────────────────────────┐
│                                         │
│             ✨ Sparkles Icon            │
│                                         │
│         Welcome to Neatlify             │
│                                         │
│    Organize your files with AI          │
│         in seconds                      │
│                                         │
│                                         │
│              [Next]                     │
│                                         │
└─────────────────────────────────────────┘
```

Click through 4 onboarding pages, then you'll see:

```
┌─────────────────────────────────────────┐
│  ✨ Neatlify                      ⚙️    │
├─────────────────────────────────────────┤
│                                         │
│  🤖 Welcome to Neatlify! I can help... │
│                                         │
│  Try saying:                            │
│  • "Organize my Downloads by..."       │
│  • "Sort my vacation photos..."        │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  Type a message...            [Send ⬆️]  │
└─────────────────────────────────────────┘
```

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Build | Cmd+B |
| Run | Cmd+R |
| Stop | Cmd+. |
| Clean | Shift+Cmd+K |
| Show/Hide Navigator | Cmd+0 |
| Show/Hide Inspector | Cmd+Option+0 |
| Show Console | Cmd+Shift+Y |

---

**Ready to start?** Open `READY_TO_BUILD.md` and follow the steps!
