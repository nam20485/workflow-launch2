# Architecture Guide - Summary

## System Overview

The Performer Identifier uses a three-layer modular architecture:

1. **Core Library** - Platform-agnostic ML logic
2. **Windows Implementation** - DirectML GPU acceleration
3. **Application Layer** - WinUI 3 UI

## Key Components

- **Face Detection Service** - ONNX-based detection and recognition
- **Video Frame Extractor** - FFmpeg integration
- **Performer Repository** - SQLite database with EF Core
- **Video Processor** - Orchestrates the full pipeline

## Design Patterns

- Strategy Pattern (platform implementations)
- Template Method (base services)
- Repository Pattern (data access)
- Factory Pattern (service creation)
- Observer Pattern (progress reporting)

## Performance

- Windows (DirectML): ~30-50 FPS
- Cross-platform (CPU): ~5-15 FPS
- Bottleneck: ONNX inference (GPU/CPU bound)

For the complete architectural details, diagrams, and technical specifications, see the full Architecture Guide artifact in the conversation above.