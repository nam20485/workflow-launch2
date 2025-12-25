# **Technical Design Document: Cross-Platform Inference Application**

Version: 4.2 (Comprehensive Engineering Guide)  
Framework: .NET 8.0  
UI Stack: Avalonia UI (v11+)  
Inference Stack: ONNX Runtime (v1.17+)

## **1\. Architecture Guide & Principles**

This section defines the rigorous rules and software patterns that govern the codebase. The primary architectural goal is to decouple the application's "Brain" (the AI inference capabilities) from its "Body" (the User Interface). This separation ensures that the core intellectual property—your inference pipeline—remains portable and stable, even as UI frameworks evolve or get replaced (e.g., migrating from WPF to Avalonia, or later to MAUI or a web API).

### **1.1 Core Principle: The Dependency Rule**

We strictly utilize **Clean Architecture** (also known as Onion Architecture). The fundamental rule is that dependencies must always flow **inward** toward the core domain.

* **Inner Circle (The Core / Domain Layer):**  
  * **Content:** This layer contains Enterprise Business Rules. In the context of an AI application, this includes the AI Models themselves, the mathematical Tensor transformation logic, and the Post-processing algorithms (like Non-Maximum Suppression or Softmax).  
  * **Constraints:** This layer must have **zero dependencies** on external UI frameworks like Avalonia, WPF, MAUI, or any OS-specific UI libraries (e.g., System.Windows). It relies solely on standard .NET types and generic, cross-platform libraries (like SkiaSharp for platform-agnostic imaging).  
  * **Implication:** By isolating this layer, we achieve "Testability" and "Portability." You can write Unit Tests for your inference logic without needing to instantiate a Window or a Graphics Device. You can also take this compiled DLL and drop it into a headless Linux Docker container to run as a backend service, or into a Unity game project, without changing a single line of code.  
* **Outer Circle (The UI / Infrastructure Layer):**  
  * **Content:** This layer contains Mechanisms. It handles the "dirty details" of the operating system: Window management, Button click events, Native File Dialogs, and the actual rendering of pixels to the screen.  
  * **Constraints:** This layer adapts the Core to the user. It is allowed to reference the Core to invoke operations, but the Core must never reference it back.  
  * **Implication:** The UI is treated as a "plugin" to the system. If we decide to switch from Avalonia to a Command Line Interface (CLI) tool for batch processing later, we simply throw away this outer layer and replace it; the complex Core logic remains untouched and pristine.

### **1.2 The "Adapter" Pattern for Hardware**

Hardware acceleration is inherently platform-specific, volatile, and prone to breaking changes (driver updates, OS upgrades). To insulate the application from this volatility, we use the **Adapter Pattern** via the IInferenceEngine interface.

* **The Contract:** The IInferenceEngine interface defines a pure C\# contract: *"I accept a byte array representing an image, and I return a list of predictions."* It intentionally says nothing about GPUs, NPUs, CUDA, or specific drivers.  
* **The Adaptation:** The concrete implementation (OnnxInferenceEngine) acts as the adapter. At runtime (not compile time), it queries the operating system environment to decide how to fulfill the contract.  
  * *Scenario A (Windows):* "I detect I am running on Windows 10/11. I will configure the session to talk to the GPU via the DirectML API, which abstracts the specific hardware (AMD/NVIDIA/Intel)."  
  * *Scenario B (Linux):* "I detect I am running on Linux. I will configure the session to execute on the CPU via standard AVX/AVX512 instructions, ensuring stability over raw speed."  
  * *Scenario C (macOS):* "I detect I am running on macOS (Arm64). I will bridge to the Apple Neural Engine via CoreML."  
* **Benefit:** The consuming code (the UI ViewModel) remains completely ignorant of the complex driver negotiations happening in the background. It simply calls PredictAsync and awaits the result.

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

