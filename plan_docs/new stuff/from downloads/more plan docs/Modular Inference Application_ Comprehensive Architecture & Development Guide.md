# **Modular Inference Application: Comprehensive Architecture & Development Guide**

## **1\. Architectural Philosophy & Strategy**

To ensure future portability while leveraging **Avalonia's** cross-platform capabilities, we will adhere to **Clean Architecture**. This separates the "Brain" (Inference) from the "Body" (UI), ensuring that the volatile nature of UI frameworks never breaks your core intellectual property.

### **The "Dependency Rule"**

The golden rule is that **Dependencies flow inward**.

* **The UI (Avalonia)** depends on the Core.  
* **The Core** depends on *nothing* but standard .NET 8 libraries.  
* **The Core** does *not* know it is running inside an Avalonia app. It just receives bytes and returns data.

graph TD  
    subgraph "Infrastructure & UI (Volatile Layer)"  
        UI\[InferenceApp.UI (Avalonia)\]  
        Views\[AXAML Windows & Controls\]  
        VM\[ViewModels (CommunityToolkit.Mvvm)\]  
    end

    subgraph "Core Domain (Stable Layer)"  
        Core\[InferenceApp.Core\]  
        Interfaces\[IInferenceEngine\]  
        Models\[Domain Models (PredictionResult)\]  
        Logic\[OnnxInferenceEngine\]  
    end

    UI \--\>|Reference| Core  
    VM \--\>|Implements| Interfaces  
    VM \--\>|Uses| Models  
    Logic \--\>|Implements| Interfaces

## **2\. Model Strategy: Sourcing & Preparation (Pre-Requisite)**

**Crucial:** You cannot write the Core code until you have a model and understand its shape.

### **A. Sourcing the Model**

You do not need to train a model from scratch. You will likely source a pre-trained .onnx file.

1. **ONNX Model Zoo:** Good for standard computer vision tasks (ResNet, MobileNet, YOLO, SSD).  
2. **Hugging Face:** Search for models with the onnx tag.  
3. **Export:** If you have a PyTorch (.pt) or TensorFlow model, use torch.onnx.export to convert it.

### **B. The "Netron" Inspection (Mandatory)**

Before writing a single line of C\#, you must inspect the model to know what inputs it expects.

1. **Download:** [Netron](https://netron.app/) (Open source model viewer).  
2. **Inspect Input Node:** Click the input node (often named images, input, or data).  
   * **Shape:** Look for dimensions like 1x3x640x640 (Batch x Channels x Height x Width).  
   * **Meaning:** This tells you that you **MUST** resize every image to 640x640 in your C\# code before sending it to the engine.  
3. **Inspect Output Node:** Click the output node (e.g., output0).  
   * **Shape:** Look for dimensions like 1x84x8400 (YOLOv8 format).  
   * **Meaning:** This tells you how to parse the resulting float array into bounding boxes.

## **3\. Solution Breakdown & Dependencies**

We will create a Solution named InferenceApp.

### **A. Project: InferenceApp.Core (Class Library)**

* **Framework:** .NET 8.0  
* **Role:** The portable brain.  
* **NuGet Dependencies:**  
  * Microsoft.ML.OnnxRuntime (The CPU runtime).  
  * Microsoft.ML.OnnxRuntime.DirectML (Windows GPU acceleration).  
  * Microsoft.ML.OnnxRuntime.CoreML (macOS Neural Engine acceleration).  
  * SkiaSharp (Cross-platform image processing).  
  * Microsoft.Extensions.Logging.Abstractions (Generic logging).

### **B. Project: InferenceApp.UI (Avalonia App)**

* **Framework:** .NET 8.0  
* **Role:** The visual shell.  
* **NuGet Dependencies:**  
  * Avalonia  
  * Avalonia.Desktop  
  * Avalonia.Themes.Fluent  
  * CommunityToolkit.Mvvm (Source-generated MVVM).  
  * SkiaSharp.NativeAssets.Linux (Required for Linux rendering).

## **4\. Hardware Acceleration Implementation**

The OnnxInferenceEngine constructor must intelligently select the hardware accelerator based on the operating system.

**The "Switch" Logic:**

var options \= new SessionOptions();  
try {  
    if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows)) {  
        // Windows: DirectML (AMD/NVIDIA/Intel)  
        options.AppendExecutionProvider\_DML(0);  
    }  
    else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX)) {  
        // Mac: CoreML (Neural Engine)  
        options.AppendExecutionProvider\_CoreML(CoreMLFlags.COREML\_FLAG\_ENABLE\_ON\_SUBGRAPH);  
    }  
    else {  
        // Linux: CPU (safest default)  
        options.AppendExecutionProvider\_CPU();  
    }  
}  
catch (Exception ex) {  
    // Fallback if drivers are missing  
    \_logger.LogWarning("GPU provider failed. Falling back to CPU. Error: " \+ ex.Message);  
    options.AppendExecutionProvider\_CPU();  
}  
\_session \= new InferenceSession(\_modelPath, options);

## **5\. Detailed Component Design**

### **The Core (InferenceApp.Core)**

