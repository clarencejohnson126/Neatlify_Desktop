# Neatlify Project Structure

Complete overview of all files and their purposes.

## Directory Layout

```
Neatlify Desktop/
├── README.md                           # Main documentation
├── SETUP_GUIDE.md                      # Detailed setup instructions
├── QUICKSTART.md                       # 10-minute quick start
├── PROJECT_STRUCTURE.md                # This file
│
└── Neatlify/                           # Xcode project directory
    ├── Neatlify.xcodeproj              # (Create this in Xcode)
    │
    ├── Neatlify/                       # Main app source
    │   ├── NeatlifyApp.swift           # ⭐ App entry point
    │   ├── Info.plist                  # ⭐ Permissions & config
    │   ├── Neatlify.entitlements       # ⭐ App sandbox settings
    │   │
    │   ├── Models/                     # Data structures
    │   │   ├── ChatMessage.swift       # Chat message model
    │   │   ├── FileItem.swift          # File metadata model
    │   │   ├── OrganizationPlan.swift  # AI organization plan
    │   │   └── UserSession.swift       # User state & subscription
    │   │
    │   ├── Views/                      # SwiftUI views
    │   │   ├── ContentView.swift       # Main app container
    │   │   ├── ChatView.swift          # Chat interface
    │   │   ├── ProgressView.swift      # Organization progress
    │   │   ├── OnboardingView.swift    # First-run tutorial
    │   │   ├── PaywallView.swift       # Subscription screen
    │   │   └── SettingsView.swift      # App preferences
    │   │
    │   ├── ViewModels/                 # Business logic
    │   │   ├── ChatViewModel.swift     # Chat state management
    │   │   └── OrganizationViewModel.swift # Organization orchestration
    │   │
    │   ├── Services/                   # Core services
    │   │   ├── ClaudeAPIService.swift  # ⭐ Claude API client
    │   │   ├── FileService.swift       # File operations
    │   │   ├── PermissionsService.swift # Folder access
    │   │   └── PaymentService.swift    # Stripe integration
    │   │
    │   ├── Utilities/                  # Helper classes
    │   │   ├── APIKeyManager.swift     # ⭐ API key storage
    │   │   ├── ImageProcessor.swift    # Image encoding
    │   │   ├── PDFProcessor.swift      # PDF text extraction
    │   │   └── Logger.swift            # Debug logging
    │   │
    │   └── Resources/                  # (Optional)
    │       └── Assets.xcassets         # App icon, colors
    │
    └── NeatlifyTests/                  # (Optional) Unit tests
```

⭐ = Critical files to configure first

## File Descriptions

### Core App Files

#### `NeatlifyApp.swift`
- SwiftUI app entry point
- Creates window with ContentView
- Initializes UserSession
- Sets up Settings window

**Key Features:**
- Window configuration (800x600 minimum)
- Environment object injection
- Settings integration

#### `Info.plist`
- App configuration and permissions
- Privacy usage descriptions for folder access
- Network security settings
- Minimum macOS version (15.0)

**Required Keys:**
- NSDesktopFolderUsageDescription
- NSDocumentsFolderUsageDescription
- NSDownloadsFolderUsageDescription

#### `Neatlify.entitlements`
- App sandbox configuration
- Network client capability
- File access permissions
- Security-scoped bookmarks

---

### Models (Data Structures)

#### `ChatMessage.swift`
- Represents a single chat message
- Includes: role (user/assistant), content, timestamp
- Used for chat history

#### `FileItem.swift`
- Represents a scanned file
- Includes: URL, name, type, size, dates
- Supports: images, PDFs, documents

**FileType enum:**
- `.image` (JPG, PNG, HEIC, etc.)
- `.pdf`
- `.document`
- `.video`
- `.audio`
- `.other`

#### `OrganizationPlan.swift`
- AI-generated organization plan
- Includes: categories, file assignments, folder structure
- Used for preview before execution

**Related:**
- `OrganizationIntent` - Parsed user request

#### `UserSession.swift`
- User state and preferences
- Subscription management
- Trial tracking (3 free cleanups)
- Persists to UserDefaults

**Key Properties:**
- `freeTrialCleanupsRemaining`
- `hasActiveSubscription`
- `subscriptionType` (.monthly or .lifetime)
- `totalCleanupsPerformed`

---

### Views (UI Components)

