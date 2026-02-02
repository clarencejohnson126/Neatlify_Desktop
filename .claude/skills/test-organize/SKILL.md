---
name: test-organize
description: Create and run test scenarios for file organization
arguments:
  - name: scenario
    description: "Test scenario: 'mixed', 'images', 'documents', 'edge-cases'"
    required: false
---

# Test Organization Scenarios

Create structured test scenarios for the Neatlify file organization system.

## Test Directory Setup

```bash
# Create test folder structure
TEST_DIR=~/Desktop/NeatlifyTest
mkdir -p "$TEST_DIR"/{images,documents,mixed}

# Generate test files
touch "$TEST_DIR/images/vacation_photo.jpg"
touch "$TEST_DIR/images/receipt_2024.png"
touch "$TEST_DIR/documents/contract.pdf"
touch "$TEST_DIR/documents/notes.txt"
touch "$TEST_DIR/mixed/screenshot.png"
touch "$TEST_DIR/mixed/invoice.pdf"
touch "$TEST_DIR/mixed/random.docx"
```

## Test Scenarios

### 1. Mixed File Types (`/test-organize mixed`)

```bash
# Create diverse test set
mkdir -p ~/Desktop/TestMixed
cd ~/Desktop/TestMixed

# Images
curl -o photo1.jpg "https://picsum.photos/800/600"
curl -o photo2.png "https://picsum.photos/600/400"

# Documents (create empty placeholders)
echo "Invoice #12345 - Amount: $500" > invoice.txt
echo "Meeting notes from Q4 planning" > notes.txt
```

Expected categories:
- `Photos/` - vacation images
- `Documents/Receipts/` - financial documents
- `Documents/Notes/` - text notes

### 2. Image-Heavy (`/test-organize images`)

```bash
mkdir -p ~/Desktop/TestImages
# Download sample images of different types
# Screenshots, photos, graphics, etc.
```

Expected detection:
- Screenshots → `Screenshots/`
- Photos → `Photos/`
- Graphics → `Design/`

### 3. Document-Heavy (`/test-organize documents`)

Test PDFs, DOCs, spreadsheets.

### 4. Edge Cases (`/test-organize edge-cases`)

- Files with no extension
- Very long filenames
- Unicode characters in names
- Empty files
- Corrupted images
- Password-protected PDFs

## Unit Test Templates

Location: `Neatlify Desktop/Neatlify DesktopTests/`

### FileService Tests

```swift
import XCTest
@testable import Neatlify_Desktop

class FileServiceTests: XCTestCase {
    var fileService: FileService!

    override func setUp() {
        super.setUp()
        fileService = FileService()
    }

    func testScanFolder_EmptyDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let files = try await fileService.scanFolder(at: tempDir.path)
        XCTAssertEqual(files.count, 0)

        try FileManager.default.removeItem(at: tempDir)
    }

    func testScanFolder_IgnoresHiddenFiles() async throws {
        // Hidden files (starting with .) should be skipped
    }

    func testScanFolder_IgnoresSystemFolders() async throws {
        // .DS_Store, .Trash, etc. should be skipped
    }
}
```

### FileType Detection Tests

```swift
func testFileType_ImageDetection() {
    let jpgFile = FileItem(path: "/test/photo.jpg", name: "photo.jpg")
    XCTAssertEqual(jpgFile.fileType, .image)

    let pngFile = FileItem(path: "/test/screenshot.png", name: "screenshot.png")
    XCTAssertEqual(pngFile.fileType, .image)

    let heicFile = FileItem(path: "/test/IMG_0001.HEIC", name: "IMG_0001.HEIC")
    XCTAssertEqual(heicFile.fileType, .image)
}

func testFileType_PDFDetection() {
    let pdfFile = FileItem(path: "/test/document.pdf", name: "document.pdf")
    XCTAssertEqual(pdfFile.fileType, .pdf)
}
```

### Organization Tests

```swift
func testOrganization_CreatesCorrectFolders() async throws {
    // Test that organization creates expected folder structure
}

func testOrganization_MovesFilesCorrectly() async throws {
    // Test file movement
}

func testOrganization_HandlesConflicts() async throws {
    // Test behavior when destination file already exists
}
```

## Manual Testing Checklist

- [ ] Scan folder with 10 files
- [ ] Scan folder with 100 files
- [ ] Scan folder with 1000 files
- [ ] Test with images only
- [ ] Test with PDFs only
- [ ] Test with mixed types
- [ ] Test with nested folders
- [ ] Test cancellation mid-scan
- [ ] Test undo after organization
- [ ] Test with permission-denied files

## Performance Benchmarks

Target: 100 files in < 90 seconds

```swift
func testPerformance_100Files() {
    measure {
        // Organization of 100 mixed files
    }
}
```
