# Framework Interface Contract

**Date**: 2025-10-16

## Python Script Interface

All Python benchmark scripts must output JSON to stdout:

```json
{
  "framework": "tensorflow",
  "modelName": "gpt2-small",
  "modelSize": "small",
  "metrics": {
    "throughputOpsPerSec": 42.5,
    "latencyMs": 23.5,
    "initTimeMs": 1250,
    "modelLoadTimeMs": 850,
    "prefillTokensPerSec": 125.0,
    "decodeTokensPerSec": 45.0
  },
  "progress": {
    "phase": "decode",
    "percent": 85,
    "tokensProcessed": 850
  }
}
```

## Model Deployment

Uses SSH from Feature 002:
- Transfer: `scp models/gpt2-small.bin user@host:~/models/`
- Verify: `ssh user@host "shasum ~/models/gpt2-small.bin"`
- Cache check: `ssh user@host "[ -f ~/models/gpt2-small.bin ] && echo exists"`

Phase 1 complete.
