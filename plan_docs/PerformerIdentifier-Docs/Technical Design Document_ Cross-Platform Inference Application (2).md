# **Technical Design Document: Cross-Platform Inference Application**

Version: 5.1 (Comprehensive Engineering Guide)  
Framework: .NET 8.0  
UI Stack: Avalonia UI (v11+)  
Inference Stack: ONNX Runtime (v1.17+)  
Document Scope: Architecture, Implementation, Hardware Acceleration, and Deployment Strategy.

## **1\. Architecture Guide & Principles**

This section defines the rigorous rules, software patterns, and design philosophies that govern the codebase. The primary architectural goal is to rigidly decouple the application's "Brain" (the high-performance AI inference capabilities) from its "Body" (the User Interface). This separation ensures that the core intellectual property—your inference pipeline, pre-processing logic, and model heuristics—remains portable, testable, and stable, even as UI frameworks evolve (e.g., migrating from WPF to Avalonia) or deployment targets change (e.g., moving from a Desktop App to a headless Web API).

### **1.1 Core Principle: The Dependency Rule**

We strictly utilize **Clean Architecture** (also known as Onion Architecture or Hexagonal Architecture). The fundamental, non-negotiable rule is that **source code dependencies must always flow inward** toward the core domain.

* **Inner Circle (The Core / Domain Layer):**  
  * **Content:** This layer contains **Enterprise Business Rules**. In the context of a Computer Vision application, this includes:  
    * **The AI Models:** The binary assets and their associated metadata (input/output shapes).  
    * **Tensor Logic:** The mathematical transformations required to convert raw bytes into normalized matrices.  
    * **Post-processing Algorithms:** Domain-specific logic such as Non-Maximum Suppression (NMS), Softmax probability normalization, and class label mapping.  
  * **Constraints:** This layer must have **zero dependencies** on external UI frameworks like Avalonia, WPF, MAUI, or any OS-specific UI libraries (e.g., System.Windows, UIKit). It must rely solely on standard .NET types and generic, cross-platform libraries (like SkiaSharp for platform-agnostic imaging).  
  * **Implication & Value:** By isolating this layer, we achieve two critical engineering goals:  
    1. **Testability:** You can write fast, robust Unit Tests for your inference logic without needing to instantiate a Window, initialize a Graphics Device, or spin up a UI thread.  
    2. **Portability:** You can take the compiled InferenceApp.Core.dll and drop it into a headless Linux Docker container to run as a backend microservice, or into a Unity game project, without changing a single line of code.  
* **Outer Circle (The UI / Infrastructure Layer):**  
  * **Content:** This layer contains **Mechanisms**. It handles the "dirty details" of the operating system and user interaction:  
    * **Window Management:** Resizing, minimizing, and DPI scaling.  
    * **Input Handling:** Button click events, drag-and-drop, and keyboard shortcuts.  
    * **Native Interop:** Native File Dialogs (Explorer/Finder) and the actual rendering of pixels to the screen via the GPU.  
  * **Constraints:** This layer acts as an adapter. It adapts the Core to the specific needs of the user interface. It is allowed to reference the Core to invoke operations, but the Core must **never** reference the UI layer.  
  * **Implication:** The UI is treated as a "plugin" to the system. If we decide to switch from Avalonia to a Command Line Interface (CLI) tool for batch processing later, we simply throw away this outer layer and replace it with a new Console project; the complex Core logic remains untouched and pristine.

### **1.2 The "Adapter" Pattern for Hardware**

Hardware acceleration is inherently platform-specific, volatile, and prone to breaking changes (e.g., driver updates, OS upgrades, CUDA version mismatches). To insulate the application's business logic from this volatility, we use the **Adapter Pattern** via the IInferenceEngine interface.

