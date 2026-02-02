---
name: debug-analysis
description: Trace file analysis pipeline from scan to categorization
arguments:
  - name: type
    description: "File type to trace: 'image', 'pdf', 'text', or 'all'"
    required: false
---

# File Analysis Pipeline Debugger

Trace the complete path: Folder Scan → File Filter → Processing → Claude API → Category Assignment

## Pipeline Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐    ┌──────────────┐
│ FileService │ → │ FileItem     │ → │ Image/PDF       │ → │ ClaudeAPI    │
│ .scanFolder │    │ .FileType    │    │ Processor       │    │ .analyze*    │
│ (21-64)     │    │ detection    │    │                 │    │ (214-325)    │
└─────────────┘    └──────────────┘    └─────────────────┘    └──────────────┘
```

## Key Files & Line Numbers

| Component | File | Lines | Purpose |
|-----------|------|-------|---------|
| Folder Scan | `Services/FileService.swift` | 21-64 | Enumerate files |
| Type Detection | `Models/FileItem.swift` | varies | Determine file type |
| Image Processing | `Utilities/ImageProcessor.swift` | all | Resize + base64 encode |
| PDF Processing | `Utilities/PDFProcessor.swift` | all | Extract text (first 500 chars) |
| Image Analysis | `Services/ClaudeAPIService.swift` | 214-232 | Vision API call |
| Text Analysis | `Services/ClaudeAPIService.swift` | 280-325 | Text-based analysis |
| Labeling | `Services/ClaudeAPIService.swift` | 357-378 | Category generation |

## Debug by File Type

### Image Analysis (`/debug-analysis image`)

```swift
// Add to ImageProcessor.swift
print("📷 Processing: \(imageURL.lastPathComponent)")
print("   Original size: \(originalSize)")
print("   Encoded size: \(base64String.count) bytes")
print("   Max dimension: 1024px")
```

Check `ClaudeAPIService.swift` lines 217-232 for image prompt.

### PDF Analysis (`/debug-analysis pdf`)

```swift
// Add to PDFProcessor.swift
print("📄 PDF: \(pdfURL.lastPathComponent)")
print("   Pages: \(document.pageCount)")
print("   Extracted chars: \(extractedText.count) (max 500)")
```

### Text Analysis (`/debug-analysis text`)

Text files are read directly. Check `ClaudeAPIService.analyzeTextContent()` at line 280.

## Monitoring Commands

```bash
# Watch for API calls in Console.app
log stream --predicate 'subsystem == "com.neatlify.desktop"' --level debug

# Check file type distribution
find ~/Desktop -type f | rev | cut -d. -f1 | rev | sort | uniq -c | sort -rn

# Monitor Claude API responses
grep -n "suggestedCategory\|label\|error" "Neatlify Desktop/Neatlify Desktop/Services/ClaudeAPIService.swift"
```

## Common Issues

### Issue: Image not analyzed
**Symptoms:** File skipped or generic category
**Debug:** Check `ImageProcessor.swift` - verify image can be loaded and encoded
**Fix:** Ensure image format is supported (JPEG, PNG, HEIC, WebP)

### Issue: PDF text extraction fails
**Symptoms:** PDF gets wrong category
**Debug:** Check if PDF is text-based or scanned (image-only)
**Fix:** For scanned PDFs, consider OCR or image-based analysis

### Issue: Wrong category assigned
**Symptoms:** Files in unexpected folders
**Debug:**
1. Log the prompt sent to Claude API
2. Log the raw response
3. Check JSON parsing at line 325

### Issue: Rate limiting
**Symptoms:** Sudden failures after many files
**Check:** `ClaudeAPIService.swift` lines 473-479
**Fix:** Increase delay between batches (currently 2 seconds)

## Batch Processing Flow

```
OrganizationViewModel.executeOrganization()
    ↓
For each batch of 10 images:
    → ImageProcessor.encode() [parallel]
    → ClaudeAPIService.analyzeImages() [single call]
    → Parse response
    → 2 second delay
    ↓
For each batch of 5 PDFs:
    → PDFProcessor.extractText() [parallel]
    → ClaudeAPIService.analyzeTextContent()
    → Parse response
```
