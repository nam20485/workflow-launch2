# **board-shape-view-client-dotnet: Architecture**

This document details the internal architecture of the board-shape-view-client-dotnet cross-platform desktop application built with Avalonia UI and .NET.

## **1. High-Level Architecture**

The application follows a **client-server model** with a **desktop-native client**. This architecture document focuses exclusively on the **client application**. The client is a modern .NET desktop application built with Avalonia UI, designed to run natively on Windows, Linux, and macOS. Its primary responsibilities are to fetch data from the OdbDesignServer REST API, transform that data into visual objects, and render them using hardware-accelerated graphics with a responsive, native user interface.

### **Architectural Style**
- **Pattern**: Model-View-ViewModel (MVVM) with Reactive Extensions
- **UI Framework**: Avalonia UI with XAML-based declarative UI
- **Rendering**: Hardware-accelerated 2D/3D graphics (SkiaSharp for MVP, OpenGL/Vulkan for 3D)
- **State Management**: ReactiveUI for reactive, event-driven state changes
- **Dependency Injection**: Microsoft.Extensions.DependencyInjection

## **2. Client Application Architecture**

The client is designed with a **layered, modular structure** to ensure clean separation of concerns, testability, and maintainability. The architecture follows established .NET best practices and Avalonia-specific patterns.

### **Solution Structure**

```
BoardShapeViewClient.sln
├── src/
│   ├── BoardShapeViewClient.Desktop/        # Avalonia Desktop App (entry point)
│   ├── BoardShapeViewClient.Core/           # Domain Models & Business Logic
│   ├── BoardShapeViewClient.Api/            # REST API Client
│   ├── BoardShapeViewClient.Rendering/      # Graphics Rendering Engine
│   └── BoardShapeViewClient.Services/       # Application Services
├── tests/
│   ├── BoardShapeViewClient.Core.Tests/
│   ├── BoardShapeViewClient.Api.Tests/
│   ├── BoardShapeViewClient.Rendering.Tests/
│   └── BoardShapeViewClient.Desktop.Tests/  # UI integration tests
└── docs/
    └── architecture.md (this file)
```

### **Layer Responsibilities**

#### **1. Desktop Layer** (`BoardShapeViewClient.Desktop`)
- **Responsibility**: Application entry point, view definitions, platform-specific bootstrapping
- **Technology**: Avalonia UI, XAML
- **Key Components**:
  - `App.axaml` / `App.axaml.cs`: Application configuration, dependency injection setup
  - `Views/`: XAML view files (MainWindow, LayerPanel, ToolbarView, etc.)
  - `Program.cs`: Application entry point, Avalonia builder configuration
  - `ViewLocator.cs`: ViewModel to View mapping

**Example: App.axaml.cs (Dependency Injection Setup)**
```csharp
public partial class App : Application
{
    public IServiceProvider Services { get; private set; } = null!;

    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        // Setup dependency injection
        var services = new ServiceCollection();
        ConfigureServices(services);
        Services = services.BuildServiceProvider();

        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            desktop.MainWindow = new MainWindow
            {
                DataContext = Services.GetRequiredService<MainViewModel>()
            };
        }

        base.OnFrameworkInitializationCompleted();
    }

    private void ConfigureServices(IServiceCollection services)
    {
        // API Client
        services.AddSingleton<IOdbApiClient, OdbApiClient>();
        
        // Services
        services.AddSingleton<ISymbolCache, SymbolCache>();
        services.AddSingleton<IRenderingEngine, SkiaRenderingEngine>();
        services.AddSingleton<ILayerManager, LayerManager>();
        
        // ViewModels
        services.AddTransient<MainViewModel>();
        services.AddTransient<LayerPanelViewModel>();
        services.AddTransient<BoardViewportViewModel>();
        
        // Logging
        services.AddLogging(builder =>
        {
            builder.AddConsole();
            builder.AddDebug();
        });
    }
}
```

#### **2. Core Layer** (`BoardShapeViewClient.Core`)
- **Responsibility**: Domain models, business logic, data structures
- **Technology**: Pure C# with no UI dependencies
- **Key Components**:
  - `Models/`: ODB++ data structures (`FeatureRecord`, `SymbolDefinition`, `Layer`, etc.)
  - `Interfaces/`: Service abstractions
  - `Extensions/`: Helper methods and extension methods
  - `Constants/`: Application-wide constants