Our strategy relies on the philosophy of **"Write Once, Adapt Runtime"**. However, simple .NET compatibility is not enough when dealing with high-performance graphics and AI hardware. This section details the "Native Gap" mechanics and how to handle them robustly.

### **2.1 The "Native Gap" Mechanics**

.NET code runs in a managed Virtual Machine (CLR), but GPUs and Graphics Drivers run in unmanaged C/C++ land. The "Native Gap" is the boundary where .NET uses P/Invoke to call into OS-specific shared libraries (.dll, .so, .dylib).

The Problem:  
If you reference a standard NuGet package like SkiaSharp, it contains the managed C\# wrapper. It does not always contain the native C++ binary for every possible operating system (to save space).

* **On Windows:** SkiaSharp.dll (Managed) looks for libSkiaSharp.dll (Native).  
* **On Linux:** SkiaSharp.dll (Managed) looks for libSkiaSharp.so (Native).

If the native file is missing, the app crashes instantly with DllNotFoundException or TypeInitializationException.

### **2.2 Solution Strategy: Rendering (SkiaSharp)**

We use SkiaSharp because it is the engine powering Google Chrome and Android, making it the most stable 2D graphics library available.

* **Implementation Hint:** Do **not** rely on the meta-package SkiaSharp alone. You must explicitly reference native assets for your target platforms in the .csproj.  
  \<\!-- In InferenceApp.UI.csproj \--\>  
  \<ItemGroup\>  
      \<PackageReference Include="SkiaSharp" Version="2.88.6" /\>  
      \<\!-- REQUIRED for Linux support \--\>  
      \<PackageReference Include="SkiaSharp.NativeAssets.Linux" Version="2.88.6" /\>  
      \<\!-- REQUIRED for macOS support \--\>  
      \<PackageReference Include="SkiaSharp.NativeAssets.macOS" Version="2.88.6" /\>  
  \</ItemGroup\>

* **Linux Troubleshooting:** Even with the package above, libSkiaSharp.so depends on system fonts.  
  * Hint: On a fresh Ubuntu/Debian install, your app may crash until you run:  
    sudo apt-get install libfontconfig1  
  * **Debug Tip:** Use ldd to verify dependencies. Navigate to your publish folder and run: ldd libSkiaSharp.so. Any line showing "not found" represents a missing system package.

### **2.3 Solution Strategy: Inference (ONNX Runtime)**

ONNX Runtime (ORT) is modular. The base package Microsoft.ML.OnnxRuntime contains the CPU runtime. Hardware accelerators (DirectML, CoreML) are separate add-ons.

The "DLL Hell" Risk:  
You cannot simply "add all packages."

