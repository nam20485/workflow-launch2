# **Helix Toolkit & Avalonia: Support and Resources**

This document confirms that Helix Toolkit provides official support for the Avalonia UI framework and provides resources for getting started.

Support is provided via the high-performance **SharpDX (DirectX 11\)** implementation, which is analogous to the HelixToolkit.Wpf.SharpDX package used in WPF.

## **Proof of Support**

Here is the direct evidence of official support, which can be verified from the project's official sources:

* **Official NuGet Package:** The project publishes a specific package for Avalonia integration.  
  * **Package:** HelixToolkit.Avalonia.SharpDX  
  * **Link:** [https://github.com/orgs/helix-toolkit/packages/nuget/package/HelixToolkit.Avalonia.SharpDX](https://www.google.com/search?q=https://github.com/orgs/helix-toolkit/packages/nuget/package/HelixToolkit.Avalonia.SharpDX)  
* **GitHub Repository README:** The main repository's README file explicitly lists Avalonia.SharpDX as a supported platform and part of the project.  
  * **Quote:** "Avalonia.SharpDX: Custom 3D Engine and XAML/MVVM compatible Scene Graphs based on SharpDX(DirectX 11\) for AvaloniaUI."  
  * **Link:** [https://github.com/helix-toolkit/helix-toolkit](https://github.com/helix-toolkit/helix-toolkit)  
* **Source Code:** The project source code includes a dedicated project for the Avalonia controls.  
  * **Location:** helix-toolkit/Source/HelixToolkit.Avalonia.SharpDX

## **Teaching & Getting Started**

### **How It Works**

The integration uses Avalonia for the UI and hands off the 3D rendering to DirectX 11 via SharpDX. This provides excellent rendering performance on Windows.

The basic data flow is:  
Avalonia UI (Controls) $\\rightarrow$ HelixToolkit.Avalonia.SharpDX (e.g., Viewport3DX control) $\\rightarrow$ SharpDX (C\# Wrapper) $\\rightarrow$ DirectX 11 (GPU Rendering)

### **Key Resources**

* **Installation:** To add the toolkit to your Avalonia project, install the NuGet package:  
  dotnet add package HelixToolkit.Avalonia.SharpDX

* **Example Project:** The best way to learn is by reading the code. The official repository includes a complete example project for Avalonia.  
  * **Location:** helix-toolkit/Source/Examples/Avalonia.SharpDX/  
  * **Direct Link:** [https://github.com/helix-toolkit/helix-toolkit/tree/develop/Source/Examples/Avalonia.SharpDX](https://www.google.com/search?q=https://github.com/helix-toolkit/helix-toolkit/tree/develop/Source/Examples/Avalonia.SharpDX)  
* **Main Documentation:** While much of the documentation focuses on WPF, the core concepts (Scene Graph, MVVM, Cameras, Lights, Materials) are identical. The WPF documentation is still the primary resource for learning the toolkit's architecture.  
  * **Link:** [https://docs.helix-toolkit.org/](https://docs.helix-toolkit.org/)

### **Important Consideration: Cross-Platform**

It is crucial to understand that **Avalonia** is cross-platform (Windows, macOS, Linux).

However, this *specific* Helix Toolkit package (HelixToolkit.Avalonia.SharpDX) depends on **SharpDX**, which is a wrapper for **DirectX 11**. DirectX 11 is a Windows-only technology.

**Therefore, using HelixToolkit.Avalonia.SharpDX will allow you to build your application with Avalonia, but that application will only run on Windows.**