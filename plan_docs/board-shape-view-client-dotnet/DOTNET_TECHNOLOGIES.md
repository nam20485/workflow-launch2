# .NET Technologies for board-shape-view-client-dotnet

This document provides a comprehensive list of .NET technologies, libraries, and tools required for implementing the board-shape-view-client as a cross-platform desktop application.

---

## Core Framework

### .NET Runtime & SDK
- **.NET 8.0 LTS** (recommended) or **.NET 9.0**
  - C# 12+ language features
  - Improved performance (PGO, native AOT support)
  - Cross-platform runtime (Windows, Linux, macOS)

---

## UI Framework Stack

### Primary UI Framework
- **Avalonia UI 11.x+**
  - Cross-platform XAML-based UI framework
  - Native rendering on Win/Linux/Mac
  - Skia-based graphics backend
  - Supports MVVM pattern natively

### MVVM Infrastructure
- **CommunityToolkit.Mvvm 8.x+**
  - Source generator-based MVVM toolkit
  - `ObservableObject`, `RelayCommand`, `ObservableProperty`
  - Reduces boilerplate code significantly
  - Alternative: ReactiveUI (more advanced, steeper learning curve)

- **ReactiveUI 19.x+**
  - Reactive programming framework
  - Integrates with Avalonia
  - Excellent for complex UI state management
  - Provides `WhenAnyValue()`, `ReactiveCommand`, etc.

### Reactive Extensions
- **System.Reactive 6.x+**
  - `IObservable<T>` and LINQ operators
  - Foundation for ReactiveUI
  - Event stream processing

---

## Rendering & Graphics

### 2D/2.5D Rendering (Phase 1 MVP)
**Option 3: Helix Toolkit**
- 3D graphics toolkit for WPF/UWP
- Full Avalonia support
- Good for rapid prototyping

**Platform-Specific Assets:**
- **SkiaSharp.NativeAssets.Linux** (for Linux GPU acceleration)
- **SkiaSharp.NativeAssets.macOS** (for Metal backend on macOS)

### 3D Rendering (Phase 3)
**Option 3: Helix Toolkit**
- 3D graphics toolkit for WPF/UWP
- Full Avalonia support
- Good for rapid prototyping

**Recommendation for Production:** Helix Toolkit for ease of use and integration with Avalonia

---

## HTTP & API Communication

### HTTP Client
- **System.Net.Http** (built-in)
  - `HttpClient` with connection pooling
  - Async/await support
  - Polly integration for resilience

### Resilience & Retry Logic
- **Polly 8.x+**
  - Retry, circuit breaker, timeout policies
  - Integrates with `HttpClient` via DI

### JSON Serialization
- **System.Text.Json** (built-in)
  - High-performance JSON parser
  - Source generator support for AOT
  - Lower memory allocation than Newtonsoft.Json
  - Native support for `snake_case` property naming

**Custom Converters:**
```csharp
// For handling ODB++ numeric type fields (0-5)
public class FeatureTypeConverter : JsonConverter<FeatureType> { }
```

---

## Geometry & Mathematics

### Polygon Operations
- **NetTopologySuite (NTS)**
  - 2D geometry library (JTS port)
  - Polygon union, intersection, difference
  - Triangulation for rendering surfaces
  - Spatial indexing (quadtree, R-tree)
  - Critical for ODB++ surface features with holes

### Numerical Computing
- **MathNet.Numerics**
  - Linear algebra (matrices, vectors)
  - Coordinate transformations
  - Affine transformations for orientation modes
  - Statistical functions (optional)

**Example Usage:**
```csharp
using MathNet.Numerics.LinearAlgebra;

var transform = Matrix<double>.Build.Dense(3, 3);
transform[0, 0] = Math.Cos(angle);
transform[0, 1] = -Math.Sin(angle);
// ... apply to feature coordinates
```

---

## Dependency Injection & Configuration

### Dependency Injection
- **Microsoft.Extensions.DependencyInjection** (built-in)
  - Standard .NET DI container
  - Service lifetimes: Singleton, Scoped, Transient
  - Constructor injection

### Configuration
- **Microsoft.Extensions.Configuration** (built-in)
  - `appsettings.json` support
  - Environment-specific configs (`appsettings.Development.json`)
  - Command-line arguments, environment variables

- **Microsoft.Extensions.Options**
  - Strongly-typed configuration classes
  - Options pattern with validation

**Example:**
```csharp
// appsettings.json
{
  "ApiSettings": {
    "BaseUrl": "http://localhost:8888",
    "Timeout": 30
  }
}

// Configuration class
public class ApiSettings
{
    public string BaseUrl { get; set; }
    public int Timeout { get; set; }
}

// Startup
services.Configure<ApiSettings>(configuration.GetSection("ApiSettings"));
```

---

## Caching & Performance

### In-Memory Caching
- **Microsoft.Extensions.Caching.Memory** (built-in)
  - LRU cache with expiration policies
  - Used for symbol definitions, standard lookups