* **The Contract (IInferenceEngine):** This interface defines a pure, abstract C\# contract: *"I accept a byte array representing an image, and I return a list of predictions."* It intentionally says nothing about GPUs, NPUs, CUDA, DirectML, or specific drivers. It is an abstraction of intent.  
* **The Adaptation (OnnxInferenceEngine):** The concrete implementation acts as the adapter. At runtime (not compile time), it intelligently queries the operating system environment (RuntimeInformation) to decide how to fulfill the contract efficiently.  
  * *Scenario A (Windows):* "I detect I am running on Windows 10/11. I will configure the session to talk to the GPU via the **DirectML API**, which abstracts the specific hardware (AMD/NVIDIA/Intel) and guarantees DirectX 12 compatibility."  
  * *Scenario B (Linux):* "I detect I am running on Linux. I will configure the session to execute on the CPU via standard **AVX/AVX512 instructions**, ensuring maximum stability over raw speed, avoiding potential driver conflicts."  
  * *Scenario C (macOS):* "I detect I am running on macOS (Arm64). I will bridge to the Apple Neural Engine (NPU) via **CoreML**, enabling high-performance, low-power inference."  
* **Benefit:** The consuming code (the UI ViewModel) remains completely ignorant of the complex driver negotiations happening in the background. It simply calls PredictAsync and awaits the result, decoupling the "What" from the "How."

### **1.3 Architectural Diagram**

graph TD  
    subgraph "Presentation Layer (Avalonia \- Volatile)"  
        View\[MainWindow.axaml\]  
        ViewModel\[MainViewModel.cs\]  
        Assets\[Assets & Styles\]  
        RenderLogic\[Canvas Overlay System\]  
    end

    subgraph "Core Layer (Class Library \- Stable)"  
        Interface\[IInferenceEngine\]  
        Implementation\[OnnxInferenceEngine\]  
        Domain\[PredictionResult Model\]  
        Helpers\[Tensor & Image Utils\]  
        PreProcess\[Preprocessing Logic\]  
        PostProcess\[NMS & Filtering\]  
    end

    View \--\>|Data Binding & Events| ViewModel  
    ViewModel \--\>|Injects via DI| Interface  
    Implementation \--\>|Implements| Interface  
    Implementation \--\>|Uses| Helpers  
    Implementation \--\>|Uses| PreProcess  
    Implementation \--\>|Uses| PostProcess

## **2\. Cross-Platform Strategy: Deep Dive**

Our strategy relies on the philosophy of **"Write Once, Adapt Runtime"**. However, simple .NET compatibility is not enough when dealing with high-performance graphics and AI hardware. This section details the mechanics of the "Native Gap" and how to handle them robustly.

### **2.1 The "Native Gap" Mechanics**

While .NET code runs in a managed Virtual Machine (CLR), high-performance operations like GPU rendering and AI inference run in unmanaged C/C++ land. The **"Native Gap"** is the boundary where .NET uses P/Invoke (Platform Invocation Services) to call into OS-specific shared libraries (.dll, .so, .dylib).

The Problem:  
If you strictly reference a standard NuGet package like SkiaSharp, it often contains only the managed C\# wrapper. It does not always contain the heavy native C++ binary for every possible operating system (to save package size).

* **On Windows:** The wrapper looks for libSkiaSharp.dll (Native).  
* **On Linux:** The wrapper looks for libSkiaSharp.so (Native).  
* **On macOS:** The wrapper looks for libSkiaSharp.dylib (Native).

If the correct native file for the current OS is missing at runtime, the application will crash instantly with a DllNotFoundException or TypeInitializationException.

### **2.2 Solution Strategy: Rendering (SkiaSharp)**

We use SkiaSharp because it is the engine powering Google Chrome, Android, and Flutter, making it the most stable and performant 2D graphics library available.

