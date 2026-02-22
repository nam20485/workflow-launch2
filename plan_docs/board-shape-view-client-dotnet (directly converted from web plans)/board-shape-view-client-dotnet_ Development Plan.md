# **board-shape-view-client-dotnet: Development Plan**

This document provides a comprehensive, multi-phase development plan for the board-shape-view-client-dotnet application. It incorporates the architectural decisions, outlines the core .NET/Avalonia technologies, and defines user stories for key features, with a primary focus on delivering a functional MVP in the first phase.

## **1. Motivation & Guiding Principles**

The core purpose of this project is to create a high-performance, cross-platform desktop application that can visualize complex Printed Circuit Board (PCB) designs from ODB++ data. The target audience is PCB designers and engineers who need a fast, native tool to view and inspect board layouts with superior performance compared to web-based solutions. Success is a responsive desktop viewer that can render boards from a remote data source and provide advanced interactive controls with native OS integration.

The project is guided by these core principles:

* **Speed to MVP**: The highest priority is to develop a working prototype that demonstrates the core functionality: fetching data, rendering shapes, and basic 2.5D navigation with SkiaSharp. Later phases will build upon this solid foundation with full 3D capabilities.
* **Native Performance**: Leverage .NET's performance characteristics and hardware-accelerated rendering to provide fluid interaction even with large, complex boards.
* **Cross-Platform First**: Design and test for Windows, Linux, and macOS from day one. Use Avalonia's cross-platform abstractions to avoid platform-specific code where possible.
* **MVVM Architecture**: Follow established MVVM patterns with CommunityToolkit.Mvvm for testability, maintainability, and clear separation of concerns.
* **Reactive UI**: Use ReactiveUI and System.Reactive for responsive, event-driven user interfaces that handle async operations gracefully.

## **2. Architectural Decisions**

To achieve our goals of performance, cross-platform support, and native experience, we have chosen to build the application as a modern .NET desktop application using Avalonia UI. This approach provides native performance, OS integration, and hardware-accelerated graphics capabilities.

We evaluated several options before arriving at our chosen architecture:

* **Alternative Option 1 (WPF)**: Windows Presentation Foundation was considered for Windows-only deployment. It was rejected because it locks us into the Windows ecosystem and doesn't align with the cross-platform requirement.
* **Alternative Option 2 (Electron)**: Electron-based desktop wrapper was considered for code reuse with web version. It was rejected due to massive resource overhead (500MB+ memory baseline), poor performance for graphics-intensive applications, and lack of true native controls.
* **Alternative Option 3 (MAUI)**: .NET MAUI was considered as Microsoft's cross-platform framework. It was rejected because it's primarily mobile-focused with less mature desktop support compared to Avalonia, especially on Linux.
* **Chosen Approach (Avalonia UI)**: This approach was selected for its **mature cross-platform desktop support**, **native performance**, **XAML-based UI design**, and **excellent .NET integration**. The primary challenges—learning curve for Avalonia-specific patterns and smaller ecosystem compared to web—are mitigated by comprehensive documentation and the ability to use standard .NET libraries.

## **3. Core Technologies**

### **UI Framework**
* **Avalonia UI (11.x+)**
  * **Rationale**: Industry-leading cross-platform XAML framework for .NET. Provides Windows/Linux/macOS support with native rendering, excellent performance, and familiar XAML-based development model for .NET developers.
  * **Rendering Backend**: Uses Skia (SkiaSharp) for hardware-accelerated 2D graphics with consistent rendering across platforms.

### **MVVM Infrastructure**
* **CommunityToolkit.Mvvm (8.x+)**
  * **Rationale**: Modern, source-generator-based MVVM toolkit that eliminates boilerplate code. Provides `ObservableObject`, `RelayCommand`, and property change notification with minimal code.
* **ReactiveUI (19.x+)**
  * **Rationale**: Integrates seamlessly with Avalonia for reactive programming patterns. Handles complex UI state management, async workflows, and property change propagation elegantly.

