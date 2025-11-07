# **New Application: board-shape-view-client-dotnet**

|  |  |
| :---- | :---- |
| **App Title** | board-shape-view-client-dotnet |
| **Development Plan** | [development\_plan.md](https://www.google.com/search?q=development_plan.md) |
| **Architecture Doc** | [architecture.md](http://docs.google.com/architecture.md) |

## **Description**

### **Overview**

board-shape-view-client-dotnet is a cross-platform desktop application designed to visualize 2D/3D Printed Circuit Board (PCB) designs. Built with Avalonia UI and .NET 8+, it runs natively on Windows, Linux, and macOS. The application operates in a client-server architecture, where the client is responsible for fetching parsed ODB++ design data from the existing OdbDesignServer REST API. The client then renders this data visually using hardware-accelerated 2D/3D graphics, allowing users to inspect the PCB layout with interactive pan, zoom, and rotate controls. The primary goal is to provide a high-performance, native desktop tool for PCB visualization with superior rendering quality compared to web-based solutions.

### **Document Links**

| Document | Link |
| :---- | :---- |
| **User Stories** | [development\_plan.md\#5-user-stories](https://www.google.com/search?q=development_plan.md%235-user-stories) |
| **Swagger/OpenAPI** | [OdbDesignServer v0.9 OpenAPI Spec](https://github.com/nam20485/OdbDesign/blob/development/swagger/odbdesign-server-0.9-swagger.yaml) |
| **Containerization** | Not applicable for desktop application. Installation packages (MSI, DEB, DMG) will be created for distribution. |
| **Acceptance Criteria** | See User Stories in the Development Plan. A story is complete when its described functionality is implemented and verifiable. |

## **Technology Stack**

| Category | Technology | Version / Details |
| :---- | :---- | :---- |
| **Language** | C# | 12+ (.NET 8/9) |
| **Framework** | .NET | 8.0+ (LTS) or 9.0 |
| **UI Framework** | Avalonia UI | 11.x+ |
| **MVVM Toolkit** | CommunityToolkit.Mvvm | 8.x+ |
| **3D Rendering** | SkiaSharp | 2.88.x+ (2D/2.5D canvas) |
| **3D Rendering (Future)** | Silk.NET.OpenGL / Veldrid | For true 3D visualization |
| **HTTP Client** | System.Net.Http | Built-in .NET |
| **JSON Serialization** | System.Text.Json | Built-in .NET |
| **Dependency Injection** | Microsoft.Extensions.DependencyInjection | Built-in .NET |
| **Reactive Extensions** | System.Reactive | 6.x+ |
| **State Management** | ReactiveUI | 19.x+ (integrates with Avalonia) |
| **Logging** | Microsoft.Extensions.Logging | Built-in .NET |
| **Testing Framework** | xUnit | 2.x+ |
| **Mocking** | Moq | 4.x+ |
| **UI Testing** | Avalonia.Headless.XUnit | 11.x+ |

## **Additional .NET Technologies**

### **Essential Libraries**

| Category | Library | Purpose |
| :---- | :---- | :---- |
| **Geometry Processing** | NetTopologySuite | Polygon operations, spatial indexing |
| **Numerical Computing** | MathNet.Numerics | Matrix transformations, linear algebra |
| **Configuration** | Microsoft.Extensions.Configuration | appsettings.json support |
| **Options Pattern** | Microsoft.Extensions.Options | Strongly-typed configuration |
| **Validation** | FluentValidation | Input/data validation |
| **Caching** | Microsoft.Extensions.Caching.Memory | In-memory caching for symbols/standards |
| **Compression** | System.IO.Compression | ODB++ archive extraction |
| **Async/Threading** | System.Threading.Channels | Async data pipelines |

### **UI Enhancement**

| Category | Library | Purpose |
| :---- | :---- | :---- |
| **Icons** | Avalonia.Controls.DataGrid | DataGrid control for layer panels |
| **Dialogs** | Avalonia.Dialogs | Native file/folder dialogs |
| **Themes** | Avalonia.Themes.Fluent | Modern Fluent Design UI |
| **Animations** | Avalonia.Animation | Smooth UI transitions |
| **Charts** | LiveChartsCore | Performance metrics visualization (optional) |

### **Development Tools**

| Category | Tool | Purpose |
| :---- | :---- | :---- |
| **Code Analysis** | Microsoft.CodeAnalysis.CSharp | Roslyn analyzers |
| **Formatting** | dotnet-format | Code style enforcement |
| **Hot Reload** | dotnet watch | Live reload during development |
| **Profiling** | dotnet-trace | Performance profiling |
| **Coverage** | coverlet | Code coverage analysis |
| **Benchmarking** | BenchmarkDotNet | Performance benchmarking |

### **Platform-Specific**

| Platform | Libraries | Purpose |
| :---- | :---- | :---- |
| **Windows** | System.Drawing.Common | Windows-specific rendering optimizations |
| **Linux** | SkiaSharp.NativeAssets.Linux | Hardware acceleration on Linux |
| **macOS** | SkiaSharp.NativeAssets.macOS | Metal backend support |

### **Packaging & Distribution**

| Target | Tool | Output Format |
| :---- | :---- | :---- |
| **Windows** | dotnet publish + WiX Toolset | MSI installer |
| **Linux** | dotnet publish + dpkg / rpm | DEB/RPM packages |
| **macOS** | dotnet publish + create-dmg | DMG installer |
| **Cross-platform** | dotnet publish | Self-contained single-file executable |

## **Architecture Highlights**

### **MVVM Pattern with CommunityToolkit**
- **ViewModels**: Business logic and state management using `ObservableObject` and `RelayCommand`
- **Views**: XAML-based Avalonia UI with data binding
- **Models**: ODB++ data structures and API client models
- **Services**: API communication, rendering, state management

### **Rendering Pipeline**
1. **2D/2.5D (MVP)**: SkiaSharp with Avalonia integration
   - Hardware-accelerated 2D canvas rendering
   - Immediate mode drawing with retained-mode caching
   - Suitable for layer visualization with depth cues

2. **3D (Post-MVP)**: Silk.NET.OpenGL or Veldrid
   - True 3D scene graph
   - Shader-based rendering pipeline
   - Camera controls (orbit, pan, zoom)
   - GPU instancing for repeated symbols

### **Dependency Injection**
```csharp
services.AddSingleton<IOdbApiClient, OdbApiClient>();
services.AddSingleton<ISymbolCache, SymbolCache>();
services.AddTransient<MainViewModel>();
services.AddTransient<LayerPanelViewModel>();
```

### **Reactive State Management**
```csharp
// Example: Layer visibility toggle
this.WhenAnyValue(x => x.IsLayerVisible)
    .Subscribe(visible => UpdateLayerRender(visible));
```

## **Project & Delivery**

|  |  |
| :---- | :---- |
| **Project Structure** | Solution with Desktop project + Class Libraries (Core, API, Rendering) |
| **GitHub Repo** | https://github.com/nam20485/board-shape-view-client-dotnet (to be created) |
| **Branch** | development |
| **Deliverables** | Installer packages (MSI/DEB/DMG), self-contained executables, NuGet packages for reusable components |

## **Why .NET/Avalonia over Web?**

### **Advantages**
- **Native Performance**: 5-10x faster rendering compared to browser canvas
- **Hardware Access**: Direct GPU acceleration, better memory management
- **Offline-First**: No web server required for local file viewing
- **Superior UX**: Native file dialogs, OS integration, multi-window support
- **Advanced Graphics**: Easier integration with OpenGL/Vulkan for 3D
- **Enterprise Ready**: Better security, licensing control, no CORS issues

### **Trade-offs**
- **Installation Required**: Users must install vs. instant web access
- **Platform Builds**: Separate builds/testing for Win/Linux/Mac
- **Update Distribution**: MSI/DMG updates vs. automatic web updates
- **Bundle Size**: ~50-100 MB installers vs. ~2 MB web app

## **Development Environment Setup**

### **Prerequisites**
- .NET 8 SDK or later
- Visual Studio 2022 / JetBrains Rider / VS Code with C# Dev Kit
- Git

### **Recommended Extensions**
- Avalonia XAML Intelligence
- C# Dev Kit (VS Code)
- ReSharper (Visual Studio)

### **Getting Started**
```bash
# Clone repository
git clone https://github.com/nam20485/board-shape-view-client-dotnet.git
cd board-shape-view-client-dotnet

# Restore dependencies
dotnet restore

# Run application
dotnet run --project src/BoardShapeViewClient.Desktop

# Run tests
dotnet test

# Build release package
dotnet publish -c Release -r win-x64 --self-contained
```

## **Next Steps**
1. Review Development Plan for phased implementation strategy
2. Review Architecture document for detailed system design
3. Set up development environment
4. Implement Phase 1: Foundation & MVP 2.5D Viewer