**Example: Feature Model**
```csharp
namespace BoardShapeViewClient.Core.Models;

public enum FeatureType
{
    Arc = 0,
    Pad = 1,
    Surface = 2,
    Text = 4,
    Line = 5
}

public record FeatureRecord
{
    public required FeatureType Type { get; init; }
    public int? SymNum { get; init; }
    public Polarity? Polarity { get; init; }
    public int? DCode { get; init; }
    public int? Id { get; init; }
    public Dictionary<string, string>? Attributes { get; init; }
}

public record LineFeature : FeatureRecord
{
    public required double Xs { get; init; }
    public required double Ys { get; init; }
    public required double Xe { get; init; }
    public required double Ye { get; init; }
}

public record PadFeature : FeatureRecord
{
    public required double X { get; init; }
    public required double Y { get; init; }
    public int? AptDefSymbolNum { get; init; }
    public double? AptDefResizeFactor { get; init; }
}
```

#### **3. API Client Layer** (`BoardShapeViewClient.Api`)
- **Responsibility**: HTTP communication with OdbDesignServer, JSON deserialization
- **Technology**: `System.Net.Http`, `System.Text.Json`
- **Key Components**:
  - `IOdbApiClient`: Interface for API operations
  - `OdbApiClient`: HttpClient-based implementation
  - `ApiModels/`: DTO classes for API responses (auto-generated from OpenAPI)
  - `Converters/`: Custom JSON converters for ODB++ data types

**Example: API Client Interface**
```csharp
namespace BoardShapeViewClient.Api;

public interface IOdbApiClient
{
    Task<FeaturesFile> GetLayerFeaturesAsync(
        string design, 
        string step, 
        string layer, 
        CancellationToken ct = default);

    Task<SymbolDefinition> GetSymbolAsync(
        string design, 
        string symbolName, 
        CancellationToken ct = default);

    Task<List<string>> GetDesignsAsync(CancellationToken ct = default);

    Task<DesignMetadata> GetDesignMetadataAsync(
        string design, 
        CancellationToken ct = default);
}

public class OdbApiClient : IOdbApiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<OdbApiClient> _logger;
    private readonly JsonSerializerOptions _jsonOptions;

    public OdbApiClient(
        HttpClient httpClient, 
        ILogger<OdbApiClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
            Converters = { new FeatureRecordConverter() }
        };
    }

    public async Task<FeaturesFile> GetLayerFeaturesAsync(
        string design, 
        string step, 
        string layer, 
        CancellationToken ct = default)
    {
        var url = $"filemodels/{design}/steps/{step}/layers/{layer}/features";
        
        try
        {
            var response = await _httpClient.GetAsync(url, ct);
            response.EnsureSuccessStatusCode();
            
            var json = await response.Content.ReadAsStringAsync(ct);
            return JsonSerializer.Deserialize<FeaturesFile>(json, _jsonOptions)
                ?? throw new InvalidDataException("Null response from API");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Failed to fetch layer features: {Url}", url);
            throw;
        }
    }
}
```

#### **4. Rendering Layer** (`BoardShapeViewClient.Rendering`)
- **Responsibility**: Graphics rendering, geometry processing, visual representation
- **Technology**: SkiaSharp (Phase 1), Silk.NET.OpenGL (Phase 3)
- **Key Components**:
  - `IRenderingEngine`: Abstraction for rendering backend
  - `SkiaRenderingEngine`: SkiaSharp-based 2D/2.5D renderer (MVP)
  - `OpenGLRenderingEngine`: OpenGL-based 3D renderer (Post-MVP)
  - `Renderers/`: Feature-specific renderers (`LineRenderer`, `PadRenderer`, etc.)
  - `GeometryProcessors/`: Polygon triangulation, coordinate transformations
  - `Shaders/`: GLSL shader code (for OpenGL backend)