### **Rendering Stack**
* **SkiaSharp (2.88.x+)**
  * **Rationale**: High-performance 2D graphics library used by Avalonia. Provides immediate-mode rendering API suitable for custom canvas drawing. Hardware-accelerated on all platforms.
  * **Use Case**: Phase 1 MVP for 2.5D layer rendering with orthographic projection.
* **Silk.NET.OpenGL / Veldrid (Post-MVP)**
  * **Rationale**: Modern .NET bindings for OpenGL/Vulkan/Metal. Enables true 3D rendering pipeline with shader support, camera controls, and advanced lighting.
  * **Use Case**: Phase 3+ for full 3D PCB visualization with perspective camera.

### **HTTP Client & Serialization**
* **System.Net.Http**
  * **Rationale**: Built-in .NET HTTP client with excellent performance, connection pooling, and async support.
* **System.Text.Json**
  * **Rationale**: High-performance JSON serializer built into .NET. Faster than Newtonsoft.Json with lower memory allocation. Source-generator support for AOT compilation.

### **Dependency Injection**
* **Microsoft.Extensions.DependencyInjection**
  * **Rationale**: Standard .NET DI container. Integrates with Avalonia's service provider pattern and supports constructor injection throughout the application.

### **State Management**
* **System.Reactive (6.x+)**
  * **Rationale**: Foundational library for reactive programming. Provides `IObservable<T>` for modeling event streams, property changes, and async data flows.

### **Logging**
* **Microsoft.Extensions.Logging**
  * **Rationale**: Standard .NET logging abstraction. Supports multiple log sinks (console, file, Application Insights) with structured logging capabilities.

### **Testing**
* **xUnit (2.x+)**
  * **Rationale**: De facto standard for .NET unit testing. Excellent parallel test execution and extensibility.
* **Moq (4.x+)**
  * **Rationale**: Flexible mocking framework for isolating dependencies in unit tests.
* **Avalonia.Headless.XUnit (11.x+)**
  * **Rationale**: Enables automated UI testing for Avalonia applications without requiring a display server.

### **Geometry & Math**
* **NetTopologySuite**
  * **Rationale**: Advanced 2D geometry library for polygon operations (union, intersection, triangulation). Critical for rendering complex surface features with holes.
* **MathNet.Numerics**
  * **Rationale**: Comprehensive numerical computing library for matrix operations, transformations, and mathematical functions needed for coordinate systems.

### **Build & Distribution**
* **dotnet CLI**
  * **Rationale**: Standard .NET build system with cross-platform support.
* **WiX Toolset (Windows)**
  * **Rationale**: Industry-standard MSI installer creation for Windows.
* **dpkg/rpm (Linux)**
  * **Rationale**: Standard package formats for Debian/Ubuntu and RedHat/Fedora distributions.
* **create-dmg (macOS)**
  * **Rationale**: Tool for creating macOS DMG installer images.

## **4. Phased Development Plan**

### **Phase 1: Foundation & MVP 2.5D Viewer (Objective: A working desktop demo)**

The goal of this phase is to build the absolute core of the application: project setup, API client, and basic 2.5D rendering with SkiaSharp in an Avalonia window.

* **Task 1.1: Project Scaffolding**
  * Initialize Git repository
  * Create Avalonia MVVM application using `dotnet new avalonia.mvvm`
  * Set up solution structure:
    ```
    BoardShapeViewClient.sln
    ├── src/
    │   ├── BoardShapeViewClient.Desktop/        # Main Avalonia app
    │   ├── BoardShapeViewClient.Core/           # Business logic, models
    │   ├── BoardShapeViewClient.Api/            # API client
    │   └── BoardShapeViewClient.Rendering/      # Rendering engine
    ├── tests/
    │   ├── BoardShapeViewClient.Core.Tests/
    │   └── BoardShapeViewClient.Rendering.Tests/
    └── docs/
    ```
  * Install core NuGet packages:
    ```bash
    dotnet add package Avalonia
    dotnet add package CommunityToolkit.Mvvm
    dotnet add package ReactiveUI
    dotnet add package SkiaSharp
    dotnet add package System.Reactive
    dotnet add package Microsoft.Extensions.DependencyInjection
    dotnet add package Microsoft.Extensions.Logging
    dotnet add package System.Text.Json
    ```