**Example:**
```csharp
public class SymbolCache
{
    private readonly IMemoryCache _cache;
    
    public async Task<Symbol> GetSymbolAsync(string name)
    {
        return await _cache.GetOrCreateAsync(name, async entry =>
        {
            entry.SlidingExpiration = TimeSpan.FromMinutes(30);
            return await FetchSymbolFromApiAsync(name);
        });
    }
}
```

### Distributed Caching (Optional)
- **Microsoft.Extensions.Caching.StackExchangeRedis**
  - For multi-instance deployments (future cloud version)

---

## Validation & Data Quality

### Input Validation
- **FluentValidation 11.x+**
  - Fluent API for validation rules
  - Integrates with ASP.NET Core and MVVM

**Example:**
```csharp
public class FeatureRecordValidator : AbstractValidator<FeatureRecord>
{
    public FeatureRecordValidator()
    {
        RuleFor(x => x.Type)
            .IsInEnum()
            .WithMessage("Invalid feature type");
        
        RuleFor(x => x.Polarity)
            .NotNull()
            .Must(p => p == Polarity.Positive || p == Polarity.Negative);
    }
}
```

---

## Logging & Diagnostics

### Logging Framework
- **Microsoft.Extensions.Logging** (built-in)
  - Abstraction over multiple logging providers
  - Structured logging support

### Log Providers
- **Serilog** (recommended)
  - Rich structured logging
  - Multiple sinks (console, file, Seq, Application Insights)
  - Excellent for diagnostics

**Example Configuration:**
```csharp
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .WriteTo.Console()
    .WriteTo.File("logs/app-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

services.AddLogging(builder => builder.AddSerilog());
```

### Performance Profiling
- **dotnet-trace** (built-in)
  - CPU and memory profiling
  - ETW event tracing

- **BenchmarkDotNet**
  - Micro-benchmarking library
  - Identify rendering bottlenecks

---

## File I/O & Compression

### File System
- **System.IO** (built-in)
  - File, Directory, Path classes

### Compression
- **System.IO.Compression** (built-in)
  - ZIP archive support for ODB++ `.tgz` extraction
  - `ZipArchive` class

**Example:**
```csharp
using (var archive = ZipFile.OpenRead("design.tgz"))
{
    foreach (var entry in archive.Entries)
    {
        if (entry.FullName.EndsWith("/features"))
        {
            entry.ExtractToFile(Path.Combine(outputPath, entry.Name));
        }
    }
}
```

---

## Testing Frameworks

### Unit Testing
- **xUnit 2.x+**
  - De facto standard for .NET
  - Parallel test execution
  - Theory-based data-driven tests

### Mocking
- **Moq 4.x+**
  - Flexible mocking framework
  - Mock interfaces and virtual methods

**Example:**
```csharp
[Fact]
public async Task GetLayerFeatures_Returns_Features()
{
    // Arrange
    var mockClient = new Mock<IOdbApiClient>();
    mockClient
        .Setup(x => x.GetLayerFeaturesAsync("design1", "pcb", "top", default))
        .ReturnsAsync(new FeaturesFile { NumFeatures = 100 });
    
    // Act
    var result = await mockClient.Object.GetLayerFeaturesAsync("design1", "pcb", "top");
    
    // Assert
    Assert.Equal(100, result.NumFeatures);
}
```

### UI Testing
- **Avalonia.Headless.XUnit 11.x+**
  - Headless UI testing for Avalonia
  - No display server required
  - Automated UI integration tests

**Example:**
```csharp
[AvaloniaFact]
public void LayerCheckbox_Toggle_Updates_ViewModel()
{
    // Arrange
    var window = new MainWindow { DataContext = new MainViewModel() };
    
    // Act
    var checkbox = window.Find<CheckBox>("LayerVisibilityCheckbox");
    checkbox.IsChecked = false;
    
    // Assert
    var vm = (MainViewModel)window.DataContext;
    Assert.False(vm.Layers.First().IsVisible);
}
```

### Code Coverage
- **coverlet**
  - Cross-platform code coverage
  - Integrates with xUnit

```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

---

## Build & Packaging Tools

### Build System
- **dotnet CLI** (built-in)
  - `dotnet build`, `dotnet publish`
  - Cross-platform builds

### Platform-Specific Packaging

#### Windows
- **WiX Toolset 4.x**
  - MSI installer creation
  - Custom UI, registry keys, shortcuts

**Alternative:** Advanced Installer, Inno Setup

#### Linux
- **dpkg** (Debian/Ubuntu)
  - `.deb` package creation
- **rpm** (RedHat/Fedora)
  - `.rpm` package creation

**Tool:** `dotnet-deb` or manual `.deb` creation with control files

#### macOS
- **create-dmg**
  - DMG installer creation
  - App bundle packaging

### Self-Contained Deployment
```bash
# Publish single-file executable (includes .NET runtime)
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true