**Example: Rendering Engine Interface**
```csharp
namespace BoardShapeViewClient.Rendering;

public interface IRenderingEngine
{
    void Initialize();
    void Render(IEnumerable<FeatureRecord> features, Camera camera);
    void UpdateViewport(int width, int height);
    void Clear();
}

public class SkiaRenderingEngine : IRenderingEngine
{
    private readonly ISymbolCache _symbolCache;
    private readonly ILogger<SkiaRenderingEngine> _logger;
    private SKSurface? _surface;

    public void Render(IEnumerable<FeatureRecord> features, Camera camera)
    {
        if (_surface == null) return;
        
        var canvas = _surface.Canvas;
        canvas.Clear(SKColors.DarkGray); // Board substrate color
        
        // Apply camera transformation
        canvas.Save();
        ApplyCameraTransform(canvas, camera);
        
        // Render features by type
        foreach (var feature in features)
        {
            switch (feature.Type)
            {
                case FeatureType.Line:
                    RenderLine((LineFeature)feature, canvas);
                    break;
                case FeatureType.Pad:
                    RenderPad((PadFeature)feature, canvas);
                    break;
                // ... other types
            }
        }
        
        canvas.Restore();
    }

    private void RenderLine(LineFeature line, SKCanvas canvas)
    {
        using var paint = new SKPaint
        {
            Color = GetPolarityColor(line.Polarity),
            Style = SKPaintStyle.Stroke,
            StrokeWidth = (float)GetLineWidth(line.SymNum),
            StrokeCap = SKStrokeCap.Round,
            IsAntialias = true
        };

        canvas.DrawLine(
            (float)line.Xs, (float)line.Ys,
            (float)line.Xe, (float)line.Ye,
            paint);
    }
}
```

#### **5. Services Layer** (`BoardShapeViewClient.Services`)
- **Responsibility**: Application services, caching, state management
- **Technology**: Pure C# with reactive patterns
- **Key Components**:
  - `ISymbolCache`: Symbol definition caching service
  - `ILayerManager`: Layer visibility and ordering management
  - `IFileService`: Local file operations (ODB++ archive extraction)
  - `ISettingsService`: User preferences persistence

**Example: Symbol Cache Service**
```csharp
namespace BoardShapeViewClient.Services;

public interface ISymbolCache
{
    Task<SymbolDefinition> GetSymbolAsync(string symbolName);
    void Clear();
}

public class SymbolCache : ISymbolCache
{
    private readonly IOdbApiClient _apiClient;
    private readonly IMemoryCache _cache;
    private readonly ILogger<SymbolCache> _logger;

    public async Task<SymbolDefinition> GetSymbolAsync(string symbolName)
    {
        return await _cache.GetOrCreateAsync(
            symbolName,
            async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromMinutes(30);
                
                _logger.LogDebug("Cache miss for symbol: {Symbol}", symbolName);
                return await _apiClient.GetSymbolAsync(symbolName);
            });
    }

    public void Clear() => _cache.Clear();
}
```

### **ViewModels (MVVM Pattern)**

ViewModels bridge the gap between Views (XAML UI) and Models (domain data). They use `CommunityToolkit.Mvvm` for property change notification and command binding.

**Example: MainViewModel**
```csharp
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace BoardShapeViewClient.Desktop.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly IOdbApiClient _apiClient;
    private readonly IRenderingEngine _renderingEngine;

    [ObservableProperty]
    private string? _currentDesign;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private ObservableCollection<LayerViewModel> _layers = new();

    public MainViewModel(
        IOdbApiClient apiClient, 
        IRenderingEngine renderingEngine)
    {
        _apiClient = apiClient;
        _renderingEngine = renderingEngine;
    }

    [RelayCommand]
    private async Task LoadDesignAsync(string designName)
    {
        IsLoading = true;
        
        try
        {
            CurrentDesign = designName;
            var metadata = await _apiClient.GetDesignMetadataAsync(designName);
            
            Layers.Clear();
            foreach (var layer in metadata.Layers)
            {
                Layers.Add(new LayerViewModel(layer));
            }
        }
        catch (Exception ex)
        {
            // Show error dialog via interaction request
            _logger.LogError(ex, "Failed to load design: {Design}", designName);
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private void ZoomToFit()
    {
        // Calculate bounds and update camera
    }
}
```