* **Task 1.2: API Client & Data Modeling**
  * Create `IOdbApiClient` interface and implementation using `HttpClient`
  * Define C# record types for ODB++ data structures (auto-generated from OpenAPI spec using NSwag or Swagger Codegen)
  * Implement API methods:
    ```csharp
    Task<FeaturesFile> GetLayerFeaturesAsync(string design, string step, string layer);
    Task<SymbolDefinition> GetSymbolAsync(string design, string symbolName);
    Task<List<string>> GetDesignsAsync();
    ```
  * Configure dependency injection for API client
  * Implement retry logic and error handling

* **Task 1.3: Basic MVVM Setup**
  * Create `MainViewModel` with CommunityToolkit.Mvvm
  * Implement `INotifyPropertyChanged` using `ObservableObject` base class
  * Create `RelayCommand` instances for user actions
  * Set up Avalonia view binding in XAML
  * Configure `ViewLocator` for ViewModel → View mapping

* **Task 1.4: Basic 2.5D Viewport with SkiaSharp**
  * Create custom Avalonia control deriving from `Control`
  * Override `Render(DrawingContext context)` method
  * Integrate SkiaSharp canvas rendering:
    ```csharp
    public override void Render(DrawingContext context)
    {
        using var lease = SkiaSharp.SKSurface.Create(...);
        var canvas = lease.Canvas;
        
        // Draw PCB features on SKCanvas
        DrawFeatures(canvas);
        
        // Present to Avalonia DrawingContext
        context.DrawImage(...);
    }
    ```
  * Implement orthographic projection with slight tilt for 2.5D effect
  * Add basic pan/zoom controls using pointer events

* **Task 1.5: Shape Rendering Engine (MVP)**
  * Create `IFeatureRenderer` interface
  * Implement renderers for essential shapes:
    * `LineRenderer`: Draws line features with width
    * `PadRenderer`: Places symbol instances (limited to circles/rectangles for MVP)
  * Create `SymbolFactory` to resolve symbol definitions
  * Handle positive/negative polarity with SKPaint blending modes

* **Deliverables**:
  * Cross-platform desktop application (Win/Linux/Mac)
  * Loads a hardcoded board design from OdbDesignServer on startup
  * Renders pads and lines in a 2.5D SkiaSharp canvas
  * User can pan and zoom the view using mouse/trackpad
  * Basic layer visibility toggle

### **Phase 2: Core Features & Advanced UI**

* **Objective**: Enhance the viewer with layer management, complete shape rendering, and polished desktop UI.
* **Tasks**:
  * Implement rendering for all ODB++ feature types (arcs, text, surfaces with NetTopologySuite triangulation)
  * Create layer panel UI using Avalonia DataGrid
  * Implement layer visibility toggles with ReactiveUI bindings
  * Add toolbar with buttons (Zoom to Fit, Export Image, Settings)
  * Implement file dialogs for opening local ODB++ archives
  * Add status bar with coordinate display and zoom level
  * Implement theming support (Light/Dark modes)
  * Add keyboard shortcuts (Ctrl+O for Open, Ctrl+Plus for Zoom In, etc.)

### **Phase 3: Interaction & 3D Visualization**

* **Objective**: Enable feature selection, property inspection, and transition to true 3D rendering.
* **Tasks**:
  * Implement raycasting for feature selection (click to select)
  * Create property inspector panel showing feature attributes
  * Add measurement tools (distance, area)
  * Integrate Silk.NET.OpenGL or Veldrid for 3D rendering
  * Implement perspective camera with orbit controls
  * Add layer stacking in 3D with proper Z-ordering
  * Implement level-of-detail (LOD) for performance optimization
  * Add visual effects (shadows, anti-aliasing, ambient occlusion)

### **Phase 4: Advanced Features & Distribution**

* **Objective**: Polish the application for production release.
* **Tasks**:
  * Implement settings persistence (user preferences, recent files)
  * Add multi-document interface (MDI) for viewing multiple boards
  * Create installer packages (MSI, DEB, DMG)
  * Implement auto-update mechanism
  * Add telemetry and crash reporting (opt-in)
  * Performance profiling and optimization
  * Comprehensive documentation (user manual, API docs)
  * Automated UI tests with Avalonia.Headless

