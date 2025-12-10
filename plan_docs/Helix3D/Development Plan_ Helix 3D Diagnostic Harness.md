# **Development Plan: Helix 3D Diagnostic Harness**

## **Project Goal**

Create a diagnostic suite to identify why 3D objects fail to render in Avalonia by comparing behavior against a known working WPF stack, using configurable rendering profiles.

## **Team Requirements**

* **1 Senior C\# Developer:** Familiar with WPF, Avalonia, and MVVM.  
* **1 Graphics/Systems Developer:** Familiar with DirectX, SharpDX, or Helix Toolkit internals.

## **Phase 1: Foundation & Shared Logic (Days 1-2)**

*Goal: Create the solution structure and the shared "Brain" of the application.*

* **Task 1.1: Solution Setup**  
  * Create Solution HelixDiagnosticHarness.sln.  
  * Create H3D.Core (Class Lib), H3D.Launcher (WPF), H3D.Target.WPF (WPF), H3D.Target.Avalonia (Avalonia).  
* **Task 1.2: Logging Infrastructure**  
  * Implement DiagnosticLogger in Core.  
  * Requirement: Log file naming convention: {AppType}/{Profile}\_{Timestamp}.log.  
  * Requirement: Console output echo.  
* **Task 1.3: Profile Modeling**  
  * Create RenderProfile class (JSON serializable).  
  * Implement the boolean flags (SoftwareMode, FeatureLevel, etc.).  
* **Task 1.4: Scene Factory**  
  * Create SceneGenerator class.  
  * Implement GetTestMesh() returning a simple colored Cube and a Sphere.  
  * *Why:* Complex models introduce loading errors. Primitives confirm rendering pipelines.

## **Phase 2: The Launcher (Day 3\)**

*Goal: Build the UI to configure and spawn the tests.*

* **Task 2.1: Configuration UI**  
  * Create a Form with ComboBox for "Target App" (WPF/Avalonia).  
  * Create a PropertyGrid or List for editing RenderProfile.  
* **Task 2.2: Process Management**  
  * Implement ProcessStarter service.  
  * Logic: Serialize current Profile to temporary JSON.  
  * Logic: Start target .exe passing path to JSON as argument.

## **Phase 3: The WPF Baseline (Day 4\)**

*Goal: Establish the "Control" group. This must work first.*

* **Task 3.1: WPF Shell**  
  * Install HelixToolkit.Wpf.SharpDX.  
  * Create MainWindow.xaml with hx:Viewport3DX.  
* **Task 3.2: Argument Parsing**  
  * On Startup, read the JSON profile passed by Launcher.  
  * Apply settings to Viewport3DX (e.g., EnableDeferredRendering, EffectsManager).  
* **Task 3.3: Instrumentation**  
  * Add logging to Window\_Loaded.  
  * Add logging to Viewport3DX.OnRender.  
  * **Deliverable:** A working WPF window rendering a cube, generating a detailed log.

## **Phase 4: The Avalonia Target (Days 5-6)**

*Goal: The core diagnostic target.*

* **Task 4.1: Avalonia Shell**  
  * Install HelixToolkit.Avalonia (Ensure version compatibility with Avalonia 11.x+).  
  * Create MainWindow.axaml.  
* **Task 4.2: Viewport Implementation**  
  * Implement the Viewport3DX control.  
  * *Critical:* Map the RenderProfile settings to Avalonia-specific properties. (Note: Some WPF properties might need different handling in Avalonia).  
* **Task 4.3: Deep Tracing**  
  * Hook into Avalonia's TopLevel lifetime events.  
  * Attempt to catch DirectX device creation exceptions using a try/catch around the Viewport initialization if possible.

## **Phase 5: Profiles & Diagnostics (Day 7\)**

*Goal: Create the standard profiles to test the "Blank Screen" issues.*

* **Task 5.1: Profile Definitions**  
  * Define "Safe Mode": Force WARP, minimal shaders.  
  * Define "DX11 Hard": Force Hardware, DX11.  
* **Task 5.2: End-to-End Testing**  
  * Run Launcher.  
  * Select WPF \-\> Verify Cube \-\> Check Logs.  
  * Select Avalonia \-\> Verify Cube \-\> Check Logs.

## **Deliverables Checklist**

1. \[ \] Source Code Repository.  
2. \[ \] Compiled Binaries (Launcher \+ 2 Targets).  
3. \[ \] "Safe Mode" Profile that forces Software Rendering (Critical for debugging VM/Remote Desktop/Old Driver issues).  
4. \[ \] Sample Log files showing a successful render path.

## **Key Technical Risks & Mitigations**

* **Risk:** HelixToolkit.Avalonia API lags behind WPF.  
  * *Mitigation:* Stick to core SharpDX primitives in the Shared Library. Do not use UI-specific wrappers in the Core.  
* **Risk:** Inter-process communication complexity.  
  * *Mitigation:* Keep it simple. Pass data via a temporary JSON file on disk, not Named Pipes.