**Example: LayerViewModel (with ReactiveUI)**
```csharp
using ReactiveUI;

public class LayerViewModel : ReactiveObject
{
    private bool _isVisible = true;
    public bool IsVisible
    {
        get => _isVisible;
        set => this.RaiseAndSetIfChanged(ref _isVisible, value);
    }

    private SKColor _color;
    public SKColor Color
    {
        get => _color;
        set => this.RaiseAndSetIfChanged(ref _color, value);
    }

    public string Name { get; }
    public LayerType Type { get; }

    public LayerViewModel(LayerMetadata metadata)
    {
        Name = metadata.Name;
        Type = metadata.Type;
        Color = GetDefaultLayerColor(Type);

        // React to visibility changes
        this.WhenAnyValue(x => x.IsVisible)
            .Subscribe(visible => OnVisibilityChanged(visible));
    }

    private void OnVisibilityChanged(bool visible)
    {
        // Notify rendering engine to update
        MessageBus.Current.SendMessage(new LayerVisibilityChanged(Name, visible));
    }
}
```

### **Custom Avalonia Controls**

**BoardViewportControl** - Custom control for PCB rendering

```csharp
using Avalonia;
using Avalonia.Controls;
using Avalonia.Skia;

namespace BoardShapeViewClient.Desktop.Controls;

public class BoardViewportControl : Control
{
    private readonly IRenderingEngine _renderingEngine;
    private Camera _camera = new();

    public static readonly StyledProperty<IEnumerable<FeatureRecord>?> FeaturesProperty =
        AvaloniaProperty.Register<BoardViewportControl, IEnumerable<FeatureRecord>?>(
            nameof(Features));

    public IEnumerable<FeatureRecord>? Features
    {
        get => GetValue(FeaturesProperty);
        set => SetValue(FeaturesProperty, value);
    }

    static BoardViewportControl()
    {
        AffectsRender<BoardViewportControl>(FeaturesProperty);
    }

    public override void Render(DrawingContext context)
    {
        if (Features == null) return;

        using var lease = context.PlatformImpl.CreateSkiaRenderTarget();
        var canvas = lease.SkCanvas;

        _renderingEngine.Render(Features, _camera);

        // Present rendered surface to Avalonia
        // ...
    }

    protected override void OnPointerWheelChanged(PointerWheelEventArgs e)
    {
        // Handle zoom
        _camera.Zoom *= e.Delta.Y > 0 ? 1.1 : 0.9;
        InvalidateVisual();
    }

    protected override void OnPointerPressed(PointerPressedEventArgs e)
    {
        // Start pan
    }
}
```

## **3. Data Flow**

The application follows a **unidirectional, reactive data flow** pattern:

1. **User Action** → ViewModel receives command (e.g., `LoadDesignCommand`)
2. **ViewModel** → Calls API Client service (`IOdbApiClient.GetLayerFeaturesAsync()`)
3. **API Client** → Fetches JSON from OdbDesignServer, deserializes to models
4. **ViewModel** → Updates observable properties (`Features` collection changes)
5. **View** → Avalonia data binding detects property change via `INotifyPropertyChanged`
6. **Custom Control** → `Render()` method called, passes data to rendering engine
7. **Rendering Engine** → Transforms features to geometry, draws on SkiaSharp canvas
8. **Display** → Hardware-accelerated frame presented to screen

**Reactive Example:**
```csharp
// In ViewModel
this.WhenAnyValue(x => x.SelectedLayer)
    .Where(layer => layer != null)
    .SelectMany(layer => _apiClient.GetLayerFeaturesAsync(layer.Name))
    .ObserveOn(RxApp.MainThreadScheduler)
    .Subscribe(features =>
    {
        Features = features.FeatureRecords;
    });
```

## **4. Rendering Architecture**

### **Phase 1: SkiaSharp 2D/2.5D (MVP)**

```
BoardViewportControl (Avalonia Control)
    ↓ Render(DrawingContext)
    ↓
SkiaRenderingEngine
    ↓ GetSkiaCanvas()
    ↓
FeatureRenderers (LineRenderer, PadRenderer, etc.)
    ↓ DrawLine(), DrawPad()
    ↓
SkiaSharp Canvas (SKCanvas)
    ↓ Hardware-accelerated rendering
    ↓
GPU → Display
```

**Rendering Pipeline:**
- Orthographic projection with fixed camera tilt for depth cue
- Immediate-mode rendering (redraw entire scene per frame)
- Feature culling based on viewport bounds
- Layer composition with SKPaint blend modes for polarity

### **Phase 3: OpenGL/Vulkan 3D (Post-MVP)**