1. **PredictionResult (Model):**  
   * A clean C\# class (DTO).  
   * Properties: string Label, float Confidence, float X, float Y, float Width, float Height.  
   * *Note:* Store coordinates as normalized floats (0.0 to 1.0) so they apply to any screen size.  
2. **OnnxInferenceEngine (Service):**  
   * **Preprocessing:** Uses SkiaSharp to resize the incoming image to the dimensions found in Netron (e.g., 640x640).  
   * **Tensor Creation:** Converts the SKBitmap pixels into a DenseTensor\<float\>.  
     * **Critical:** Most vision models require **NCHW** format (Batch, Channel, Height, Width).  
     * **Logic:** You must transpose the pixel data loop: tensor\[0, c, y, x\] \= pixelVal / 255f. Failing to transpose from packed RGB will result in garbage predictions.  
   * **Inference:** Calls \_session.Run().  
   * **Postprocessing:** Filters the raw output array.  
     * **Note:** For object detection (e.g., YOLO), you often receive thousands of overlapping boxes. You must implement **Non-Maximum Suppression (NMS)** to deduplicate them into clean PredictionResult objects.

### **The UI (InferenceApp.UI)**

1. **MainViewModel:**  
   * \[ObservableProperty\] SKBitmap DisplayImage: The image shown on screen.  
   * \[ObservableProperty\] ObservableCollection\<PredictionResult\> Detections: The list of found objects.  
   * \[RelayCommand\] LoadImage(): Opens file picker.  
   * \[RelayCommand\] RunInference(): Calls the engine.  
2. **MainWindow.axaml:**  
   * **Image Control:** Binds to DisplayImage.  
   * **Canvas Overlay:** An ItemsControl strictly positioned *over* the image. It binds to Detections and generates a \<Border\> (rectangle) for each detection.

## **6\. Step-by-Step Development Roadmap**

### **Phase 1: The Foundation (Core)**

*Goal: A working library that can load a model and output dummy data.*

1. **Create Solution:** dotnet new sln \-n InferenceApp  
2. **Create Core:** dotnet new classlib \-n InferenceApp.Core  
3. **Add NuGets:**  
   * dotnet add InferenceApp.Core package Microsoft.ML.OnnxRuntime  
   * dotnet add InferenceApp.Core package SkiaSharp  
4. **Create Interface:** IInferenceEngine.cs.  
5. **Create Service:** OnnxInferenceEngine.cs. Implement the Constructor to load the .onnx file.  
6. **Unit Test:** Create a console app to verify new OnnxInferenceEngine("model.onnx") does not crash.

### **Phase 2: The Visuals (Avalonia)**

*Goal: A window that can load and display an image.*

1. **Install Templates:** dotnet new install Avalonia.Templates  
2. **Create UI:** dotnet new avalonia.app \-n InferenceApp.UI  
3. **Reference Core:** dotnet add InferenceApp.UI reference InferenceApp.Core  
4. **Add MVVM:** dotnet add InferenceApp.UI package CommunityToolkit.Mvvm  
5. **Implement Layout:** In MainWindow.axaml, add a Grid with a Button ("Load Image") and an Image control.  
6. **Wire Logic:** Use StorageProvider (Avalonia's file picker) to pick a file, load it into SKBitmap, and display it.

### **Phase 3: The Brain (Integration)**

*Goal: Connect the UI button to the Core inference.*

1. **Tensor Logic:** In OnnxInferenceEngine, implement the PredictAsync method. Write the loops to convert SKBitmap \-\> float\[\] \-\> DenseTensor.  
2. **Dependency Injection:** In App.axaml.cs, create the OnnxInferenceEngine instance and pass it to MainViewModel.  
3. **Threading:** In MainViewModel, wrap the inference call in Task.Run().  
   * **Crucial:** When adding results to ObservableCollection, you **must** marshal back to the UI thread using Dispatcher.UIThread.InvokeAsync(...) or the app will crash.  
4. **Drawing:** Update MainWindow.axaml to overlay rectangles based on the results.

### **Phase 4: Acceleration & Polish**

*Goal: Make it fast and cross-platform ready.*

1. **Add GPU Support:**  
   * dotnet add InferenceApp.Core package Microsoft.ML.OnnxRuntime.DirectML  
   * dotnet add InferenceApp.Core package Microsoft.ML.OnnxRuntime.CoreML  
2. **Implement Switch:** Add the RuntimeInformation checks in the Core constructor.  
3. **Logging:** Inject an ILogger to see if DirectML loads successfully or falls back to CPU.

## **7\. Troubleshooting & Pitfalls**

1. **Linux "DllNotFoundException":**  
   * *Cause:* Linux is missing the native Skia library.  
   * *Fix:* Ensure InferenceApp.UI references SkiaSharp.NativeAssets.Linux.  
2. **"System.Drawing is not supported":**  
   * *Cause:* You accidentally used System.Drawing.Bitmap.  
   * *Fix:* Use SkiaSharp.SKBitmap exclusively.  
3. **Mac "Unsigned Application":**  
   * *Cause:* MacOS security.  
   * *Fix:* You may need to codesign your published app before it runs on another Mac.