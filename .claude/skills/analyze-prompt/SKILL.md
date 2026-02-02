---
name: analyze-prompt
description: Debug and optimize Claude API prompts for better file analysis
arguments:
  - name: issue
    description: "Issue type: 'wrong-mode', 'language', 'json-error', 'category'"
    required: false
---

# Claude API Prompt Debugger

All prompts are in `Neatlify Desktop/Services/ClaudeAPIService.swift`

## Prompt Locations

| Prompt | Lines | Purpose |
|--------|-------|---------|
| Chat System Prompt | 21-45 | Main conversational context |
| Intent Parsing | 71-129 | Detect organize/chat/navigate intent |
| Image Analysis | 217-232 | Vision-based categorization |
| Text Analysis | 280-310 | Document content analysis |
| Label Generation | 357-378 | Create folder names |

## Prompt Templates

### Chat System Prompt (lines 21-45)

```swift
let systemPrompt = """
You are Neatlify, an AI assistant that helps users organize their files.
You can:
1. Organize files into categories based on content
2. Answer questions about file organization
3. Help navigate to specific folders

Current language: \(language)
User's folder: \(folderPath)

Respond naturally and helpfully.
"""
```

### Intent Parsing (lines 71-129)

```swift
let intentPrompt = """
Analyze the user's message and determine their intent:
- "organize": User wants to organize files
- "chat": User is asking a question or chatting
- "navigate": User wants to go to a folder

Message: "\(userMessage)"

Respond with JSON: {"intent": "organize|chat|navigate", "details": "..."}
"""
```

### Image Analysis (lines 217-232)

```swift
let imagePrompt = """
Analyze this image and suggest a category for organizing it.
Consider:
- Is it a photo, screenshot, graphic, or document scan?
- What is the main subject?
- What context might it belong to (work, personal, receipts, etc.)?

Respond with JSON: {"category": "suggested/folder/path", "confidence": 0.0-1.0}
"""
```

## Debug Workflows

### Wrong Mode Detection (`/analyze-prompt wrong-mode`)

**Symptom:** User says "organize my files" but gets chat response

**Debug steps:**
1. Log the intent parsing request/response:
```swift
print("Intent prompt: \(intentPrompt)")
print("Intent response: \(response)")
```

2. Check JSON parsing:
```swift
// Line ~100
guard let intent = json["intent"] as? String else {
    print("Failed to parse intent from: \(json)")
}
```

3. Common fixes:
- User message too ambiguous
- Language mismatch in prompt
- JSON malformed in response

### Language Issues (`/analyze-prompt language`)

**Symptom:** Responses in wrong language

**Check:**
```swift
// Supported languages in ClaudeAPIService
let supportedLanguages = ["en", "de", "es", "fr", "it", "pt", "nl"]

// Verify language is passed correctly
print("Using language: \(currentLanguage)")
```

**Fix:** Ensure language code is included in system prompt

### JSON Parsing Failures (`/analyze-prompt json-error`)

**Symptom:** `JSONSerialization` throws error

**Common causes:**
1. Response includes markdown code blocks
2. Response has trailing text after JSON
3. Special characters not escaped

**Debug:**
```swift
// Before parsing
print("Raw response: \(responseText)")

// Extract JSON from markdown
if responseText.contains("```json") {
    let jsonString = responseText
        .components(separatedBy: "```json")[1]
        .components(separatedBy: "```")[0]
}
```

### Wrong Category (`/analyze-prompt category`)

**Symptom:** Files put in wrong folders

**Debug steps:**
1. Check the image/text sent to API
2. Log the suggested category
3. Compare with expected

**Improve prompts:**
```swift
// Add more specific guidance
let improvedPrompt = """
Categorize this file. Use these exact categories when applicable:
- Photos/Vacation
- Photos/Family
- Documents/Receipts
- Documents/Work
- Screenshots
- Downloads

Only suggest custom categories if none of the above fit.
"""
```

## Prompt Testing

### Test Intent Parsing
```swift
let testMessages = [
    "organize my downloads folder",  // Expected: organize
    "what folders do I have?",        // Expected: chat
    "go to Documents",                // Expected: navigate
    "help me clean up",               // Expected: organize
    "tell me a joke"                  // Expected: chat
]
```

### Test Category Suggestions
```swift
// Create test images and verify categorization
let testCases = [
    ("receipt.jpg", "Documents/Receipts"),
    ("family_photo.jpg", "Photos/Family"),
    ("code_screenshot.png", "Screenshots/Code"),
]
```

## Prompt Optimization Tips

1. **Be specific:** "Respond with exactly one of: organize, chat, navigate"
2. **Provide examples:** Include 2-3 examples of each category
3. **Constrain output:** "Respond ONLY with JSON, no explanation"
4. **Handle edge cases:** "If unsure, use category 'Uncategorized'"
