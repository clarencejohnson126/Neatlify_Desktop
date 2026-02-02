---
name: sync-context
description: Debug conversation history and context passing between ChatViewModel and OrganizationViewModel
---

# Session Context Debugging

Debug issues where the AI "forgets" previous folder references or conversation context.

## Key Architecture

Context flows: `ChatViewModel` → `OrganizationViewModel` → `ClaudeAPIService`

### Critical Files & Lines

| File | Lines | Purpose |
|------|-------|---------|
| `Neatlify Desktop/ViewModels/ChatViewModel.swift` | 81-91 | Stores conversation history |
| `Neatlify Desktop/ViewModels/OrganizationViewModel.swift` | 33, 56-62 | Receives context from ChatViewModel |
| `Neatlify Desktop/Services/ClaudeAPIService.swift` | 21-45 | System prompt with context |

## Debug Steps

### 1. Check Current Conversation State
```swift
// In ChatViewModel - verify messages array
print("Chat messages count: \(messages.count)")
for msg in messages {
    print("[\(msg.role)]: \(msg.content.prefix(100))...")
}
```

### 2. Verify Context Handoff
```swift
// In OrganizationViewModel.startOrganization()
print("Received context: \(conversationContext ?? "nil")")
print("Selected folder: \(selectedFolderPath ?? "nil")")
```

### 3. Check API Request
Look at `ClaudeAPIService.swift` line 473-479 for how conversation history is formatted in API calls.

## Common Issues

### Issue: AI doesn't remember folder selection
**Cause:** `conversationContext` not passed when switching views
**Fix:** Ensure `OrganizationViewModel.setContext()` is called before `startOrganization()`

### Issue: Context truncated
**Cause:** Token limit management cuts relevant context
**Fix:** Check `ClaudeAPIService.swift` for token counting logic

### Issue: System prompt overrides context
**Cause:** New system prompt replaces conversation context
**Fix:** Append context to system prompt rather than replacing

## Diagnostic Commands

```bash
# Search for context-related code
grep -n "conversationContext\|messageHistory\|context" "Neatlify Desktop/Neatlify Desktop/ViewModels/"*.swift

# Check how messages are passed to API
grep -n "messages\|content\|role" "Neatlify Desktop/Neatlify Desktop/Services/ClaudeAPIService.swift" | head -50
```

## Quick Fixes

1. **Add logging** to `ChatViewModel.sendMessage()` at line 81
2. **Verify binding** between ChatView and OrganizationView
3. **Check @Published** properties are triggering updates