* **Implementation Strategy:** Do **not** rely on the meta-package SkiaSharp alone. You must explicitly reference native assets for your target platforms in the .csproj. This forces the build system to copy the correct binary to the output folder.  
  \<\!-- In InferenceApp.UI.csproj \--\>  
  \<ItemGroup\>  
      \<PackageReference Include="SkiaSharp" Version="2.88.6" /\>  
      \<\!-- REQUIRED: Bundles libSkiaSharp.so for Ubuntu/Debian/Fedora \--\>  
      \<PackageReference Include="SkiaSharp.NativeAssets.Linux" Version="2.88.6" /\>  
      \<\!-- REQUIRED: Bundles libSkiaSharp.dylib for macOS Intel/Silicon \--\>  
      \<PackageReference Include="SkiaSharp.NativeAssets.macOS" Version="2.88.6" /\>  
  \</ItemGroup\>

* **Linux Troubleshooting:** Even with the package above, libSkiaSharp.so relies on system-level font libraries to render text.  
  * **The Issue:** On a fresh, minimal Ubuntu/Debian install, the app may crash because Skia cannot find a font manager.  
  * The Fix: You must ensure the target machine has the basic font configurations installed:  
    sudo apt-get install libfontconfig1  
  * **Debugging:** Use the ldd command to inspect dependencies. Navigate to your publish folder and run ldd libSkiaSharp.so. Any line showing "not found" represents a missing system package that must be installed via apt or yum.

### **2.3 Solution Strategy: Inference (ONNX Runtime)**

ONNX Runtime (ORT) is highly modular to keep the base footprint small. The base package Microsoft.ML.OnnxRuntime contains only the CPU runtime. Hardware accelerators (DirectML, CoreML, CUDA) are distributed as separate add-on packages.

The "DLL Hell" Risk:  
You cannot simply "add all packages" and expect it to work.

* If you attempt to load DirectML.dll on Linux, it will crash because the DirectX subsystem does not exist.  
* If you attempt to load CoreML on Windows, it will crash because the Apple Neural Engine frameworks are missing.

Implementation Pattern: Safe Conditional Loading  
Do not use hard dependencies or static linking in your using statements if possible. Instead, use the RuntimeInformation check to conditionally register providers at runtime.  
// In OnnxInferenceEngine constructor  
var options \= new SessionOptions();

// 1\. Windows Strategy (DirectML)  
if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))  
{  
    try   
    {  
        // Explicitly requesting GPU 0\.  
        // REQUIRES: Microsoft.ML.OnnxRuntime.DirectML package installed  
        options.AppendExecutionProvider\_DML(0);  
    }  
    catch (Exception ex)  
    {  
        // Fallback: This catches scenarios where the user is on Windows 7,  
        // or has a generic "Microsoft Basic Display Adapter" with no DX12 support.  
        \_logger.LogWarning($"DirectML failed to load. Falling back to CPU. Error: {ex.Message}");  
        options.AppendExecutionProvider\_CPU();  
    }  
}  
// 2\. macOS Strategy (CoreML)  
else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))  
{  
    try  
    {  
        // Enable CoreML on Subgraph ensures that if a specific ONNX operator isn't   
        // supported by Apple NPU, it falls back to CPU for just that node,   
        // preventing the entire graph from failing.  
        // REQUIRES: Microsoft.ML.OnnxRuntime.CoreML package installed  
        options.AppendExecutionProvider\_CoreML(CoreMLFlags.COREML\_FLAG\_ENABLE\_ON\_SUBGRAPH);  
    }  
    catch (Exception ex)  
    {  
        \_logger.LogWarning($"CoreML failed to load. Falling back to CPU. Error: {ex.Message}");  
        options.AppendExecutionProvider\_CPU();  
    }  
}  
// 3\. Linux Strategy (CPU Default)  
else  
{  
    // On Linux, the standard "Microsoft.ML.OnnxRuntime" package provides a   
    // highly optimized CPU runner (using AVX2/AVX512 instructions).   
    // Note: ROCm (AMD GPU) support requires a custom Docker container build   
    // and is technically out of scope for a generic standalone executable.  
    options.AppendExecutionProvider\_CPU();  
}