# AOT compilation (optional, .NET 8+)
dotnet publish -c Release -r linux-x64 /p:PublishAot=true
```

---

## Development Tools & Extensions

### IDEs
- **Visual Studio 2022** (Windows)
  - Best Avalonia XAML designer support
  - Excellent debugging experience

- **JetBrains Rider** (cross-platform)
  - Superior Avalonia support via AvaloniaRider plugin
  - Advanced refactoring tools

- **Visual Studio Code** (lightweight)
  - C# Dev Kit extension
  - Avalonia XAML Intelligence extension

### Extensions & Plugins
- **Avalonia for Visual Studio** - XAML IntelliSense and previewer
- **AvaloniaRider** - Rider plugin for XAML editing
- **ReSharper** (Visual Studio) - Code quality and refactoring
- **dotnet-format** - Code style enforcement

### Hot Reload
```bash
dotnet watch --project src/BoardShapeViewClient.Desktop
```

---

## CI/CD & DevOps

### Continuous Integration
- **GitHub Actions**
  - Matrix builds for Win/Linux/Mac
  - Automated testing

**Example Workflow:**
```yaml
name: CI
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
      - run: dotnet test
      - run: dotnet publish -c Release
```

### Static Code Analysis
- **Roslyn Analyzers**
  - Built-in C# code analysis
- **SonarCloud** / **SonarQube**
  - Code quality and security scanning

---

## Optional Enhancements

### Advanced UI Components
- **Avalonia.Controls.DataGrid**
  - Data grid control for layer panel
- **LiveChartsCore**
  - Charting library (performance metrics, statistics)

### Internationalization
- **Microsoft.Extensions.Localization**
  - Resource files for multi-language support

### Advanced Async
- **System.Threading.Channels**
  - Async data pipelines (producer-consumer patterns)
  - Useful for streaming large layer files

### ORM (if adding database)
- **Entity Framework Core**
  - For local SQLite database (design cache, recent files)

---

## Recommended Starter NuGet Packages

```xml
<ItemGroup>
  <!-- UI Framework -->
  <PackageReference Include="Avalonia" Version="11.0.*" />
  <PackageReference Include="Avalonia.Desktop" Version="11.0.*" />
  <PackageReference Include="Avalonia.Themes.Fluent" Version="11.0.*" />
  
  <!-- MVVM -->
  <PackageReference Include="CommunityToolkit.Mvvm" Version="8.2.*" />
  <PackageReference Include="ReactiveUI" Version="19.5.*" />
  
  <!-- Rendering -->
  <PackageReference Include="SkiaSharp" Version="2.88.*" />
  
  <!-- Geometry -->
  <PackageReference Include="NetTopologySuite" Version="2.5.*" />
  <PackageReference Include="MathNet.Numerics" Version="5.0.*" />
  
  <!-- Configuration -->
  <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.*" />
  <PackageReference Include="Microsoft.Extensions.Options" Version="8.0.*" />
  
  <!-- Caching -->
  <PackageReference Include="Microsoft.Extensions.Caching.Memory" Version="8.0.*" />
  
  <!-- Logging -->
  <PackageReference Include="Serilog" Version="3.1.*" />
  <PackageReference Include="Serilog.Extensions.Logging" Version="8.0.*" />
  <PackageReference Include="Serilog.Sinks.Console" Version="5.0.*" />
  <PackageReference Include="Serilog.Sinks.File" Version="5.0.*" />
  
  <!-- Validation -->
  <PackageReference Include="FluentValidation" Version="11.9.*" />
  
  <!-- Testing -->
  <PackageReference Include="xunit" Version="2.6.*" />
  <PackageReference Include="Moq" Version="4.20.*" />
  <PackageReference Include="Avalonia.Headless.XUnit" Version="11.0.*" />
  <PackageReference Include="coverlet.collector" Version="6.0.*" />
</ItemGroup>
```

---

## Summary: Core vs. Optional Technologies

### Core (Required for MVP)
✅ .NET 8 SDK  
✅ Avalonia UI  
✅ CommunityToolkit.Mvvm OR ReactiveUI  
✅ SkiaSharp  
✅ System.Net.Http  
✅ System.Text.Json  
✅ Microsoft.Extensions.DependencyInjection  
✅ xUnit + Moq  

### Important (Highly Recommended)
⭐ NetTopologySuite (for surface rendering)  
⭐ MathNet.Numerics (for transformations)  
⭐ Microsoft.Extensions.Caching.Memory (symbol cache)  
⭐ Serilog (logging)  
⭐ FluentValidation (data quality)  

### Optional (Post-MVP)
🔹 Silk.NET.OpenGL / Veldrid (3D rendering)  
🔹 Polly (resilience)  
🔹 BenchmarkDotNet (profiling)  
🔹 LiveChartsCore (charting)  
🔹 Entity Framework Core (local database)  

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Target Framework:** .NET 8.0 LTS