## **5. User Stories**

### **Epic: Core Board Visualization (MVP)**

* **As a PCB designer**, I want to launch the desktop application and see a board's design rendered automatically, **so that** I can instantly verify that the API connection and rendering pipeline are working.
* **As a user**, I want to use my mouse/trackpad to pan (drag), zoom (scroll), and tilt the view of the PCB, **so that** I can inspect it from different angles and magnifications.
* **As a developer**, I want the application to fetch board data from the OdbDesignServer REST API with proper error handling, **so that** I can display real, externally-managed PCB designs reliably.
* **As a user**, I want to see the basic pads and lines of a board layer rendered in the viewport with hardware acceleration, **so that** I can understand the fundamental layout with smooth performance even on large boards.
* **As a user**, I want the application to work identically on Windows, Linux, and macOS, **so that** I can use my preferred operating system without feature limitations.

### **Epic: Layer Management**

* **As a PCB designer**, I want to see a docked panel listing all layers present in the design with checkboxes, **so that** I know what parts of the board I can inspect.
* **As a PCB designer**, I want to click a checkbox to toggle the visibility of individual layers with instant feedback, **so that** I can isolate specific parts of the design and reduce visual clutter.
* **As a user**, I want layer color indicators in the panel, **so that** I can quickly identify copper, soldermask, and silkscreen layers visually.

### **Epic: Desktop Integration**

* **As a user**, I want to open ODB++ archives from my local filesystem using native file dialogs, **so that** I can work offline without requiring server access.
* **As a user**, I want the application to remember my recently opened files, **so that** I can quickly reopen boards I'm working on.
* **As a user**, I want to export the current view as a PNG/SVG image using native save dialogs, **so that** I can include screenshots in documentation.

### **Epic: Performance & Responsiveness**

* **As a user**, I want the application to remain responsive while loading large board files (100k+ features), **so that** I can continue interacting with the UI without freezing.
* **As a user**, I want to see a progress bar when loading board data, **so that** I know the application is working and can estimate completion time.
* **As a user**, I want 60 FPS rendering performance when panning/zooming even with complex boards, **so that** the viewing experience feels fluid and professional.

## **6. Risks and Mitigations**

| Risk | Description | Mitigation Strategy |
| :---- | :---- | :---- |
| **Cross-Platform Rendering Differences** | SkiaSharp rendering may have subtle differences on Windows vs. Linux vs. macOS, leading to visual inconsistencies. | **Testing**: Implement automated visual regression tests that compare screenshots across platforms. Use Avalonia's DevTools to debug layout issues. **Fallback**: Document platform-specific quirks and provide settings to adjust rendering if needed. |
| **3D Rendering Complexity** | Transitioning from 2.5D (SkiaSharp) to true 3D (OpenGL/Vulkan) is a significant architectural change that could delay Phase 3. | **MVP Approach**: Phase 1 focuses exclusively on 2.5D with SkiaSharp. Phase 2 completes all 2D features. Only transition to 3D in Phase 3 when 2D foundation is solid. **Alternative**: Consider using existing 3D scene graph libraries like Helix Toolkit if available for .NET. |
| **Avalonia Learning Curve** | Team may be unfamiliar with Avalonia-specific patterns, slowing initial development. | **Training**: Allocate time in Task 1.1 for team to complete Avalonia tutorials. Use Avalonia samples repository as reference. **Community**: Leverage Avalonia Discord/GitHub discussions for questions. |
| **Performance with Very Large Boards** | Boards with millions of features may exhaust memory or drop frame rates even with native code. | **MVP**: Accept performance limitations for extremely large boards (>1M features). **Post-MVP**: Implement spatial indexing (quadtree), level-of-detail rendering, and geometry instancing. Use BenchmarkDotNet to identify bottlenecks. |
| **Packaging & Distribution Complexity** | Creating installers for three different platforms (MSI, DEB, DMG) requires platform-specific tooling and testing infrastructure. | **CI/CD**: Use GitHub Actions with matrix builds for Win/Linux/Mac. Automate installer creation in build pipeline. **Testing**: Manual testing on each platform required for MVP, automated UI testing added in Phase 4. |
| **API Server Unavailability** | OdbDesignServer may be unreachable, preventing data loading. | **Offline Mode**: Implement local file parsing in Phase 2 as fallback. **Error Handling**: Display user-friendly error dialogs with retry button. Implement exponential backoff for transient network failures. |
| **Polygon Triangulation Failures** | Complex surfaces with holes may fail to triangulate correctly using NetTopologySuite. | **MVP**: Defer surface rendering to Phase 2. **Validation**: Implement extensive unit tests with problematic polygon shapes from real boards. **Fallback**: Render bounding box for failed surfaces and log warning. |

