---
name: undo-system
description: Debug and improve the file operation undo system
---

# Undo System Analysis

The undo system tracks file moves and allows reverting organization.

## Current Implementation

**Location:** `Neatlify Desktop/Services/FileService.swift` lines 250-283

```swift
struct UndoOperation {
    let originalPath: String
    let newPath: String
    let timestamp: Date  // BUG: Always returns new Date() on access
}

class FileService {
    private var undoStack: [UndoOperation] = []
    private let maxUndoOperations = 1000

    func moveFile(from source: URL, to destination: URL) throws {
        try FileManager.default.moveItem(at: source, to: destination)
        undoStack.append(UndoOperation(
            originalPath: source.path,
            newPath: destination.path,
            timestamp: Date()
        ))

        // Trim if over limit
        if undoStack.count > maxUndoOperations {
            undoStack.removeFirst()
        }
    }

    func undoLastOperation() throws -> Bool {
        guard let lastOp = undoStack.popLast() else { return false }
        try FileManager.default.moveItem(
            atPath: lastOp.newPath,
            toPath: lastOp.originalPath
        )
        return true
    }

    func undoAll() throws -> Int {
        var count = 0
        while try undoLastOperation() {
            count += 1
        }
        return count
    }
}
```

## Known Issues

### 1. In-Memory Only (Lost on Restart)

**Problem:** Undo stack exists only in memory. Closing app = lost history.

**Fix:** Persist to disk

```swift
// Add to FileService
private let undoStackURL = FileManager.default
    .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("com.neatlify.desktop/undo_stack.json")

func saveUndoStack() throws {
    let data = try JSONEncoder().encode(undoStack)
    try data.write(to: undoStackURL)
}

func loadUndoStack() throws {
    let data = try Data(contentsOf: undoStackURL)
    undoStack = try JSONDecoder().decode([UndoOperation].self, from: data)
}
```

### 2. Timestamp Bug

**Problem:** `timestamp` property always returns `Date()` instead of stored value

**Location:** Check struct definition - might be a computed property instead of stored

**Fix:**
```swift
struct UndoOperation: Codable {
    let originalPath: String
    let newPath: String
    let timestamp: Date  // Ensure this is stored, not computed

    init(originalPath: String, newPath: String, timestamp: Date = Date()) {
        self.originalPath = originalPath
        self.newPath = newPath
        self.timestamp = timestamp  // Store the passed value
    }
}
```

### 3. No UI for Undo

**Current:** No visible undo button in ContentView

**Fix:** Add undo UI

```swift
// ContentView.swift
Button(action: { viewModel.undoLastOrganization() }) {
    Label("Undo", systemImage: "arrow.uturn.backward")
}
.disabled(viewModel.undoStack.isEmpty)

// Show count
Text("\(viewModel.undoStackCount) operations can be undone")
```

### 4. No Partial Undo

**Current:** Only undo all or undo one-by-one

**Improvement:** Allow selecting specific operations to undo

```swift
func undoOperations(indices: [Int]) throws {
    // Undo specific operations by index
    let toUndo = indices.sorted(by: >).compactMap { undoStack[safe: $0] }
    for op in toUndo {
        try FileManager.default.moveItem(atPath: op.newPath, toPath: op.originalPath)
    }
    // Remove from stack
    for index in indices.sorted(by: >) {
        undoStack.remove(at: index)
    }
}
```

## Debugging Commands

```bash
# Find undo-related code
grep -rn "undo\|Undo\|revert" "Neatlify Desktop/Neatlify Desktop/"

# Check FileService implementation
grep -n "undoStack\|UndoOperation" "Neatlify Desktop/Neatlify Desktop/Services/FileService.swift"

# Look for persistence
grep -rn "UserDefaults\|FileManager.*write\|JSONEncoder" "Neatlify Desktop/Neatlify Desktop/Services/"
```

## Improvement Plan

### Phase 1: Persistence
1. Add Codable conformance to UndoOperation
2. Save stack on each operation
3. Load stack on app launch
4. Handle missing/corrupted file

### Phase 2: UI
1. Add "Undo Last" button to ContentView
2. Add "Undo All" button
3. Show undo stack count
4. Add "View Undo History" sheet

### Phase 3: Enhanced Features
1. Group operations by session/batch
2. Allow partial undo
3. Add redo capability
4. Show operation preview before undoing

## Testing Undo

```swift
// Unit tests
func testUndo_SingleOperation() {
    let service = FileService()

    // Setup test file
    let tempDir = FileManager.default.temporaryDirectory
    let source = tempDir.appendingPathComponent("test.txt")
    let dest = tempDir.appendingPathComponent("organized/test.txt")

    // Create file and directory
    try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: source.path, contents: nil)

    // Move
    try service.moveFile(from: source, to: dest)
    XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))

    // Undo
    let undone = try service.undoLastOperation()
    XCTAssertTrue(undone)
    XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path))
}
```

## Related Code

| File | Purpose |
|------|---------|
| `FileService.swift` | Core undo logic |
| `OrganizationViewModel.swift` | Orchestrates file moves |
| `ContentView.swift` | Needs undo UI |
| `PreviewSheet.swift` | Could show undo option after completion |