* If you load DirectML on Linux, it will crash (DirectX doesn't exist).  
* If you load CoreML on Windows, it will crash (Apple frameworks don't exist).

Implementation Pattern: Safe Loading  
Do not use hard dependencies in your using statements if possible. Instead, use the RuntimeInformation check to conditionally register providers.  
// In OnnxInferenceEngine constructor  
var options \= new SessionOptions();

// 1\. Windows Strategy (DirectML)  
if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))  
{  
    try   
    {  
        // Explicitly requesting GPU 0\.  
        // REQUIRES: Microsoft.ML.OnnxRuntime.DirectML package  
        options.AppendExecutionProvider\_DML(0);  
    }  
    catch (Exception ex)  
    {  
        // Fallback: This catches scenarios where the user is on Windows 7   
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
        // supported by Apple NPU, it falls back to CPU for just that node, not the whole graph.  
        // REQUIRES: Microsoft.ML.OnnxRuntime.CoreML package  
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
    // highly optimized CPU runner (using AVX2/AVX512).   
    // ROCm (AMD GPU) support requires a custom Docker container build and is out of scope for a generic MVP.  
    options.AppendExecutionProvider\_CPU();  
}

### **2.4 Execution Provider Matrix**

This table details exactly how we achieve hardware acceleration on each target, balancing performance against compatibility.

| OS | Hardware Target | Execution Provider | NuGet Package | Technical Notes |
| :---- | :---- | :---- | :---- | :---- |
| **Windows** | Any GPU (AMD/NV/Intel) | **DirectML** | Microsoft.ML.OnnxRuntime.DirectML | **Recommended.** DirectML is a low-level abstraction layer in DirectX 12\. It works on *any* DirectX 12 compatible GPU, effectively abstracting vendor differences. It eliminates the need for strict CUDA version matching, which is the \#1 cause of support tickets in AI apps. |
| **Windows** | NVIDIA GPU | **CUDA** | Microsoft.ML.OnnxRuntime.Gpu | Faster raw throughput than DirectML, but brittle. Requires the user to have specific NVIDIA drivers and a specific CUDA Toolkit version installed. We avoid this for general distribution to prevent "it works on my machine" issues. |
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
dotnet publish \-c Release \-r win-x64 \--self-contained \-p:PublishSingleFile=true \-p:IncludeNativeLibrariesForSelfExtract=true

\# For Linux  
dotnet publish \-c Release \-r linux-x64 \--self-contained

## **3\. Model Engineering: Acquisition & Preparation**

Before writing code, you need a valid ONNX model file. This section details how to source, convert, and optimize models for the .NET runtime.

### **3.1 Acquisition Channels**

1. **Hugging Face (The "GitHub" of AI):**  
   * **Search:** Use the filter Library: ONNX on Hugging Face.  
   * **CLI Download:** Use the huggingface-cli to download specific files without cloning terabytes of data.  
     pip install huggingface\_hub  
     huggingface-cli download ultralytics/yolov8n-onnx yolov8n.onnx \--local-dir ./Assets

   * **Verification:** Ensure you download the .onnx file, not .pt (PyTorch) or .safetensors.  
2. **ONNX Model Zoo:**  
   * Best for standard academic models (ResNet-50, MobileNet, SSD).  
   * Repository: github.com/onnx/models  
   * **Tip:** These models often require specific normalization (e.g., Mean/Std subtraction) which is documented in their individual Readmes.

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
  from onnxruntime.quantization import quantize\_dynamic, QuantType

  model\_fp32 \= 'yolov8n.onnx'  
  model\_quant \= 'yolov8n.int8.onnx'

  quantize\_dynamic(  
      model\_fp32,  
      model\_quant,  
      weight\_type=QuantType.QUInt8  \# Quantize weights to 8-bit unsigned integers  
  )

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
    // Without this, input images in BGRA or Gray8 format will result in corrupt colors   
    // and severe accuracy loss (e.g. blue skies becoming red).  
    using var converted \= resized.Copy(SKColorType.Rgba8888);  
    ReadOnlySpan\<byte\> pixels \= converted.GetPixelSpan();  
    int bytesPerPixel \= resized.BytesPerPixel; 

    for (int y \= 0; y \< targetDim; y++)  
    {  
        for (int x \= 0; x \< targetDim; x++)  
        {  
            // Calculate the offset in the 1D byte array  
            int offset \= (y \* targetDim \+ x) \* bytesPerPixel;  
              
            // We are now guaranteed RGBA8888 by the conversion step above.  
            // We divide by 255.0f to normalize the range to 0.0-1.0  
              
            // Channel 0: Red  
            tensor\[0, 0, y, x\] \= pixels\[offset\] / 255.0f;       
              
            // Channel 1: Green  
            tensor\[0, 1, y, x\] \= pixels\[offset \+ 1\] / 255.0f;   
              
            // Channel 2: Blue  
            tensor\[0, 2, y, x\] \= pixels\[offset \+ 2\] / 255.0f;   
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

1. **NuGets:** Add Microsoft.ML.OnnxRuntime.DirectML and Microsoft.ML.OnnxRuntime.CoreML to the Core project. **Warning:** Ensure these package versions match the base Microsoft.ML.OnnxRuntime version EXACTLY to avoid runtime linking errors.  
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