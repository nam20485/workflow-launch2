# **Architecture Design Document: Helix 3D Diagnostic Harness (H3D-Diag)**

## **1\. Executive Summary**

The **H3D-Diag** is a specialized Proof of Concept (PoC) application designed to validate, diagnose, and benchmark 3D rendering capabilities using the Helix Toolkit. Its primary goal is to isolate rendering failures in **Avalonia UI** by comparing them against a control baseline in **WPF**. The system utilizes a "Profile" based configuration system to test various DirectX and Initialization strategies to solve the "Blank Screen" / non-rendering issue.

## **2\. System Architecture**

The solution uses a Multi-Process Architecture.  
Reasoning: To capture a true "Startup to Render" trace, every test run must occur in a fresh process to ensure the DirectX context, Windowing subsystem, and memory are completely clean.

### **2.1 High-Level Component Diagram**

\[ H3D-Launcher (WinForms/WPF) \]   
       |  
       \+--- UI: Profile Selection & Configuration  
       \+--- Logic: Serializes Settings to JSON  
       \+--- Action: Spawns Child Process  
       |  
       v  
\[ H3D-Core (NetStandard 2.1 Lib) \] \<--- Referenced by all  
       |  
       \+--- Models: RenderProfile, AppConfig  
       \+--- Logic: DiagnosticLogger, SceneGenerator  
       \+--- ViewModels: Shared VM for Camera/Models  
       |  
       v  
\[ Target App: WPF \] OR \[ Target App: Avalonia \]  
       |                       |  
 (Reads Config File)     (Reads Config File)  
       |                       |  
    \[Init Trace\]            \[Init Trace\]  
       |                       |  
  \[Helix.Wpf.SharpDX\]   \[Helix.Avalonia\]

### **2.2 Project Structure**

1. **H3D.Core (Class Library)**  
   * Contains the *Business Logic* of the tests.  
   * **DiagnosticLogger**: A high-performance logger wrapping Serilog.  
   * **SceneFactory**: Generates the 3D objects (Cube, Sphere, Grid) programmatically so both apps render the exact same mesh data.  
   * **RenderProfile**: The model defining the configuration options (see Section 3).  
   * **TraceManager**: Static helper to tap into System.Diagnostics.PresentationTraceSources (WPF) and Avalonia's Log sink.  
2. **H3D.Launcher (WPF App)**  
   * The "Control Panel."  
   * Allows the user to select Target Framework (WPF | Avalonia).  
   * Allows the user to select or customize a RenderProfile.  
   * Generates a unique SessionID.  
   * Button: "Launch Diagnostic Test".  
3. **H3D.Target.WPF (WPF App)**  
   * A minimal WPF shell.  
   * Uses HelixToolkit.Wpf.SharpDX.  
   * Accepts command line args for Profile and SessionID.  
4. **H3D.Target.Avalonia (Avalonia App)**  
   * A minimal Avalonia shell.  
   * Uses HelixToolkit.Avalonia.  
   * Accepts command line args for Profile and SessionID.

## **3\. The "Profile" System (Configuration Strategy)**

To solve the rendering issues, we will inject configurations at startup. A RenderProfile consists of the following settings groups.

### **3.1 Profile Settings Schema**

| Group | Setting | Type | Description |
| :---- | :---- | :---- | :---- |
| **Driver** | ForceSoftwareRendering | Bool | Forces WARP (Windows Advanced Rasterization Platform). Good for detecting GPU driver bugs. |
|  | PreferredDriverType | Enum | Hardware, Reference, Software. |
| **DirectX** | MinimumFeatureLevel | Enum | Level\_10\_0, Level\_11\_0. Some older integrated cards fail on 11.0. |
| **Windowing** | EnableDpiScaling | Bool | Toggles HighDPI awareness manifest properties. |
| **Helix** | EnableDeferredRendering | Bool | Switches between immediate and deferred rendering pipelines. |
|  | RenderTechnique | Enum | Blinn, Phong, PBR (Physically Based Rendering). PBR is heavier and often fails on older hardware. |
| **Threading** | MultithreadedRendering | Bool | Toggles Helix's internal threading optimization. |

### **3.2 Pre-defined Profiles (The Solutions)**

1. **Standard (Default):** Hardware Accel, DX11, PBR, Multithreaded.  
2. **Safe Mode (WARP):** Software Rendering, DX10, Blinn shader. *If this works, the issue is your GPU Driver.*  
3. **Legacy Compatibility:** Hardware, DX10.1, Phong Shader. *If this works, the GPU is too old for DX11 features.*  
4. **Single Threaded:** Hardware, DX11, PBR, Main Thread only. *If this works, the issue is thread-safety/race conditions.*

## **4\. Diagnostic Tracing Pipeline**

The diagnostic requirement is to trace "Startup to Render". The DiagnosticLogger will create a file at:  
./Logs/{TargetType}/{ProfileName}\_{Timestamp}/debug.log

### **4.1 Trace Points**

The apps must emit logs at these specific lifecycle events:

1. **Phase 0: Boot:** Process Start, parsing arguments, deserializing Profile.  
2. **Phase 1: Window Init:** Window Constructor, OnSourceInitialized (WPF) / OnOpened (Avalonia).  
   * *Critical:* Log the IntPtr (Window Handle) to verify the OS window exists.  
3. **Phase 2: Graphics Context:**  
   * Query HelixToolkit.SharpDX.Core.DisposeCollector.  
   * Log detected Video Card Adapter and Driver Version.  
   * Log actual DirectX Feature Level obtained.  
4. **Phase 3: Scene Graph:**  
   * Log when models are added to the Viewport Items collection.  
5. **Phase 4: Render Loop:**  
   * Hook into Rendered event (if available) or override OnRender.  
   * Log "First Frame Time".  
   * **Action:** Capture a **Screenshot (PNG)** of the viewport. This provides definitive visual proof of whether the object rendered or if the screen remained black.

## **5\. Implementation Details**

### **Shared 3D Logic**

To ensure apples-to-apples comparison, the H3D.Core will expose a ViewModel:

public class DiagnosticSceneViewModel  
{  
    public Geometry3D TestObject { get; set; } // The Mesh  
    public Material Material { get; set; }     // The Shader config  
    public Vector3D CameraPosition { get; set; }  
      
    public void LoadScene(RenderProfile profile) {  
        // Generates the geometry based on the profile  
    }  
}

Both the WPF and Avalonia projects will bind their respective Viewport3DX controls to this exact same ViewModel.