#### `ContentView.swift`
- Main app container
- Manages chat + organization views
- Shows onboarding and paywall modals
- Handles organization notifications

#### `ChatView.swift`
- Chat interface with message list
- Text input field
- Send button
- Auto-scroll to latest message

**Subviews:**
- `MessageBubbleView` - Individual message bubbles

#### `ProgressView.swift`
- Shows organization progress
- Progress bar with percentage
- Status messages
- Cancel button

**Displays:**
- Current step (scanning, analyzing, moving)
- Files processed count
- Completion status

#### `OnboardingView.swift`
- First-run tutorial
- 4-page walkthrough
- Explains features and benefits

**Pages:**
1. Welcome
2. Smart Categorization
3. Safe & Local
4. Try It Free

#### `PaywallView.swift`
- Subscription selection screen
- Shows pricing options
- Opens Stripe checkout
- Displays remaining free cleanups

**Pricing Options:**
- Monthly: $19.99/month (3 cleanups)
- Lifetime: $99 one-time (unlimited)

#### `SettingsView.swift`
- App preferences
- Subscription status
- Usage statistics
- About information

**Tabs:**
- General (organization preferences)
- Subscription (status and management)
- About (version, links)

---

### ViewModels (Business Logic)

#### `ChatViewModel.swift`
- Manages chat state and messages
- Sends messages to Claude API
- Detects organization requests
- Handles errors

**Key Methods:**
- `sendMessage()` - Send user message
- `addSystemMessage()` - Add assistant response
- `isOrganizationRequest()` - Detect organize commands

#### `OrganizationViewModel.swift`
- Orchestrates entire organization workflow
- Manages progress and state
- Coordinates API calls and file operations

**Workflow Steps:**
1. Parse intent (extract criteria)
2. Request folder access
3. Scan files
4. Analyze with Claude AI
5. Create organization plan
6. Show preview
7. Execute file moves
8. Complete

**Key Properties:**
- `currentStep` - Current workflow step
- `progress` - 0.0 to 1.0
- `organizationPlan` - AI-generated plan
- `scannedFiles` - Files to organize

---

### Services (Core Functionality)

#### `ClaudeAPIService.swift` ⭐
- Claude API client
- Handles chat and vision requests
- Batches file analysis

**Key Methods:**
- `sendMessage()` - Chat with Claude
- `parseIntent()` - Extract organization criteria
- `analyzeImages()` - Batch image analysis (20 at a time)
- `analyzeText()` - Batch PDF analysis (10 at a time)

**API Configuration:**
- Model: `claude-3-5-sonnet-20241022`
- Max tokens: 4096
- Base URL: `https://api.anthropic.com/v1/messages`

#### `FileService.swift`
- File system operations
- Scanning, moving, organizing
- Undo tracking

**Key Methods:**
- `scanFolder()` - Recursively scan files
- `filterFiles()` - Filter by type
- `createFolders()` - Create category folders
- `moveFile()` - Move file safely
- `organizeFiles()` - Execute organization plan
- `undoOperations()` - Reverse file moves

**Safety Features:**
- Unique filename generation
- Operation history
- 7-day undo window

#### `PermissionsService.swift`
- macOS folder access permissions
- Security-scoped bookmarks
- Persistent access

**Key Methods:**
- `requestFolderAccess()` - Show folder picker
- `requestCommonFolderAccess()` - Access Downloads/Desktop/Documents
- `restoreAccess()` - Restore from bookmark
- `hasAccess()` - Check permissions

#### `PaymentService.swift`
- Stripe payment integration
- Subscription management
- Trial tracking

**Key Methods:**
- `purchaseMonthlySubscription()` - Open Stripe checkout
- `purchaseLifetimeSubscription()` - Open Stripe checkout
- `activateSubscription()` - Activate after payment
- `checkSubscriptionStatus()` - Verify active subscription

**Configuration Required:**
- Monthly Stripe link
- Lifetime Stripe link

---

### Utilities (Helpers)

#### `APIKeyManager.swift` ⭐
- Secure API key storage
- Usage tracking
- Rate limiting

**Key Methods:**
- `getAPIKey()` - Retrieve Claude API key
- `logUsage()` - Track API calls
- `getTotalTokensThisMonth()` - Monthly usage

**Configuration:**
- Set `obfuscatedKey` or use environment variable

