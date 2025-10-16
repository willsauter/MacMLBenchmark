# MacMLBenchmark Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-16

## Active Technologies
- Swift 5.9+ (for Metal Performance Shaders access and macOS system APIs) + Metal Performance Shaders (MPS), Foundation, ArgumentParser (CLI), SwiftJSON (result export) (001-mac-ml-benchmark-suite)
- Swift 5.9+ (consistent with Feature 001) + Existing (ArgumentParser, Metal), New: Process/SSH for remote execution, terminal UI library for interactive menu (002-remote-deploy-menu)
- File system (JSON for SSH profiles and multi-machine results), extends existing result expor (002-remote-deploy-menu)
- Swift 5.9+ (primary), Python 3.10+ (for TensorFlow/PyTorch via subprocess) (003-ml-library-benchmarks)
- File system (model cache in models/ dir, results extend existing JSON export) (003-ml-library-benchmarks)

## Project Structure
```
src/
tests/
```

## Commands
# Add commands for Swift 5.9+ (for Metal Performance Shaders access and macOS system APIs)

## Code Style
Swift 5.9+ (for Metal Performance Shaders access and macOS system APIs): Follow standard conventions

## Recent Changes
- 003-ml-library-benchmarks: Added Swift 5.9+ (primary), Python 3.10+ (for TensorFlow/PyTorch via subprocess)
- 002-remote-deploy-menu: Added Swift 5.9+ (consistent with Feature 001) + Existing (ArgumentParser, Metal), New: Process/SSH for remote execution, terminal UI library for interactive menu
- 002-remote-deploy-menu: Added Swift 5.9+ (consistent with Feature 001) + Existing (ArgumentParser, Metal), New: Process/SSH for remote execution, terminal UI library for interactive menu

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