## **7. Development Environment & Tooling**

### **Required Software**
* **.NET 8 SDK** (or .NET 10 for latest features)
* **Visual Studio 2022** (Windows) with .NET desktop workload
* **JetBrrains Rider** (cross-platform, excellent Avalonia support)
* **VS Code** with C# Dev Kit (lightweight alternative)
* **Git** for version control

### **Recommended Extensions**
* **Avalonia for Visual Studio** - XAML designer and IntelliSense
* **AvaloniaRider** - Rider plugin for XAML previewer
* **Avalonia XAML Intelligence** (VS Code)
* **ReSharper** (Visual Studio) - Advanced refactoring and code quality

### **CI/CD Pipeline**
```yaml
# .github/workflows/build.yml
name: Build & Test
on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [windows-latest, ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      - run: dotnet restore
      - run: dotnet build --no-restore
      - run: dotnet test --no-build --verbosity normal
      - run: dotnet publish -c Release -r ${{ matrix.os }}
```

### **Local Development Workflow**
```bash
# Clone repository
git clone https://github.com/nam20485/board-shape-view-client-dotnet.git
cd board-shape-view-client-dotnet

# Restore dependencies
dotnet restore

# Run application with hot reload
dotnet watch --project src/BoardShapeViewClient.Desktop

# Run tests in watch mode
dotnet watch test --project tests/BoardShapeViewClient.Core.Tests

# Format code
dotnet format

# Publish self-contained executable
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true
```

## **8. Project Timeline Estimates**

| Phase | Duration | Key Milestones |
|-------|----------|----------------|
| **Phase 1: Foundation & MVP** | 4-6 weeks | Working 2.5D viewer with SkiaSharp, API integration, basic layer rendering |
| **Phase 2: Core Features** | 4-6 weeks | All feature types rendered, layer panel, file dialogs, theming |
| **Phase 3: 3D Visualization** | 6-8 weeks | OpenGL/Veldrid integration, perspective camera, interactive selection |
| **Phase 4: Production Ready** | 4-6 weeks | Installers, auto-update, performance optimization, documentation |
| **Total** | 18-26 weeks | From start to production release |

**Note**: Timeline assumes a small team (2-4 developers) working part-time. Full-time development could halve these estimates.

## **9. Success Metrics**

* **Performance**: Render 100,000 features at 60 FPS on mid-range hardware
* **Startup Time**: Application launch to first render < 3 seconds
* **Memory**: Peak memory usage < 500 MB for typical boards (<50k features)
* **Cross-Platform**: Zero platform-specific bugs reported after Phase 1
* **User Adoption**: 50+ active users within first 3 months of release
* **Test Coverage**: Minimum 80% code coverage for Core and Rendering projects
* **Build Success**: CI/CD pipeline maintains >95% green build rate

## **10. Conclusion**

This development plan provides a clear roadmap for building a production-quality, cross-platform PCB viewer using modern .NET technologies. By following MVVM best practices, leveraging Avalonia's mature ecosystem, and prioritizing performance from day one, we can deliver a desktop application that significantly outperforms web-based alternatives while maintaining excellent code quality and testability.

The phased approach ensures we can deliver incremental value (MVP in Phase 1) while building toward a comprehensive solution with advanced 3D visualization and enterprise features in later phases.
