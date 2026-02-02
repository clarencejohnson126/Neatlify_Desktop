---
name: privacy-audit
description: Verify privacy compliance and data handling practices
---

# Privacy Compliance Audit

Audit Neatlify's data handling against privacy claims and GDPR requirements.

## ⚠️ Critical Finding

**Landing page claims:** "Your files never leave your Mac"

**Reality:** Images ARE sent as base64 to Claude API

```swift
// ClaudeAPIService.swift - Image Analysis
// Images are encoded and sent to Anthropic's servers
let base64Image = imageData.base64EncodedString()
// This IS transmitted over the network
```

### Data Transmission Summary

| Data Type | Transmitted? | To Where | Details |
|-----------|-------------|----------|---------|
| Images | ✅ YES | Claude API | Full image as base64 |
| PDFs | ⚠️ PARTIAL | Claude API | First 500 chars of text only |
| Filenames | ✅ YES | Claude API | Used in prompts |
| File contents | Varies | Claude API | Depends on file type |
| User credentials | ✅ YES | Supabase | Auth tokens, email |

## Files to Audit

| File | Lines | What to Check |
|------|-------|---------------|
| `Services/ClaudeAPIService.swift` | 214-232 | Image transmission |
| `Services/ClaudeAPIService.swift` | 280-325 | Text transmission |
| `Utilities/ImageProcessor.swift` | all | Image encoding (no local-only processing) |
| `Utilities/PDFProcessor.swift` | all | Text extraction limits |
| `Services/SupabaseService.swift` | all | User data handling |
| `Models/UserSession.swift` | all | Keychain storage |

## Privacy Audit Checklist

### Data Collection
- [ ] What data is collected?
- [ ] Is collection necessary for functionality?
- [ ] Is user informed about collection?

### Data Transmission
- [ ] What data leaves the device?
- [ ] Is transmission encrypted (HTTPS)?
- [ ] Is transmission to trusted parties only?

### Data Storage
- [ ] What is stored locally?
- [ ] What is stored remotely?
- [ ] Are credentials stored securely (Keychain)?

### Data Retention
- [ ] How long is data retained by Claude API?
- [ ] How long is data retained by Supabase?
- [ ] Can users request deletion?

### User Rights (GDPR)
- [ ] Right to access: Can users see their data?
- [ ] Right to rectification: Can users correct data?
- [ ] Right to erasure: Can users delete data?
- [ ] Right to portability: Can users export data?

## Recommended Actions

### 1. Update Landing Page Copy

**Current (misleading):**
> "Your files never leave your Mac"

**Suggested (accurate):**
> "File contents are analyzed using Claude AI to determine organization. Images and text excerpts are sent securely to Anthropic's API for processing. No files are stored on external servers."

### 2. Add Privacy Disclosure in App

```swift
// Before first scan, show:
"""
To organize your files, Neatlify sends:
• Images: Resized versions for visual analysis
• Documents: Text excerpts (first 500 characters)
• Filenames: For context

Data is processed by Claude AI (Anthropic) and not stored.
"""
```

### 3. Implement Local-Only Mode (Optional)

For users who truly want "never leaves Mac":
- Use on-device ML (Core ML) for basic categorization
- Reduced accuracy but full privacy
- Premium feature?

## Anthropic API Data Policy

Check Anthropic's current data retention policy:
- API inputs are not used for training (as of 2024)
- Data is retained temporarily for abuse prevention
- No long-term storage of prompts/responses

## Code Search Commands

```bash
# Find all network calls
grep -rn "URLSession\|URLRequest\|fetch\|post" "Neatlify Desktop/Neatlify Desktop/Services/"

# Find all data encoding
grep -rn "base64\|encode\|Data(" "Neatlify Desktop/Neatlify Desktop/"

# Find keychain usage
grep -rn "Keychain\|SecItem" "Neatlify Desktop/Neatlify Desktop/"

# Find analytics/tracking
grep -rn "analytics\|tracking\|telemetry" "Neatlify Desktop/Neatlify Desktop/"
```

## GDPR Compliance Status

| Requirement | Status | Notes |
|-------------|--------|-------|
| Lawful basis | ⚠️ | Need consent for API transmission |
| Data minimization | ✅ | Only sends what's needed |
| Purpose limitation | ✅ | Only for file organization |
| Storage limitation | ✅ | No persistent storage of file data |
| Security | ✅ | HTTPS, Keychain for credentials |
| Rights handling | ❌ | No data export/deletion features |
