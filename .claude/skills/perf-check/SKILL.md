---
name: perf-check
description: Analyze and optimize performance for file organization
arguments:
  - name: files
    description: "Number of files to benchmark (default: 100)"
    required: false
---

# Performance Analysis & Optimization

Target: 100 files organized in < 90 seconds

## Current Pipeline Timing

| Phase | Current | Target | Bottleneck |
|-------|---------|--------|------------|
| Folder Scan | ~2s | 1s | File enumeration |
| Image Encoding | ~20s | 10s | Parallel, but CPU-bound |
| API Calls | ~50s | 40s | Rate limiting + batch delays |
| File Moves | ~5s | 5s | Disk I/O |
| **Total** | **~77s** | **56s** | API is main bottleneck |

## Optimization Opportunities

### 1. Image Processing (Currently Unlimited Parallel)

**Current:** All images encoded in parallel (can overwhelm CPU/memory)

```swift
// Current approach - TaskGroup with no limit
await withTaskGroup(of: (URL, String?).self) { group in
    for imageURL in imageURLs {
        group.addTask {
            return (imageURL, await ImageProcessor.encode(imageURL))
        }
    }
}
```

**Optimized:** Limit concurrency

```swift
// Add concurrency limit
let semaphore = AsyncSemaphore(value: 4)  // Max 4 concurrent

await withTaskGroup(of: (URL, String?).self) { group in
    for imageURL in imageURLs {
        group.addTask {
            await semaphore.wait()
            defer { semaphore.signal() }
            return (imageURL, await ImageProcessor.encode(imageURL))
        }
    }
}
```

### 2. Image Size Reduction

**Current:** 1024px max dimension
**Optimized:** 768px (30% fewer pixels, ~30% faster encoding)

```swift
// ImageProcessor.swift
let maxDimension: CGFloat = 768  // was 1024
```

Token impact: ~40% reduction in vision tokens

### 3. Batch Size Tuning

**Current:**
- Images: 10 per batch
- PDFs: 5 per batch

**Trade-offs:**
| Batch Size | API Calls | Latency | Risk |
|------------|-----------|---------|------|
| 5 images | More calls | Lower per-call | Lower retry cost |
| 10 images | Fewer calls | Higher per-call | Higher retry cost |
| 20 images | Fewest calls | Highest per-call | Highest retry cost |

**Recommendation:** Keep 10 images, but retry individual failures

### 4. Inter-Batch Delay

**Current:** 2 seconds between batches
**Optimized:** 1 second (if not hitting rate limits)

```swift
// ClaudeAPIService.swift
private let batchDelay: TimeInterval = 1.0  // was 2.0
```

### 5. Caching

**Add file hash cache:**
```swift
struct AnalysisCache {
    static let shared = AnalysisCache()
    private var cache: [String: CachedResult] = [:]  // hash -> result

    struct CachedResult {
        let category: String
        let confidence: Double
        let timestamp: Date
    }

    func lookup(fileHash: String) -> CachedResult? {
        guard let cached = cache[fileHash],
              cached.timestamp.timeIntervalSinceNow > -86400 else {  // 24h TTL
            return nil
        }
        return cached
    }
}
```

### 6. Skip Already-Organized Files

```swift
// FileService.scanFolder()
func shouldAnalyze(_ file: FileItem) -> Bool {
    // Skip files in known organization patterns
    let organizedPatterns = [
        "/Photos/",
        "/Documents/",
        "/Screenshots/",
        "/Downloads/Organized/"
    ]
    return !organizedPatterns.contains { file.path.contains($0) }
}
```

## Benchmarking Code

```swift
// Add to OrganizationViewModel
struct PerformanceMetrics {
    var scanTime: TimeInterval = 0
    var encodeTime: TimeInterval = 0
    var apiTime: TimeInterval = 0
    var moveTime: TimeInterval = 0
    var totalFiles: Int = 0

    var totalTime: TimeInterval {
        scanTime + encodeTime + apiTime + moveTime
    }

    var filesPerSecond: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalFiles) / totalTime
    }
}

func measurePhase<T>(_ name: String, _ block: () async throws -> T) async rethrows -> T {
    let start = Date()
    let result = try await block()
    let elapsed = Date().timeIntervalSince(start)
    print("⏱ \(name): \(String(format: "%.2f", elapsed))s")
    return result
}
```

## Console Monitoring

```bash
# Watch CPU usage during organization
top -pid $(pgrep -f "Neatlify Desktop") -l 2

# Monitor memory
vmmap $(pgrep -f "Neatlify Desktop") | grep "TOTAL"

# Check for memory leaks
leaks $(pgrep -f "Neatlify Desktop")
```

## Xcode Instruments

Profile with:
1. **Time Profiler** - Find CPU bottlenecks
2. **Allocations** - Track memory usage
3. **Network** - Monitor API call timing
4. **System Trace** - File I/O analysis

## Expected Improvements

| Optimization | Time Saved |
|-------------|------------|
| Limit concurrent encoding | 5s (reduces memory pressure) |
| Reduce image size to 768px | 8s (encoding + API) |
| Reduce batch delay to 1s | 5s (10 batches × 1s) |
| Smart file filtering | Variable (skip already organized) |
| **Total Potential** | **~18s (77s → 59s)** |

## Performance Targets by File Count

| Files | Current | Optimized | Target |
|-------|---------|-----------|--------|
| 50 | ~40s | ~30s | 30s |
| 100 | ~77s | ~59s | 60s |
| 500 | ~6min | ~4.5min | 5min |
| 1000 | ~12min | ~9min | 10min |

## Quick Performance Test

```bash
# Create test folder with N files
mkdir -p ~/Desktop/PerfTest
for i in {1..100}; do
    curl -s "https://picsum.photos/800/600" > ~/Desktop/PerfTest/img_$i.jpg
done

# Run organization and time it
time # (manual timing in app)
```