#### `ImageProcessor.swift`
- Image encoding for Claude Vision
- Base64 conversion
- Size optimization

**Key Methods:**
- `encodeImage()` - Convert image to base64
- `encodeImages()` - Batch encode (async)
- `resize()` - Reduce size (max 1024px width)

**Optimization:**
- JPEG compression (80% quality)
- Resize to 1024px max width
- Parallel processing

#### `PDFProcessor.swift`
- PDF text extraction
- Page rendering
- Type detection

**Key Methods:**
- `extractText()` - Extract text (max 10 pages)
- `renderAsImage()` - Convert page to image
- `isTextBased()` - Detect text-based PDFs

**Uses:**
- PDFKit for text extraction
- Faster than vision for text PDFs

#### `Logger.swift`
- Debug logging
- OS log integration
- Error tracking

**Methods:**
- `debug()` - Development logging
- `info()` - General information
- `warning()` - Non-critical issues
- `error()` - Critical errors

---

## Critical Configuration

### Before Building

1. **Set API Key** (`APIKeyManager.swift`)
   - Method 1: Environment variable
     ```bash
     export ANTHROPIC_API_KEY="your-key"
     ```
   - Method 2: Hard-code in `obfuscatedKey`

2. **Configure Permissions** (`Info.plist`)
   - Add folder usage descriptions
   - Set minimum macOS version

3. **Set Bundle ID** (Xcode)
   - `com.neatlify.desktop`

4. **Enable Entitlements** (Xcode)
   - App Sandbox
   - Network client
   - User selected files

### Optional Configuration

1. **Stripe Payment** (`PaymentService.swift`)
   - Set monthly checkout URL
   - Set lifetime checkout URL

2. **App Icon** (`Assets.xcassets`)
   - Add 1024x1024 icon

3. **Customize Branding**
   - Update colors in views
   - Change welcome messages

## Data Flow

```
User Input (Chat)
    ↓
ChatViewModel
    ↓
OrganizationViewModel
    ↓
┌─────────────────────────┐
│ 1. Parse Intent         │ → ClaudeAPIService
│ 2. Request Access       │ → PermissionsService
│ 3. Scan Files           │ → FileService
│ 4. Analyze Files        │ → ClaudeAPIService + ImageProcessor/PDFProcessor
│ 5. Create Plan          │ → OrganizationPlan
│ 6. Execute Moves        │ → FileService
│ 7. Complete             │ → UserSession
└─────────────────────────┘
    ↓
Update UI (Views)
```

## Key Workflows

### Organization Workflow

1. User types: "Organize my Downloads by construction trade"
2. ChatViewModel detects organization request
3. Sends notification to OrganizationViewModel
4. OrganizationViewModel:
   - Calls ClaudeAPIService.parseIntent()
   - Calls PermissionsService.requestFolderAccess()
   - Calls FileService.scanFolder()
   - Batches files (images: 20, PDFs: 10)
   - Calls ClaudeAPIService.analyzeImages/Text()
   - Creates OrganizationPlan
   - Shows preview
   - On confirm: executes file moves
5. Updates UserSession (records cleanup)
6. Shows completion message

### Subscription Workflow

1. User completes 3 free cleanups
2. Next organization attempt → shows PaywallView
3. User selects plan (monthly/lifetime)
4. Opens Stripe checkout in browser
5. After payment → webhook activates subscription
6. UserSession updated
7. User can continue organizing

## Dependencies

### System Frameworks
- SwiftUI (UI)
- Foundation (Core)
- AppKit (macOS APIs)
- PDFKit (PDF processing)

### External APIs
- Anthropic Claude API (AI analysis)
- Stripe (payments)

### No Package Dependencies
- All code is self-contained
- No CocoaPods or SPM packages needed

## Build Requirements

- Xcode 16.0+
- Swift 6.0+
- macOS SDK 15.0+
- Developer account (for signing)

## Next Steps

1. Create Xcode project
2. Add all source files
3. Configure Info.plist and entitlements
4. Set Claude API key
5. Build and run
6. Test organization flow
7. Configure Stripe (optional)
8. Customize branding
9. Test thoroughly
10. Prepare for distribution

---

**Total Files:** 25 Swift files + 3 config files
**Lines of Code:** ~2,500 LOC
**Estimated Implementation:** Complete MVP in provided files