### **2.4 Execution Provider Matrix**

This table details exactly how we achieve hardware acceleration on each target, balancing performance against compatibility.

| OS | Hardware Target | Execution Provider | NuGet Package | Technical Notes |
| :---- | :---- | :---- | :---- | :---- |
| **Windows** | Any GPU (AMD/NV/Intel) | **DirectML** | Microsoft.ML.OnnxRuntime.DirectML | **Recommended.** DirectML is a low-level abstraction layer in DirectX 12\. It works on *any* DirectX 12 compatible GPU, effectively abstracting vendor differences. It eliminates the need for strict CUDA version matching, which is the \#1 cause of support tickets in AI apps. |
| **Windows** | NVIDIA GPU | **CUDA** | Microsoft.ML.OnnxRuntime.Gpu | Faster raw throughput than DirectML, but **brittle**. Requires the user to have specific NVIDIA drivers and a specific CUDA Toolkit version (e.g., v11.8) installed. We avoid this for general distribution to prevent "it works on my machine" issues. |
| **macOS** | Apple Silicon (M1+) | **CoreML** | Microsoft.ML.OnnxRuntime.CoreML | Directly accesses the Apple Neural Engine (NPU). This is orders of magnitude faster and more power-efficient than CPU inference on MacBooks. It essentially makes inference "free" regarding battery life. |
| **Linux** | x64 CPU | **CPU** | Microsoft.ML.OnnxRuntime | The default fallback. Modern CPUs with AVX512 instructions are surprisingly fast for small/medium models (e.g., YOLOv8-Nano). It is the safest baseline for Linux servers or desktops. |
| **Linux** | AMD GPU | **ROCm** | *Docker Container* | **Advanced.** ROCm support is not available via a simple NuGet package. To support AMD GPUs on Linux, the application must typically be deployed as a Docker container built on top of AMD's official ROCm base image. |

### **2.5 Deployment & Publishing Hints**

When deploying, you cannot rely on the user having the .NET Runtime installed. You must use **Self-Contained** publishing. This bundles the CLR, your code, and the specific native assets for that OS into one folder.

* **Runtime Identifier (RID):** You must specify the target OS at build time.  
  * win-x64: Windows 64-bit.  
  * linux-x64: Linux 64-bit (Most desktop distros).  
  * osx-arm64: macOS Apple Silicon.

**Correct Publishing Command:**

\# For Windows  
\# PublishSingleFile: Packages everything into one .exe  
\# IncludeNativeLibrariesForSelfExtract: Ensures native DLLs are extracted to a temp folder at run time  
dotnet publish \-c Release \-r win-x64 \--self-contained \-p:PublishSingleFile=true \-p:IncludeNativeLibrariesForSelfExtract=true

\# For Linux  
\# We do not typically use SingleFile for Linux to allow for easier LD\_LIBRARY\_PATH debugging  
dotnet publish \-c Release \-r linux-x64 \--self-contained

## **3\. Model Engineering: Acquisition & Preparation**

Before writing code, you need a valid ONNX model file. This section details how to source, convert, and optimize models for the .NET runtime.

### **3.1 Acquisition Channels**

1. Exporting Locally (The Gold Standard):  
   The most reliable way to get a model that guaranteed works with your code is to export it yourself. This ensures the Input Shape and Opset version match your C\# implementation exactly.  
   * **Command:** pip install ultralytics && yolo export model=yolov8n.pt format=onnx opset=12 imgsz=640  
   * **Result:** You will have a file yolov8n.onnx in your folder. This file is perfect.  