```
BoardViewportControl (Avalonia + OpenGL interop)
    ↓
OpenGLRenderingEngine
    ↓
Scene Graph (Hierarchy of renderable objects)
    ↓
Vertex Buffer Objects (VBOs) - GPU-resident geometry
    ↓
Shader Programs (GLSL) - Vertex + Fragment shaders
    ↓
OpenGL Context → GPU → Display
```

**Rendering Pipeline:**
- Perspective camera with orbit controls
- Retained-mode scene graph for efficient updates
- Geometry instancing for repeated symbols (pads, vias)
- Multi-pass rendering (depth pass, lighting pass, post-processing)
- Deferred shading for complex lighting (optional)

## **5. Dependency Injection Container Configuration**

**Service Lifetimes:**

| Service | Lifetime | Rationale |
|---------|----------|-----------|
| `IOdbApiClient` | Singleton | Single HttpClient instance with connection pooling |
| `IRenderingEngine` | Singleton | Maintains GPU resources (shaders, buffers) |
| `ISymbolCache` | Singleton | Application-wide cache shared across views |
| `ILayerManager` | Singleton | Global layer state |
| `MainViewModel` | Transient | New instance per window (MDI support) |
| `LayerPanelViewModel` | Transient | Scoped to parent ViewModel |
| `ILogger<T>` | Singleton | Configured once, injected everywhere |

## **6. Testing Strategy**

### **Unit Tests** (xUnit + Moq)
```csharp
public class OdbApiClientTests
{
    [Fact]
    public async Task GetLayerFeatures_ValidRequest_ReturnsFeatures()
    {
        // Arrange
        var httpClient = new HttpClient(new MockHttpMessageHandler());
        var apiClient = new OdbApiClient(httpClient, Mock.Of<ILogger>());

        // Act
        var result = await apiClient.GetLayerFeaturesAsync("design1", "pcb", "top");

        // Assert
        Assert.NotNull(result);
        Assert.NotEmpty(result.FeatureRecords);
    }
}
```

### **UI Tests** (Avalonia.Headless.XUnit)
```csharp
[AvaloniaTheory]
public async Task LayerPanel_ToggleVisibility_UpdatesViewModel()
{
    // Arrange
    var viewModel = new LayerPanelViewModel();
    var window = new Window { DataContext = viewModel };

    // Act
    var checkbox = window.Find<CheckBox>("LayerVisibilityCheckbox");
    checkbox.IsChecked = false;

    // Assert
    Assert.False(viewModel.Layers.First().IsVisible);
}
```

## **7. Performance Considerations**

### **Optimization Strategies**

1. **Spatial Indexing**: Use quadtree for O(log n) feature lookup during rendering
2. **Geometry Instancing**: Reuse GPU buffers for identical symbols (e.g., same pad repeated 1000x)
3. **Level of Detail (LOD)**: Simplify geometry when zoomed out (reduce polygon vertex count)
4. **Frustum Culling**: Don't render features outside camera viewport
5. **Async Loading**: Stream large layer files in chunks to avoid UI freezing
6. **Lazy Evaluation**: Only fetch symbol definitions when first referenced

### **Memory Management**

```csharp
// Use structs for geometry data to reduce allocations
public readonly struct Vertex
{
    public readonly float X, Y, Z;
    public readonly byte R, G, B, A;
}

// Pool large buffers
private static readonly ArrayPool<Vertex> _vertexPool = ArrayPool<Vertex>.Create();

public void RenderSurface(SurfaceFeature surface)
{
    var vertices = _vertexPool.Rent(surface.VertexCount);
    try
    {
        // Use rented array
        TriangulatePolygon(surface, vertices);
        DrawTriangles(vertices);
    }
    finally
    {
        _vertexPool.Return(vertices);
    }
}
```

## **8. Future Extensibility**

The architecture is designed to support future enhancements:

- **Plugin System**: Load custom feature renderers via MEF or similar
- **Scripting**: Expose API for automation via C# scripting (Roslyn) or Python.NET
- **Cloud Integration**: Add Azure/AWS backends for design storage
- **Collaboration**: Real-time multi-user viewing with SignalR
- **VR/AR Support**: Extend rendering engine for Oculus/HoloLens

---

This architecture provides a solid, scalable foundation for a high-performance, cross-platform PCB viewer with clear separation of concerns, testability, and maintainability. The layered design allows parallel development of UI, API, and rendering components while maintaining strict interface boundaries.
