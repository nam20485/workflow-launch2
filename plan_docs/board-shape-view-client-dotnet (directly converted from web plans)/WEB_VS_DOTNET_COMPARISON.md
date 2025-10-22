# Technology Stack Comparison: Web vs. .NET Desktop

This document compares the technology stacks for the **web-based (React/TypeScript)** and **.NET desktop (Avalonia/C#)** versions of board-shape-view-client.

---

## Quick Comparison Table

| Aspect | Web (React/TypeScript) | Desktop (.NET/Avalonia) |
|--------|------------------------|-------------------------|
| **Primary Language** | TypeScript 5.x | C# 12+ |
| **Framework** | React 18.x | Avalonia UI 11.x |
| **Runtime** | Browser (Chrome, Firefox, Safari) | .NET 8/9 CLR |
| **UI Paradigm** | Component-based (JSX) | XAML-based MVVM |
| **State Management** | Zustand | ReactiveUI + CommunityToolkit.Mvvm |
| **3D Rendering** | Three.js + React Three Fiber | SkiaSharp (2D) → Silk.NET.OpenGL (3D) |
| **Build Tool** | Vite | dotnet CLI |
| **Package Manager** | npm/yarn | NuGet |
| **Deployment** | Static hosting (Netlify, Vercel) | MSI/DEB/DMG installers |
| **Installation** | None (browser-based) | Required (~50-100 MB) |
| **Performance** | Good (60 FPS for <50k features) | Excellent (60 FPS for 100k+ features) |
| **Startup Time** | < 1 second | 2-3 seconds |
| **Memory Usage** | 200-500 MB (browser overhead) | 150-300 MB (native) |
| **Offline Support** | Limited (requires PWA) | Full (native file access) |
| **Auto-Update** | Automatic (on refresh) | Requires update mechanism |
| **Cross-Platform** | Any modern browser | Win/Linux/Mac (separate builds) |
| **Development Complexity** | Lower learning curve | Higher (MVVM, .NET ecosystem) |
| **Testing** | Jest, React Testing Library | xUnit, Moq, Avalonia.Headless |

---

## Technology Mappings

### UI Framework
| Web | .NET | Notes |
|-----|------|-------|
| React 18.x | Avalonia UI 11.x | Both use declarative UI (JSX vs. XAML) |
| React Hooks | ReactiveUI / CommunityToolkit.Mvvm | State management patterns |
| CSS / Tailwind | Avalonia Styles / XAML | Styling approaches differ significantly |

### State Management
| Web | .NET | Notes |
|-----|------|-------|
| Zustand | ReactiveUI | Reactive state management |
| React Context | Dependency Injection (DI) | Sharing state across components |
| useState / useEffect | ObservableProperty / WhenAnyValue | Property change notification |

### 3D Rendering
| Web | .NET | Notes |
|-----|------|-------|
| Three.js | Silk.NET.OpenGL / Veldrid | Raw OpenGL bindings vs. scene graph library |
| React Three Fiber | Custom Avalonia control | Integration layer |
| WebGL | OpenGL 3.3+ / Vulkan / Metal | Underlying graphics APIs |
| Canvas API (2D) | SkiaSharp | 2D rendering fallback |

### HTTP & API
| Web | .NET | Notes |
|-----|------|-------|
| Axios | System.Net.Http (HttpClient) | HTTP client libraries |
| fetch API | HttpClient | Native browser vs. .NET API |
| JSON.parse() | System.Text.Json | JSON deserialization |

### Geometry & Math
| Web | .NET | Notes |
|-----|------|-------|
| (Manual implementation) | NetTopologySuite | Polygon operations, triangulation |
| Math.* | MathNet.Numerics | Matrix operations, linear algebra |
| JSTS (optional) | NTS | Java Topology Suite ports |

### Build & Packaging
| Web | .NET | Notes |
|-----|------|-------|
| Vite | dotnet CLI | Build systems |
| npm/yarn | NuGet | Package managers |
| Docker | Docker (same) | Containerization (optional) |
| Static files (HTML/JS/CSS) | Self-contained executable | Deployment artifacts |

### Testing
| Web | .NET | Notes |
|-----|------|-------|
| Jest | xUnit | Unit test frameworks |
| React Testing Library | Avalonia.Headless.XUnit | UI component testing |
| Cypress / Playwright | (Same, or Selenium) | End-to-end testing |

---

## Detailed Comparisons

### 1. UI Development Model

#### Web (React/TypeScript)
```tsx
// Component-based with JSX
export function LayerPanel({ layers, onToggle }) {
  const [selected, setSelected] = useState<Layer | null>(null);
  
  return (
    <div className="layer-panel">
      {layers.map(layer => (
        <div key={layer.name}>
          <input
            type="checkbox"
            checked={layer.isVisible}
            onChange={() => onToggle(layer)}
          />
          <span>{layer.name}</span>
        </div>
      ))}
    </div>
  );
}
```

#### .NET (Avalonia/C#)
```xml
<!-- XAML-based declarative UI -->
<UserControl xmlns="https://github.com/avaloniaui">
  <StackPanel>
    <ItemsControl Items="{Binding Layers}">
      <ItemsControl.ItemTemplate>
        <DataTemplate>
          <StackPanel Orientation="Horizontal">
            <CheckBox IsChecked="{Binding IsVisible}" />
            <TextBlock Text="{Binding Name}" />
          </StackPanel>
        </DataTemplate>
      </ItemsControl.ItemTemplate>
    </ItemsControl>
  </StackPanel>
</UserControl>
```

```csharp
// ViewModel with data binding
public partial class LayerPanelViewModel : ObservableObject
{
    [ObservableProperty]
    private ObservableCollection<LayerViewModel> _layers = new();
}

public partial class LayerViewModel : ObservableObject
{
    [ObservableProperty]
    private bool _isVisible = true;
    
    [ObservableProperty]
    private string _name = "";
}
```

**Key Difference:** React uses component props and hooks; Avalonia uses XAML data binding with ViewModels.

---

### 2. 3D Rendering Pipeline

#### Web (Three.js + React Three Fiber)
```tsx
import { Canvas } from '@react-three/fiber';
import { OrbitControls } from '@react-three/drei';

export function BoardViewer({ features }) {
  return (
    <Canvas camera={{ position: [0, 0, 10] }}>
      <OrbitControls />
      <ambientLight intensity={0.5} />
      
      {features.map(feature => (
        <FeatureMesh key={feature.id} feature={feature} />
      ))}
    </Canvas>
  );
}

function FeatureMesh({ feature }) {
  return (
    <mesh position={[feature.x, feature.y, 0]}>
      <boxGeometry args={[feature.width, feature.height, 0.1]} />
      <meshStandardMaterial color="orange" />
    </mesh>
  );
}
```

#### .NET (SkiaSharp → Silk.NET.OpenGL)

**Phase 1 (SkiaSharp):**
```csharp
public override void Render(DrawingContext context)
{
    using var lease = SkiaSharp.SKSurface.Create(...);
    var canvas = lease.Canvas;
    
    foreach (var feature in Features)
    {
        RenderFeature(canvas, feature);
    }
}

private void RenderFeature(SKCanvas canvas, FeatureRecord feature)
{
    using var paint = new SKPaint { Color = SKColors.Orange };
    
    if (feature is PadFeature pad)
    {
        canvas.DrawCircle((float)pad.X, (float)pad.Y, 5f, paint);
    }
}
```

**Phase 3 (Silk.NET.OpenGL):**
```csharp
public void Render()
{
    GL.Clear(ClearBufferMask.ColorBufferBit | ClearBufferMask.DepthBufferBit);
    
    _shader.Use();
    _shader.SetMatrix4("view", _camera.GetViewMatrix());
    _shader.SetMatrix4("projection", _camera.GetProjectionMatrix());
    
    foreach (var batch in _featureBatches)
    {
        GL.BindVertexArray(batch.VAO);
        GL.DrawElementsInstanced(
            PrimitiveType.Triangles,
            batch.IndexCount,
            DrawElementsType.UnsignedInt,
            IntPtr.Zero,
            batch.InstanceCount);
    }
}
```

**Key Difference:** Web uses high-level scene graph (Three.js); .NET MVP uses immediate-mode 2D (SkiaSharp), transitioning to low-level OpenGL for 3D.

---

### 3. State Management

#### Web (Zustand)
```typescript
import create from 'zustand';

interface BoardState {
  layers: Layer[];
  toggleLayer: (layerName: string) => void;
}

export const useBoardStore = create<BoardState>((set) => ({
  layers: [],
  
  toggleLayer: (layerName) => set((state) => ({
    layers: state.layers.map(layer =>
      layer.name === layerName
        ? { ...layer, isVisible: !layer.isVisible }
        : layer
    )
  }))
}));

// Usage in component
function LayerPanel() {
  const { layers, toggleLayer } = useBoardStore();
  // ...
}
```

#### .NET (ReactiveUI + CommunityToolkit.Mvvm)
```csharp
public partial class BoardViewModel : ObservableObject
{
    [ObservableProperty]
    private ObservableCollection<LayerViewModel> _layers = new();
    
    [RelayCommand]
    private void ToggleLayer(LayerViewModel layer)
    {
        layer.IsVisible = !layer.IsVisible;
    }
}

public partial class LayerViewModel : ReactiveObject
{
    private bool _isVisible = true;
    public bool IsVisible
    {
        get => _isVisible;
        set => this.RaiseAndSetIfChanged(ref _isVisible, value);
    }
    
    // Alternative with CommunityToolkit.Mvvm
    [ObservableProperty]
    private bool _isVisible = true;
}

// Usage with reactive subscriptions
this.WhenAnyValue(x => x.IsVisible)
    .Subscribe(visible => OnVisibilityChanged(visible));
```

**Key Difference:** Web uses store with immutable updates; .NET uses observable properties with change notification.

---

### 4. API Client Implementation

#### Web (Axios)
```typescript
import axios from 'axios';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: {
    'Authorization': 'Basic ' + btoa(`${username}:${password}`)
  }
});

export async function getLayerFeatures(
  design: string,
  step: string,
  layer: string
): Promise<FeaturesFile> {
  const response = await apiClient.get(
    `/filemodels/${design}/steps/${step}/layers/${layer}/features`
  );
  return response.data;
}
```

#### .NET (HttpClient + System.Text.Json)
```csharp
public class OdbApiClient : IOdbApiClient
{
    private readonly HttpClient _httpClient;
    private readonly JsonSerializerOptions _jsonOptions;
    
    public OdbApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri("http://localhost:8888");
        
        var credentials = Convert.ToBase64String(
            Encoding.ASCII.GetBytes($"{username}:{password}"));
        _httpClient.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Basic", credentials);
        
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower
        };
    }
    
    public async Task<FeaturesFile> GetLayerFeaturesAsync(
        string design,
        string step,
        string layer,
        CancellationToken ct = default)
    {
        var response = await _httpClient.GetAsync(
            $"filemodels/{design}/steps/{step}/layers/{layer}/features",
            ct);
        
        response.EnsureSuccessStatusCode();
        
        return await JsonSerializer.DeserializeAsync<FeaturesFile>(
            await response.Content.ReadAsStreamAsync(ct),
            _jsonOptions,
            ct) ?? throw new InvalidDataException();
    }
}
```

**Key Difference:** Similar patterns, but .NET uses `HttpClient` with DI and `System.Text.Json` for deserialization.

---

### 5. Testing Approach

#### Web (Jest + React Testing Library)
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { LayerPanel } from './LayerPanel';

describe('LayerPanel', () => {
  it('toggles layer visibility on checkbox click', () => {
    const layers = [{ name: 'top', isVisible: true }];
    const onToggle = jest.fn();
    
    render(<LayerPanel layers={layers} onToggle={onToggle} />);
    
    const checkbox = screen.getByRole('checkbox');
    fireEvent.click(checkbox);
    
    expect(onToggle).toHaveBeenCalledWith(layers[0]);
  });
});
```

#### .NET (xUnit + Avalonia.Headless)
```csharp
public class LayerPanelTests
{
    [AvaloniaFact]
    public void ToggleLayerVisibility_UpdatesViewModel()
    {
        // Arrange
        var viewModel = new LayerPanelViewModel();
        viewModel.Layers.Add(new LayerViewModel { Name = "top", IsVisible = true });
        
        var window = new Window { DataContext = viewModel };
        var checkbox = window.Find<CheckBox>("LayerCheckbox");
        
        // Act
        checkbox.IsChecked = false;
        
        // Assert
        Assert.False(viewModel.Layers[0].IsVisible);
    }
}
```

**Key Difference:** React uses virtual DOM testing; Avalonia uses headless rendering with control queries.

---

## When to Choose Which?

### Choose Web (React/TypeScript) if:
✅ **Instant access** is critical (no installation)  
✅ **Cross-platform compatibility** without separate builds  
✅ **Rapid iteration** and deployment (CI/CD to CDN)  
✅ **Smaller data sets** (<50k features typical)  
✅ **Cloud-native** architecture preferred  
✅ Team has strong web development skills  

### Choose Desktop (.NET/Avalonia) if:
✅ **Performance** is paramount (100k+ features)  
✅ **Native OS integration** required (file dialogs, multi-window)  
✅ **Offline support** is essential  
✅ **Advanced 3D rendering** needed (complex shaders, GPU compute)  
✅ **Enterprise deployment** with controlled updates  
✅ Team has .NET/C# expertise  

---

## Hybrid Approach?

**Possible Strategy:** Build both versions sharing core logic

1. **Web Version (MVP):**
   - Fast time-to-market
   - Validates user workflows
   - Reaches widest audience

2. **Desktop Version (Post-MVP):**
   - Targets power users needing performance
   - Adds advanced features (large file support, offline mode)
   - Reuses API client patterns (JSON schemas portable)

**Code Reuse:**
- Share OpenAPI spec for API client generation
- Share geometry algorithms (port TypeScript ↔ C#)
- Share UI/UX design patterns

---

## Summary

Both technology stacks are viable for board-shape-view-client, with different trade-offs:

- **Web:** Lower barrier to entry, instant deployment, wider reach
- **Desktop:** Superior performance, native UX, offline-first

The choice depends on target audience, performance requirements, and deployment constraints. For professional PCB design tools targeting engineers with large boards, the .NET desktop version offers significant advantages despite higher initial complexity.

---

**Document Version:** 1.0  
**Last Updated:** January 2025