2. Manual Download (Criteria Matching):  
   If you cannot run Python/PIP, you can download a pre-exported model from Hugging Face. However, you must filter through the noise to find the correct version.  
   * **Search:** Go to [Hugging Face Models](https://huggingface.co/models) and search yolov8n onnx.  
   * **Selection Criteria (CRITICAL):**  
     * **Filename:** Look for yolov8n.onnx exactly.  
     * **File Size:** It should be approximately **12 MB**.  
     * **Avoid:** Do NOT download files with \_int8, \_quant, or \_fp16 in the name unless you specifically change your pre-processing code. These are quantized models that may crash the generic CPU runtime or require casting inputs to Float16.  
     * **Avoid:** Do NOT download .safetensors or .pt files; the .NET runtime cannot read them.

### **3.2 Exporting from Training Frameworks**

If you are training your own model or using a specific architecture (like YOLO), you must export it to ONNX.

* Exporting YOLOv8 (Ultralytics):  
  Use the Python CLI to export. We explicitly set the opset to 12 to ensure broad compatibility with .NET ONNX Runtime versions.  
  pip install ultralytics  
  \# Export to ONNX with dynamic batch size disabled (simplifies C\# logic)  
  yolo export model=yolov8n.pt format=onnx opset=12 imgsz=640

* Exporting Generic PyTorch Models:  
  If you have a custom torch.nn.Module, use this Python snippet to create your .onnx file:  
  import torch  
  import torchvision

  \# 1\. Load your model  
  model \= torchvision.models.resnet18(pretrained=True)  
  model.eval()

  \# 2\. Create dummy input (Batch Size 1, 3 Channels, 224 Height, 224 Width)  
  dummy\_input \= torch.randn(1, 3, 224, 224\)

  \# 3\. Export  
  torch.onnx.export(  
      model,   
      dummy\_input,   
      "resnet18.onnx",   
      input\_names=\["input"\],   
      output\_names=\["output"\],  
      opset\_version=12  
  )

### **3.3 Model Optimization (Quantization)**

To reduce model size (e.g., from 100MB to 25MB) and increase speed on CPUs, you can **Quantize** the model from Float32 to Int8/UInt8. This is highly recommended for the "Linux CPU" fallback scenario.

* **Tools:** Use the onnxruntime python package.  
* **Script:**  
  \# Requires: pip install onnxruntime  
  from onnxruntime.quantization import quantize\_dynamic, QuantType

  model\_fp32 \= 'yolov8n.onnx'  
  model\_quant \= 'yolov8n.int8.onnx'

  print(f"Quantizing {model\_fp32}...")

  quantize\_dynamic(  
      model\_fp32,  
      model\_quant,  
      weight\_type=QuantType.QUInt8  \# Quantize weights to 8-bit unsigned integers  
  )

  print(f"Success\! Optimized model saved to {model\_quant}")

### **3.4 Model Inspection (Mandatory Step)**

You cannot blindly guess the input shape of a model. If your C\# code sends a 640x640 tensor but the model expects 224x224, the app will crash.

1. **Tool:** Download [Netron](https://netron.app/).  
2. **Verify Input:** Click the input node. Check the **shape** (e.g., 1x3x640x640) and **type** (float32).  
   * *Action:* Update your OnnxInferenceEngine.cs constants to match these dimensions.  
3. **Verify Output:** Click the output node.  
   * *Action:* This determines if you need to write classification logic (parsing a 1D array) or object detection logic (parsing bounding box coordinates).

## **4\. User Experience (UX) Design**

This section details the primary interactions the user will have with the application.

### **4.1 Expanded User Stories**

* **US-1: Load Image**  
  * **Description:** As a user, I want to load an image from my local disk using a familiar interface so that I can select specific photos for analysis.  
  * **Acceptance Criteria:**  
    * Clicking "Load" opens the native OS file picker (Explorer on Windows, Finder on macOS, GTK/Qt dialog on Linux).  
    * The file picker defaults to filtering for common image formats (.jpg, .jpeg, .png, .bmp, .webp).  
    * The application gracefully handles file permission errors (e.g., user selects a file they don't have read access to).  
  * **Technical Constraint:** Must use Avalonia's StorageProvider API for cross-platform compatibility.  
* **US-2: Display Image**  
  * **Description:** As a user, I want to see the loaded image displayed within the application window so I can confirm I selected the correct file.  
  * **Acceptance Criteria:**  
    * The image renders immediately after selection.  
    * The image scales to fit the available window space while maintaining its original aspect ratio (Stretch="Uniform"). It must not look stretched or squashed.  
    * High-quality scaling algorithms (Bicubic or HighQuality) are used to prevent pixelation artifacts on high-DPI displays.  
* **US-3: Run Detection**  
  * **Description:** As a user, I want to trigger the AI analysis by clicking a "Detect" button without the application freezing or becoming unresponsive.  
  * **Acceptance Criteria:**  
    * Clicking "Detect" starts the inference process.  
    * The UI remains responsive (e.g., the window can still be dragged/moved) while the AI is computing.  
    * A visual indicator (e.g., a spinning progress bar or "Processing..." status text) appears immediately to indicate work is happening.  
    * The "Detect" button is temporarily disabled to prevent double-clicking.  
* **US-4: Visualize Results**  
  * **Description:** As a user, I want to see clearly defined bounding boxes around detected objects, along with labels and confidence scores, so I can understand what the AI found.  
  * **Acceptance Criteria:**  
    * Bounding boxes are drawn overlaying the original image.  
    * Each box includes a text label (e.g., "Dog") and a confidence percentage (e.g., "95%").  
    * Text labels must have sufficient contrast (e.g., white text on a colored background rect) to be readable against any image background.  
    * Different object classes (e.g., Person vs. Car) should ideally use distinct colors for easier visual differentiation.  
* **US-5: Responsive Resize**  
  * **Description:** As a user, I want to resize the application window and have the bounding boxes stay correctly positioned over the objects.  
  * **Acceptance Criteria:**  
    * When the window is resized, the image resizes proportionally.  
    * The overlay bounding boxes automatically recalculate their positions to match the new image size. A box drawn around a face must remain on the face, regardless of window size.  
    * This update happens smoothly in real-time during the resize operation.  
* **US-6: Error Handling**  
  * **Description:** As a user, I want to be informed if something goes wrong (like a missing model file or corrupted image) via a clear message instead of the application crashing.  
  * **Acceptance Criteria:**  
    * If the model file (.onnx) is missing at startup, a specific error message is shown in the status bar or a dialog.  
    * If the GPU driver crashes (DirectML error), the system catches the exception, logs it, and optionally attempts to fall back to CPU or informs the user.  
    * The app does not close unexpectedly (Crash-to-Desktop) during standard error scenarios.

### **4.2 User Flow Diagram**

1. **Start App**  
   * Core initializes ONNX Runtime environment.  
   * Core polls hardware via RuntimeInformation to determine best execution provider (DirectML vs CPU).  
2. **Idle State**  
   * UI shows "Ready" in status bar.  
   * Placeholder "Drop Image Here" icon visible.  
3. **Action: Load Image**  
   * User clicks "Load" \-\> Native File Dialog opens.  
   * User selects dog.jpg.  
   * UI loads bytes into SKBitmap.  
   * UI sets DisplayImage property \-\> View updates.  
4. **Action: Run Inference**  
   * User clicks "Detect".  
   * UI sets IsBusy \= true \-\> Spinner appears, buttons disable.  
   * **Background Thread (Task.Run):**  
     1. **Pre-process:** Resize Image to 640x640 using Skia HighQuality filter.  
     2. **Normalize:** Convert RGB bytes to float tensor (0.0 \- 1.0) in NCHW format.  
     3. **Inference:** Session.Run() executes the computational graph.  
     4. **Post-process:** Filter low confidence boxes. Run NMS algorithm. Map class IDs to string labels.  
   * Background thread returns List\<PredictionResult\>.  
   * **UI Thread:**  
     1. Marshals data back to UI context.  
     2. Updates ObservableCollection\<Detections\>.  
     3. Sets IsBusy \= false \-\> Spinner hides, buttons enable.  
     4. Canvas overlays rectangles over the image.

## **5\. Core Implementation Details**

### **5.1 The Tensor Transformation (NCHW)**

This is the most common point of failure for beginners in Computer Vision. Most vision models expect **NCHW** (Batch, Channels, Height, Width) memory layout, but standard bitmaps are stored as **NHWC** (Height, Width, Channels/RGB).

* **Input:** SKBitmap (Packed pixel: R, G, B, R, G, B...)  
* **Output:** DenseTensor\<float\> (Planar: R, R, R... G, G, G... B, B, B...)

You cannot simply copy memory using BlockCopy. You must iterate and transpose.

public DenseTensor\<float\> Preprocess(SKBitmap image, int targetDim)  
{  
    // 1\. Resize using Skia   
    // We use SKFilterQuality.Medium or High to ensure the AI sees a sharp image.  
    using var resized \= image.Resize(new SKImageInfo(targetDim, targetDim), SKFilterQuality.Medium);  
      
    // 2\. Create Tensor of shape \[1, 3, H, W\]  
    var tensor \= new DenseTensor\<float\>(new\[\] { 1, 3, targetDim, targetDim });  
      
    // 3\. Transpose & Normalize Loop  
    // High-Performance Optimization: Use Span\<T\> to avoid GetPixel overhead.  
    // GetPixel() is slow because of method call overhead per pixel.  
    // Accessing the raw pixel buffer is \~10x faster.  
    // Explicitly convert to RGBA8888 before accessing bytes.  
    using var converted \= resized.Copy(SKColorType.Rgba8888);  
    ReadOnlySpan\<byte\> pixels \= converted.GetPixelSpan();  
    int bytesPerPixel \= converted.BytesPerPixel; // Should be 4 (RGBA)

    // Access the output tensor as a flat span for speed  
    var tensorSpan \= tensor.Buffer.Span;  
    int pixelCount \= targetDim \* targetDim;  
    int rOffset \= 0;  
    int gOffset \= pixelCount;  
    int bOffset \= 2 \* pixelCount;

    for (int y \= 0; y \< targetDim; y++)  
    {  
        int rowStart \= y \* targetDim;  
        int byteRowStart \= rowStart \* bytesPerPixel;

        for (int x \= 0; x \< targetDim; x++)  
        {  
            // Input Pixel Index (RGBA bytes)  
            int pixelOffset \= byteRowStart \+ (x \* bytesPerPixel);  
              
            // Output Tensor Index (Flat float array)  
            int tensorIndex \= rowStart \+ x;

            // Normalize (0..255 \-\> 0.0..1.0) and assign to planar buffers  
            // Channel 0: Red  
            tensorSpan\[rOffset \+ tensorIndex\] \= pixels\[pixelOffset\] / 255.0f;  
            // Channel 1: Green  
            tensorSpan\[gOffset \+ tensorIndex\] \= pixels\[pixelOffset \+ 1\] / 255.0f;  
            // Channel 2: Blue  
            tensorSpan\[bOffset \+ tensorIndex\] \= pixels\[pixelOffset \+ 2\] / 255.0f;  
        }  
    }  
    return tensor;  
}

### **5.2 Threading & Memory Safety**

* **IDisposable Pattern:** The InferenceSession object holds references to unmanaged memory (specifically GPU VRAM if DirectML is used). If you create a new session every time you press "Detect" without disposing the old one, you will rapidly crash the application with an Out Of Memory (OOM) error. Implement IDisposable on the OnnxInferenceEngine class and ensure it disposes the session when the app closes or when the model is switched.  
* **Observability:** Inject ILogger\<OnnxInferenceEngine\> into the constructor. Hardware acceleration failures (e.g. DirectML crashing) are often silent or generic without proper logging.  
* **Async/Await Marshalling:** Inference is a CPU/GPU intensive blocking operation.  
  * **Do Not:** Call \_session.Run() directly on the UI thread. The window will freeze, ghost, and trigger the OS "Not Responding" prompt.  
  * **Do:** Wrap the call in Task.Run(() \=\> \_session.Run(...)).  
  * **Do:** When the task returns, ensure you update the ObservableCollection on the UI thread. Avalonia usually handles this with Dispatcher.UIThread.InvokeAsync if not using the MVVM Toolkit's helpers, or use the SynchronizationContext captured by async/await.

## **6\. Implementation Roadmap**

### **Phase 1: Core Setup (The Brain)**

*Goal: Establish the stable inner domain that processes data.*

1. **Project Init:** dotnet new classlib \-n InferenceApp.Core  
2. **NuGets:** Install Microsoft.ML.OnnxRuntime, SkiaSharp, and Microsoft.Extensions.Logging.Abstractions.  
3. **Code:** Implement OnnxInferenceEngine.cs. Focus on the Preprocess method (resizing and tensor conversion) described in Section 5.1.  
4. **Test:** Create a simple Console App. Load a real .onnx file.  
   * *Tip:* Ensure the .onnx file properties are set to **"Copy to Output Directory: Copy if newer"** in Visual Studio/VS Code, or the app will crash with FileNotFoundException.  
   * **Fix for CI/Linux Tests:** You must ensure the Test project also references SkiaSharp.NativeAssets.Linux, or tests involving SKBitmap will fail with DllNotFoundException on Linux build agents (GitHub Actions).

### **Phase 2: UI Setup (The Body)**

*Goal: Create the visual shell that will host the data.*

1. **Project Init:** dotnet new avalonia.app \-n InferenceApp.UI  
2. **References:** Add project reference to InferenceApp.Core.  
   * Install CommunityToolkit.Mvvm for clean ViewModels (Source Generators).  
   * Install Microsoft.Extensions.DependencyInjection to enable the 'Injects via DI' requirement in the architectural diagram.  
3. **Linux Compat:** Install SkiaSharp.NativeAssets.Linux to ensure the drawing code works on WSL or Linux Desktop.  
4. **View Construction:** Build a Grid containing an \<Image\> control (bottom layer) and an \<ItemsControl\> (top layer) for drawing the boxes. Use Canvas.Left and Canvas.Top bindings on the items.

### **Phase 3: Hardware Acceleration**

*Goal: Enable the hardware adapters.*

1. **NuGets:** Add Microsoft.ML.OnnxRuntime.DirectML. For macOS NPU support, add Microsoft.ML.OnnxRuntime.CoreML (use CLI if not listed in UI: dotnet add package Microsoft.ML.OnnxRuntime.CoreML). **Warning:** Ensure these package versions match the base Microsoft.ML.OnnxRuntime version EXACTLY to avoid runtime linking errors.  
2. **Switch Logic:** Implement the RuntimeInformation.IsOSPlatform checks in the Core constructor to conditionally append SessionOptions.AppendExecutionProvider\_DML or \_CoreML.  
3. **Verification:** Run the app on Windows and check Task Manager \-\> Performance \-\> GPU to ensure the "Compute" or "3D" engine is active during inference.

### **Phase 4: Release & Deployment**

*Goal: Package the app for distribution.*

1. **Windows Publish:**  
   * Command: dotnet publish \-c Release \-r win-x64 \--self-contained  
   * Result: A folder containing .exe and all necessary .dlls (including DirectML and Skia). No .NET install required for the user.  
2. **Linux Publish:**  
   * Command: dotnet publish \-c Release \-r linux-x64 \--self-contained  
   * Result: A standalone binary.  
   * *Note:* Ensure libfontconfig1 is installed on the target Linux machine for Avalonia text rendering.