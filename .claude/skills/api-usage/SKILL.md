---
name: api-usage
description: Track and optimize Claude API token consumption and costs
---

# Claude API Usage Patterns

Monitor token consumption, estimate costs, and optimize API usage.

## API Methods Overview

| Method | Location | Purpose | Est. Tokens/Call |
|--------|----------|---------|------------------|
| `chat()` | Lines 47-91 | Conversational AI | ~500-2000 |
| `parseIntent()` | Lines 93-145 | Detect user intent | ~200-500 |
| `analyzeImages()` | Lines 214-275 | Vision analysis | ~1000-3000 |
| `analyzeTextContent()` | Lines 280-340 | Text analysis | ~300-800 |
| `generateLabels()` | Lines 357-400 | Category generation | ~200-400 |

## Cost Estimation

### Per-File Costs (Claude 3.5 Sonnet pricing)

| File Type | Input Tokens | Output Tokens | Cost |
|-----------|--------------|---------------|------|
| Image | ~1500 | ~100 | ~$0.005 |
| PDF | ~300 | ~50 | ~$0.001 |
| Text | ~200 | ~50 | ~$0.0008 |

### Batch Costs

| Scenario | Files | Est. Cost |
|----------|-------|-----------|
| 100 images | 100 | ~$0.50 |
| 100 PDFs | 100 | ~$0.10 |
| 100 mixed | 100 | ~$0.30 |
| 1000 mixed | 1000 | ~$3.00 |

**Average: ~$0.47 per 100 files organized**

## Rate Limiting

```swift
// ClaudeAPIService.swift lines 473-479
// Current implementation:
private let rateLimitDelay: TimeInterval = 2.0  // seconds between batches

// Rate limit handling
if response.statusCode == 429 {
    // Exponential backoff
    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
}
```

## Token Counting

```swift
// Rough token estimation
func estimateTokens(_ text: String) -> Int {
    // ~4 characters per token for English
    return text.count / 4
}

// Image tokens (based on resolution)
func estimateImageTokens(width: Int, height: Int) -> Int {
    // Claude charges ~765 tokens per 512x512 tile
    let tiles = ceil(Double(width) / 512) * ceil(Double(height) / 512)
    return Int(tiles * 765)
}
```

## Optimization Strategies

### 1. Reduce Image Size

**Current:** 1024px max dimension
**Optimized:** 768px max dimension (saves ~30% tokens)

```swift
// ImageProcessor.swift
let maxDimension: CGFloat = 768  // was 1024
```

### 2. Batch Size Tuning

**Current:** 10 images per batch, 5 PDFs per batch
**Trade-off:** Larger batches = fewer API calls but higher per-call risk

### 3. Caching

```swift
// Cache analysis results by file hash
struct AnalysisCache {
    let fileHash: String
    let category: String
    let timestamp: Date
}
```

### 4. Reduce Inter-Batch Delay

**Current:** 2 seconds
**Safe minimum:** 1 second (unless hitting rate limits)

### 5. Smarter File Filtering

Skip files that don't need AI analysis:
- Already organized (in dated/named folders)
- System files
- Duplicates (by hash)

## Monitoring Dashboard

```swift
// Add to OrganizationViewModel
struct APIUsageStats {
    var totalCalls: Int = 0
    var totalInputTokens: Int = 0
    var totalOutputTokens: Int = 0
    var estimatedCost: Double = 0.0
    var rateLimitHits: Int = 0

    mutating func recordCall(inputTokens: Int, outputTokens: Int) {
        totalCalls += 1
        totalInputTokens += inputTokens
        totalOutputTokens += outputTokens
        // Claude 3.5 Sonnet pricing
        estimatedCost += Double(inputTokens) * 0.000003 + Double(outputTokens) * 0.000015
    }
}
```

## Debug Commands

```bash
# Check API response headers for usage
# Add logging to see actual token counts from response

# Search for token-related code
grep -rn "token\|usage\|cost" "Neatlify Desktop/Neatlify Desktop/Services/ClaudeAPIService.swift"

# Find rate limit handling
grep -rn "429\|rate\|limit\|retry" "Neatlify Desktop/Neatlify Desktop/Services/"
```

## API Response Structure

```json
{
  "id": "msg_xxx",
  "type": "message",
  "usage": {
    "input_tokens": 1234,
    "output_tokens": 567
  },
  "content": [...]
}
```

Log the `usage` field to track actual consumption.

## Cost Alert Thresholds

| Level | Threshold | Action |
|-------|-----------|--------|
| Info | 100 files | Log usage stats |
| Warning | 500 files | Warn user about credits |
| Alert | 1000 files | Recommend batch limits |
