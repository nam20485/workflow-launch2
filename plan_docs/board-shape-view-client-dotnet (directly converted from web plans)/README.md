# board-shape-view-client-dotnet

**Cross-Platform PCB Viewer** - Desktop Application built with Avalonia UI and .NET

---

## Overview

This directory contains the planning documents for **board-shape-view-client-dotnet**, a native cross-platform desktop application for visualizing ODB++ PCB designs. Built with modern .NET technologies (C# 12, .NET 8+, Avalonia UI), this application provides superior performance and native OS integration compared to web-based alternatives.

**Key Features:**
- ✅ Cross-platform: Windows, Linux, macOS
- ✅ Hardware-accelerated 2D/3D rendering
- ✅ Native desktop UX with OS integration
- ✅ Offline-capable (local file support)
- ✅ MVVM architecture with reactive UI
- ✅ High performance (60 FPS with 100k+ features)

---

## Technology Stack

| Category | Technology |
|----------|------------|
| **Language** | C# 12+ (.NET 8/9) |
| **UI Framework** | Avalonia UI 11.x+ |
| **MVVM Toolkit** | CommunityToolkit.Mvvm 8.x+ |
| **Rendering (2D/2.5D)** | SkiaSharp 2.88.x+ |
| **Rendering (3D)** | Silk.NET.OpenGL / Veldrid |
| **State Management** | ReactiveUI 19.x+ |
| **HTTP Client** | System.Net.Http |
| **JSON** | System.Text.Json |
| **Testing** | xUnit, Moq, Avalonia.Headless |

See [New Application document](./New%20Application_%20board-shape-view-client-dotnet.md) for complete technology stack details.

---

## Documents

### Planning & Specifications
- **[New Application: board-shape-view-client-dotnet](./New%20Application_%20board-shape-view-client-dotnet.md)**  
  Application overview, technology stack, project structure, and deliverables

- **[Development Plan](./board-shape-view-client-dotnet_%20Development%20Plan.md)**  
  Phased implementation strategy, user stories, timeline estimates, risk analysis

- **[Architecture](./board-shape-view-client-dotnet_%20Architecture.md)**  
  Detailed system architecture, MVVM pattern, rendering pipeline, dependency injection

### Technical References (Shared with Web Version)
- **[API.md](./API.md)**  
  OdbDesignServer REST API documentation

- **[ODB_REST_API_INTEGRATION.md](./ODB_REST_API_INTEGRATION.md)**  
  Field naming conventions, JSON response examples, integration patterns

- **[ODB_SHAPE_DEFINITIONS.md](./ODB_SHAPE_DEFINITIONS.md)**  
  Complete ODB++ shape reference, feature types, coordinate systems

- **[ODB++_Shape_Representation_Research.md](./ODB++_Shape_Representation_Research.md)**  
  Research findings on ODB++ format specification

---

## Additional .NET Technologies Required

Beyond the core stack listed above, the following libraries are essential for production implementation:

### Essential Libraries
- **NetTopologySuite** - Polygon operations, spatial indexing
- **MathNet.Numerics** - Matrix transformations, linear algebra
- **Microsoft.Extensions.Configuration** - appsettings.json support
- **Microsoft.Extensions.Options** - Strongly-typed configuration
- **FluentValidation** - Input/data validation
- **Microsoft.Extensions.Caching.Memory** - Symbol/standard caching

### UI Enhancement
- **Avalonia.Controls.DataGrid** - Layer panel grid
- **Avalonia.Dialogs** - Native file/folder dialogs
- **Avalonia.Themes.Fluent** - Modern Fluent Design UI
- **LiveChartsCore** - Performance metrics visualization (optional)

### Platform-Specific
- **Windows:** System.Drawing.Common (rendering optimizations)
- **Linux:** SkiaSharp.NativeAssets.Linux (hardware acceleration)
- **macOS:** SkiaSharp.NativeAssets.macOS (Metal backend)

### Packaging & Distribution
- **Windows:** WiX Toolset → MSI installer
- **Linux:** dpkg/rpm → DEB/RPM packages
- **macOS:** create-dmg → DMG installer

---

## Architecture Highlights

### MVVM Pattern
```
Views (XAML) ← Data Binding → ViewModels (C#) → Services → API/Rendering
```

**Key Components:**
- `ObservableObject` base class (CommunityToolkit.Mvvm)
- `RelayCommand` for command binding
- `ReactiveUI` for complex state management
- Dependency injection with `Microsoft.Extensions.DependencyInjection`

### Rendering Pipeline

**Phase 1 (MVP): 2D/2.5D with SkiaSharp**
```
BoardViewportControl → SkiaRenderingEngine → FeatureRenderers → SKCanvas → GPU
```

**Phase 3: True 3D with OpenGL**
```
BoardViewportControl → OpenGLRenderingEngine → Scene Graph → VBOs → Shaders → GPU
```

### Solution Structure
```
BoardShapeViewClient.sln
├── src/
│   ├── BoardShapeViewClient.Desktop/     # Avalonia app (entry point)
│   ├── BoardShapeViewClient.Core/        # Domain models
│   ├── BoardShapeViewClient.Api/         # REST API client
│   ├── BoardShapeViewClient.Rendering/   # Graphics engine
│   └── BoardShapeViewClient.Services/    # Application services
└── tests/
    ├── BoardShapeViewClient.Core.Tests/
    └── BoardShapeViewClient.Desktop.Tests/ # UI integration tests
```

---

## Development Phases

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| **Phase 1: Foundation & MVP** | 4-6 weeks | 2.5D viewer with SkiaSharp, API integration, basic rendering |
| **Phase 2: Core Features** | 4-6 weeks | All feature types, layer panel, file dialogs, theming |
| **Phase 3: 3D Visualization** | 6-8 weeks | OpenGL integration, perspective camera, interactive selection |
| **Phase 4: Production Ready** | 4-6 weeks | Installers, auto-update, performance optimization |

**Total Timeline:** 18-26 weeks (part-time team of 2-4 developers)

---

## Why .NET/Avalonia Over Web?

### Advantages ✅
- **5-10x faster rendering** vs. browser canvas
- **Direct GPU acceleration** with better memory management
- **Native file system access** (no CORS, security restrictions)
- **Superior UX:** Native dialogs, multi-window, OS integration
- **Offline-first:** No web server required
- **Advanced graphics:** Easier OpenGL/Vulkan integration

### Trade-offs ⚠️
- **Installation required** (vs. instant web access)
- **Platform-specific builds** (Win/Linux/Mac)
- **Update distribution** (MSI/DMG vs. automatic web updates)
- **Bundle size:** 50-100 MB installers vs. ~2 MB web app

---

## Getting Started

### Prerequisites
```bash
# Install .NET 8 SDK
wget https://dot.net/v1/dotnet-install.sh
bash dotnet-install.sh --channel 8.0

# Verify installation
dotnet --version  # Should be 8.0.x or higher
```

### Create New Avalonia Project
```bash
# Install Avalonia templates
dotnet new install Avalonia.Templates

# Create MVVM application
dotnet new avalonia.mvvm -o BoardShapeViewClient

# Add required packages
cd BoardShapeViewClient
dotnet add package CommunityToolkit.Mvvm
dotnet add package ReactiveUI
dotnet add package SkiaSharp
```

### Run Application
```bash
dotnet restore
dotnet run --project src/BoardShapeViewClient.Desktop
```

### Run Tests
```bash
dotnet test
```

---

## Performance Targets

- **Render Speed:** 100,000 features @ 60 FPS
- **Startup Time:** < 3 seconds to first render
- **Memory Usage:** < 500 MB for typical boards (<50k features)
- **Cross-Platform:** Zero platform-specific bugs after Phase 1
- **Test Coverage:** Minimum 80% for Core and Rendering projects

---

## Related Repositories

- **[OdbDesign](https://github.com/nam20485/OdbDesign)** - C++ ODB++ parser and server
- **[board-shape-view-client](https://github.com/nam20485/board-shape-view-client)** - Web-based React/TypeScript version
- **[shape-sdk](https://github.com/nam20485/shape-sdk)** - Shape definition toolkit

---

## Contributing

See the main Development Plan for coding standards, testing requirements, and contribution guidelines. Key principles:

- Follow MVVM best practices
- Use CommunityToolkit.Mvvm source generators (no manual `INotifyPropertyChanged`)
- Write unit tests for all business logic
- Use Avalonia.Headless for UI integration tests
- Target .NET 8 LTS for production builds

---

## License

TBD (same as parent project)

---

**Last Updated:** January 2025  
**Document Version:** 1.0  
**Target .NET Version:** .NET 8.0 LTS or .NET 10.0
