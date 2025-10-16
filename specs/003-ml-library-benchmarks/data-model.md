# Data Model: ML Library Benchmarks

**Date**: 2025-10-16

## New Entities

### ModelVariant
- modelName: String (e.g., "gpt2-small")
- sizeCategory: ModelSize enum (small/medium/large)
- fileSizeMB: Int
- downloadURL: String
- cachedPath: String
- frameworks: [String] (compatible frameworks)

### ModelDeployment
- modelVariant: ModelVariant
- targetMachine: RemoteMachine
- status: DeploymentStatus
- transferProgress: Double (0.0-1.0)
- cacheTimestamp: Date?

### FrameworkMetrics (extends PerformanceMetrics)
- frameworkName: String
- modelName: String
- modelSize: ModelSize
- frameworkOverhead: Double (percentage vs Metal)
- initTime: TimeInterval
- modelLoadTime: TimeInterval
- prefillTokensPerSec: Double? (LLM only)
- decodeTokensPerSec: Double? (LLM only)

### LLMProgress
- phase: LLMPhase enum (loading/prefill/decode)
- phaseProgress: Double
- tokensProcessed: Int
- currentTokensPerSec: Double

## Enums

```swift
enum ModelSize: String, Codable {
    case small, medium, large
}

enum LLMPhase: String, Codable {
    case loading, prefill, decode
}
```

Ready for contracts.
