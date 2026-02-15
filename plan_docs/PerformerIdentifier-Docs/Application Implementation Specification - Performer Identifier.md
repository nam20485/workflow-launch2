# **Performer Identifier \- Application Implementation Specification**

## **New Application**

**App Title:** Performer Identifier

## **Development Plan**

**Methodology:** Phased implementation using **Clean Architecture** principles to ensure modularity and testability. The development lifecycle is structured into four distinct phases, totaling approximately 22 days, to mitigate technical risk early and ensure a polished final product.

1. **Phase 1: Foundation & Core Infrastructure (Days 1-5)**  
   * **Objective:** Establish the solution skeleton and implement the platform-agnostic domain logic.  
   * **Key Tasks:**  
     * Initialize the Visual Studio Solution (.sln) with the strict three-layer project structure (Core, Windows, App).  
     * Define core interfaces (IFaceDetectionService, IVideoFrameExtractor, IPerformerRepository) in the PerformerIdentifier.Core library.  
     * Implement the WindowsImageData service to bridge SoftwareBitmap and DirectML tensors.  
     * Set up dependency injection containers within App.xaml.cs.  
   * **Deliverable:** A compiling solution with passing unit tests for the core logic (mocked dependencies).  
2. **Phase 2: UI Construction & Media Integration (Days 6-10)**  
   * **Objective:** Build the visible layer of the application using WinUI 3\.  
   * **Key Tasks:**  
     * Construct the MainWindow.xaml layout using a Grid-based design for responsive resizing.  
     * Implement the MediaPlayerElement for handling video playback.  
     * Create the overlay system: a transparent Canvas or ItemsControl layered precisely over the video player to draw bounding boxes.  
     * Bind the UI controls to the MainViewModel using the CommunityToolkit.Mvvm \[RelayCommand\] and \[ObservableProperty\] attributes.  
   * **Deliverable:** A functional GUI where users can open video files and see them play, with placeholder graphical overlays.  
3. **Phase 3: Intelligence Pipeline & Logic Integration (Days 11-15)**  
   * **Objective:** Connect the "Brain" (AI) to the "Body" (UI).  
   * **Key Tasks:**  
     * Integrate the VideoProcessorService to orchestrate frame extraction via FFmpeg.  
     * Wire up the FaceDetectionService (ONNX Runtime) to process extracted frames.  
     * Implement the embedding matching logic: compare the 512-float vector of a detected face against the SQLite database of known performers using Cosine Similarity.  
     * Enable the PerformerDatabase Context to save and retrieve "Known" face embeddings.  
   * **Deliverable:** A fully working application that identifies faces in video, albeit potentially unoptimized.  
4. **Phase 4: Optimization, Polish & Packaging (Days 16-22)**  
   * **Objective:** Refine performance, handle edge cases, and prepare for distribution.  
   * **Key Tasks:**  
     * **FPS Tuning:** Optimize the DirectML tensor binding and ensure FFmpeg frame extraction does not block the UI thread.  
     * **Error Handling:** Implement robust try/catch blocks for corrupted video files or missing ONNX models, displaying user-friendly ContentDialog messages.  
     * **Packaging:** Create the MSIX installer manifest, ensuring all DLLs (DirectML, FFmpeg binaries) are correctly packaged.  
   * **Deliverable:** The final Release candidate ready for deployment.

## **Description**

The **Performer Identifier** is a specialized, local desktop application designed for privacy-conscious users who need to analyze video content to identify specific individuals. Unlike cloud-based solutions (e.g., AWS Rekognition, Azure Face API), which require uploading sensitive video data to remote servers, this application runs entirely on the user's local hardware (Edge AI).

It leverages advanced Deep Learning models—specifically **RetinaFace/SCRFD** for detection and **ArcFace** for recognition—to scan video frames. By utilizing **DirectML**, the application taps into the raw power of Windows-compatible GPUs (NVIDIA, AMD, Intel) to accelerate inference, making real-time analysis possible on consumer-grade hardware. The tool allows users to build a personal "Library of Performers" by tagging unknown faces, effectively training the system to recognize those individuals in future videos.

## **Overview**

The application architecture is strictly governed by the **Dependency Rule** (Clean/Onion Architecture) to decouple high-performance AI logic from the user interface. This ensures that the AI core remains portable and testable.

* **The Core (Domain Layer):**  
  * This is the "Brain" of the application. It contains the *Enterprise Business Rules*.  
  * It defines the *Entities* (Performer, FaceDetectionResult) and the *Interfaces* for services (IFaceDetectionService).  
  * It implements the platform-agnostic logic for the VideoProcessorService, which manages the timeline of the video and aggregates results.  
  * *Dependencies:* None. It does not know about WinUI, FFmpeg, or specific GPU APIs.  
* **The Infrastructure (Windows Layer):**  
  * This layer acts as the bridge to the hardware.  
  * **GPU Dispatching:** Implements IFaceDetectionService using Microsoft.ML.OnnxRuntime.DirectML. It handles the complex task of converting standard images into hardware-accelerated tensors.  
  * **Media Extraction:** Implements IVideoFrameExtractor using a wrapper around the **FFmpeg** CLI tool to seek specific timestamps and extract raw pixel data efficiently.  
* **The UI (Application Layer):**  
  * The "Presentation" layer built with **WinUI 3**.  
  * **Orchestration:** It is responsible for Composition Root (Dependency Injection) setup.  
  * **Interaction:** Handles file pickers, video playback controls (Play/Pause/Seek), and the visualization of inference results (drawing red/green boxes around faces).  
  * **State Management:** Uses the **MVVM (Model-View-ViewModel)** pattern to keep the UI responsive, processing the heavy AI workload on background threads while updating the UI via the Dispatcher.

## **Document Links**

* [01-Development-Plan.md](https://www.google.com/search?q=./01-Development-Plan.md) \- Comprehensive 22-day timeline, detailed task breakdown, and success criteria.  
* [02-Architecture-Guide.md](https://www.google.com/search?q=./02-Architecture-Guide.md) \- In-depth system design patterns, layer definitions, and dependency flow diagrams.  
* [03-Model-Acquisition-Guide.md](https://www.google.com/search?q=./03-Model-Acquisition-Guide.md) \- Step-by-step instructions for sourcing, verifying, and optimizing the necessary ONNX models.  
* [Complete Code Reference.md](https://www.google.com/search?q=./Complete%2520Code%2520Reference.md) \- Full, copy-paste ready source code for all 14 core components of the system.

## **Requirements**

### **Functional Requirements**

1. **Video Ingestion & Parsing:**  
   * The system must use the Windows File Picker to securely access user files.  
   * It must support importing standard formats: **MP4, AVI, MKV, and MOV**.  
   * It must automatically extract metadata (Resolution, Frame Rate, Duration) upon loading.  
2. **Face Detection Engine:**  
   * The system must utilize the RetinaFace or SCRFD ONNX model to detect human faces.  
   * It must support a configurable **Confidence Threshold** (default \> 0.5) to filter out noise/false positives.  
   * It must return Bounding Box coordinates ![][image1] relative to the frame size.  
3. **Face Recognition & Matching:**  
   * The system must crop detected faces and pass them to the ArcFace model to generate a **512-dimensional floating-point embedding**.  
   * It must calculate **Cosine Similarity** between the detected face and stored Performer embeddings.  
   * A match is declared if the similarity score exceeds the defined threshold (e.g., \> 0.45).  
4. **Performer Library Management:**  
   * **Add:** Users must be able to "Enroll" a new performer by selecting a face from a video frame and assigning a name.  
   * **Persist:** Performer data (Name \+ Embedding Vector) must be stored in a local SQLite database.  
   * **List:** Users must be able to view a list of all currently enrolled performers.  
5. **Smart Playback & Overlay:**  
   * The application must contain a video player capable of smooth playback.  
   * **Synchronization:** Bounding boxes must be drawn in sync with the video. If the video is at timestamp 00:15, the overlay must show detection results for that specific second.  
   * **Visual Feedback:** Known performers should have their names displayed above the box; Unknown faces should be labeled "Unknown" or color-coded differently.  
6. **Data Export:**  
   * Users must be able to export the analysis report to a **JSON file**.  
   * The schema should include: Video Filename, List of Appearances (Performer Name, Timestamp Start, Timestamp End).

### **Non-Functional Requirements (NFRs)**

1. **Performance & Throughput:**  
   * **Inference Speed:** Must exceed **10 FPS** on standard consumer hardware (e.g., NVIDIA GTX 1060 or better) using DirectML acceleration.  
   * **Startup Time:** Application must launch and be ready for input in under 3 seconds.  
2. **Accuracy & Reliability:**  
   * **False Positives:** Target \< 5% false identifications for clear, frontal face angles.  
   * **Detection Rate:** Target \> 90% detection rate for faces occupying at least 10% of the frame height.  
3. **Responsiveness & Threading:**  
   * **Non-Blocking UI:** The UI thread (Main Thread) must *never* be blocked by inference or IO operations. All heavy lifting must occur on Task.Run background threads.  
   * **Cancellation:** Users must be able to stop/cancel a processing job instantly without crashing the app.  
4. **Privacy & Security:**  
   * **Offline Only:** No telemetry, video data, or face data may be sent to any external server.  
   * **Local Storage:** All database files (performers.db) and settings are stored in the user's AppData or local application folder.

## **Features**

* **Smart Video Player:**  
  * An integrated media player that goes beyond simple playback. It features a transparent canvas overlay that acts as a "Head-Up Display" (HUD) for the AI, drawing dynamic bounding boxes and text labels that track faces as they move across the screen.  
* **Batch Processing Queue (Future):**  
  * Architecture is designed to support a "Batch Mode" where users can drop a folder of videos, and the system processes them sequentially in the background, generating a combined report.  
* **Performer Database:**  
  * A robust, SQLite-backed library. It stores the mathematical representation of faces (embeddings), allowing the system to recognize a person even if they appear in a different video, under different lighting, or with a slightly different expression.  
* **Adaptive Hardware Acceleration:**  
  * The system implements a "Strategy Pattern" for hardware execution. It attempts to load **DirectML** (GPU) first. If a compatible GPU is not found or fails, it seamlessly falls back to the **CPU execution provider**, ensuring the app works on any Windows machine (albeit slower).

## **Test Cases**

1. **Model Loading & Initialization:**  
   * *Action:* Launch application without detection.onnx in the folder.  
   * *Expected:* Application displays a clear error dialog: "Critical Error: Model files missing. Please ensure 'Models/detection.onnx' exists." Application does not crash.  
2. **Frame Extraction Integrity:**  
   * *Action:* Load a 60-second video and request extraction of frame at 00:30.  
   * *Expected:* FFmpeg process spawns, extracts a single PNG to temp, and returns an IImageData object. No lingering ffmpeg.exe processes remain in Task Manager after the operation.  
3. **Recognition Accuracy Verification:**  
   * *Action:* Enroll "Actor A" using a clear frontal image. Load a new video containing "Actor A".  
   * *Expected:* The system draws a box around the face and labels it "Actor A" with a confidence score visible in debug logs.  
4. **Unknown/Threshold Handling:**  
   * *Action:* Process a video with a person NOT in the database.  
   * *Expected:* The face is detected (Red Box), but the recognition label is either "Unknown" or the box is filtered out depending on view settings. It must NOT incorrectly label them as "Actor A".  
5. **Concurrency & UI Responsiveness:**  
   * *Action:* Click "Process Video" on a 4K file. Immediately try to drag the application window or click the "Settings" button.  
   * *Expected:* The window moves smoothly. The UI remains interactive. The "Process" button changes to a "Cancel" button.

## **Logging**

* **Console/Debug Output:**  
  * Uses System.Diagnostics.Debug.WriteLine for immediate developer feedback during debugging sessions (e.g., "Frame 102 processed in 45ms").  
* **Runtime Logging (ILogger):**  
  * Integrates Microsoft.Extensions.Logging (via Serilog or built-in providers) to capture critical operational events.  
  * **Events Logged:**  
    * Application Startup/Shutdown.  
    * DirectML Device Selection (e.g., "Using GPU: NVIDIA RTX 3080").  
    * Inference Errors (e.g., "Dimension mismatch in tensor").  
    * FFmpeg exit codes.

## **Containerization: Docker**

* *Current Status:* Not applicable for this specific release. This is a **Desktop Client** relying on Windows-specific UI frameworks (WinUI 3\) and hardware APIs (DirectML) that are not easily containerized in standard Linux Docker environments.  
* *Future Scope:* The PerformerIdentifier.Core library is .NET Standard compatible. A future "Headless Server" version could be wrapped in a Docker container to expose a REST API, processing videos uploaded via HTTP.

## **Containerization: Docker Compose**

* *N/A* \- No multi-container orchestration is required for the single-user desktop application.

## **Swagger/OpenAPI**

* *N/A* \- This is a local GUI application, not a Web API. No HTTP endpoints are exposed.

## **Documentation**

* **User Guide:**  
  * "Getting Started": Installation and first-run setup.  
  * "Library Management": Detailed guide on adding, renaming, and deleting performers from the database.  
  * "Troubleshooting": Solutions for common issues like "Video codec not supported" or "Slow performance."  
* **Developer Guide:**  
  * **Architecture Overview:** UML diagrams of the Clean Architecture layers.  
  * **Environment Setup:** Instructions for installing the .NET 10 SDK, Visual Studio 2022 workloads (Desktop Dev), and FFmpeg binaries.  
  * **Model Sourcing:** Where to download RetinaFace and ArcFace models and how to name them.

## **Acceptance Criteria**

* \[ \] **Compilation:** The solution builds in Visual Studio 2022 (Release Mode) with zero errors and zero warnings.  
* \[ \] **Media Playback:** User can open MP4, MKV, and AVI files; video renders correctly in the UI.  
* \[ \] **End-to-End Inference:** Clicking "Process" initiates the pipeline: Extract Frame \-\> Detect Face \-\> Recognize \-\> Update UI.  
* \[ \] **Persistence:** Enrolled performers are saved to SQLite. Closing and reopening the app retains the database.  
* \[ \] **Resource Utilization:** Task Manager confirms GPU usage (Compute/3D) during inference, validating DirectML is active.  
* \[ \] **Stability:** The application can process a 10-minute video without crashing or leaking memory (RAM usage remains stable).

## **Language**

* **C\#** \- Selected for its robust type safety, extensive standard library, and seamless integration with the Microsoft ecosystem (WinUI 3, DirectML).

## **Language Version**

* **.NET v10**  
  * **Reasoning:** Utilizing the latest .NET release to take advantage of performance improvements, enhanced language features, and modern runtime capabilities for WinUI 3 framework and compatibility with the Microsoft.ML.OnnxRuntime packages.

## **Include global.json?**

* Yes.  
  {  
    "sdk": {  
      "version": "10.0.0",  
      "rollForward": "latestFeature"  
    }  
  }

  * *Purpose:* Locks the SDK version to ensure all developers and CI/CD pipelines build against the exact same toolchain, preventing "works on my machine" issues.

## **Frameworks, Tools, Packages**

### **Core Technologies**

* **App Framework:** **WinUI 3 (Windows App SDK 1.5+)**  
  * The modern native UI stack for Windows, offering fluid animations, modern controls, and high-DPI support.  
* **ML Engine:** **ONNX Runtime (v1.17+)**  
  * A high-performance inference engine for machine learning models. Chosen for its wide hardware support and interoperability.  
* **Database:** **SQLite** with **Entity Framework Core (v8.0)**  
  * Lightweight, serverless relational database suitable for embedded local storage. EF Core provides a strongly-typed ORM layer.  
* **Video Engine:** **FFmpeg** (External CLI tool)  
  * The industry standard for video and audio processing. Used here for precise frame extraction and format decoding.

### **Key NuGet Packages & Justification**

1. Microsoft.WindowsAppSDK: Required for the WinUI 3 runtime and windowing system.  
2. Microsoft.ML.OnnxRuntime.DirectML: Provides the GPU-accelerated execution provider for Windows.  
3. Microsoft.ML.OnnxRuntime: The base runtime; used as a fallback if DirectML fails (CPU execution).  
4. SixLabors.ImageSharp: A fully managed, cross-platform image manipulation library. Used to crop faces, resize images to model input dimensions (e.g., 112x112), and normalize pixel data.  
5. CommunityToolkit.Mvvm: Reduces boilerplate code for implementing INotifyPropertyChanged and ICommand in the ViewModel layer.  
6. Microsoft.EntityFrameworkCore.Sqlite: The specific provider to allow EF Core to talk to the local performers.db file.

## **Project Structure/Package System**

The solution is organized into a modular **Clean Architecture** to ensure separation of concerns and maintainability.

PerformerIdentifier.sln  
├── src  
│   ├── PerformerIdentifier.Core       \# \[Class Lib\] The Domain Layer  
│   │   ├── Interfaces/                \# Contracts (IFaceDetectionService, etc.)  
│   │   ├── Entities/                  \# Domain models (Performer, DetectionResult)  
│   │   ├── Services/                  \# Business logic (VideoProcessorService)  
│   │   └── Data/                      \# Database Context definitions  
│   │  
│   ├── PerformerIdentifier.Windows    \# \[Class Lib\] The Infrastructure Layer  
│   │   ├── Services/                  \# DirectML & FFmpeg specific implementations  
│   │   └── Imaging/                   \# Bitmap \<-\> Tensor conversion logic  
│   │  
│   └── PerformerIdentifier.App        \# \[WinUI 3\] The Presentation Layer  
│       ├── Views/                     \# XAML Windows and UserControls  
│       ├── ViewModels/                \# UI Logic and State  
│       └── Assets/                    \# Icons and default images  
│  
└── tests  
    └── PerformerIdentifier.Tests      \# \[XUnit\] Unit Test Project  
        └── Services/                  \# Tests for Core logic using Moq

## **GitHub**

* **Repo:** https://github.com/intel-agency/PerformerIdentifier  
* **Visibility:** Public  
* **Branch Strategy:**  
  * main: The stable, production-ready code.  
  * develop: The integration branch for ongoing work.  
  * feature/\*: Short-lived branches for specific tasks (e.g., feature/video-player, feature/database-migration).

## **Deliverables**

1. **Source Code:** A clean, zipped archive or Git repository access containing the complete Visual Studio Solution (.sln), ensuring all project files and assets are included.  
2. **Binaries (Release Build):**  
   * A self-contained **MSIX installer** (signed with a test certificate) or a "Sideload" folder structure.  
   * Must include the runtimes folder populated with onnxruntime.dll and DirectML.dll.  
3. **Model Assets:**  
   * A pre-configured Models/ directory containing the validated detection.onnx and recognition.onnx files, ensuring the user doesn't need to hunt for them immediately.  
4. **Database Template:**  
   * An initialized performers.db file (with migration history applied) so the app works immediately upon first launch.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFgAAAAZCAYAAAC1ken9AAAE70lEQVR4Xu2Z34tVVRTHzx2l7KdaTGPz454zP2ya6ac+hGK/pAd7CXzoxUhQkRSkhyIosRCUSqIUooaYHhIpCGOiIkYF50VB8GEgJELwxXf/iOnzvWfvYd3VOfeeceapOV9YnLPXWnvttddee+19z02SGjX+dxgcHBzLsux5z6/RjuHh4WdFnt8RzWZzB3SWAG/yshrtUIyI1c+eX4qRkZH1dHqP14aXrTKsSdN0K7G4wXPBCx0aBPm3SgmJ4l4MDnv+agWxmIOuer4Hwf29a2JSS/qkmHRSWmUguHdIuu883wO9g9A1dEe8LGINwT2FwiUvWK0gHusU4KGhoZe8zAPdDej+UroYY2NjvSjMQlNeFtCgPjeR7+SGcZ8Y9LmXrH9Zme+VO6Gvr+8BHHlR5GW9vb0Pel4n4M8W+eDYDXx7mOdaNTT5SvXRgcD2qzxkOV6Bdmk8rxfQQHaitJzg5HMI/4GOeZkA/yT0E4McJTAXed/O8wdlPXTF63eC7ND3c55/amENfyt0y+p2wsDAwKPon4Z+ZPGfiHxsvwHvDn7tURLw/hW8M5OTk/fY/t2gOULnsPOR4qK5yr+yJEC+T+N6fgvhcFvQKnkZvG39/f33xzZ68yolIevnS40WQLY0aXbBI/SbIUueFl/2tb2q2lKtQ3c6BPBru41pzyK/zhibg+5G2bZz6IYsLw9T0CdJ2AkCdo4j221UF6EdqRh6fgsxwEXbFv4B15ZeKyN4vgbtsPJOoO9beiogCmbMBpzOaF+F5tp7FENlgXHfoduT9JnXdo4y2rehc+Pj4w8Z3olkCYd3KA9zWsjIM0mw3epG3HWAPYLeXs9fAnTHVMlZdCYGPC0/AwqR5qe37CwGT+3UlbqyrCuDgih/bNbHJLCLaVEpwFlBibAIg8za2rlUROeh7yMvZEalE9uCfteb5uYjv8SL5UFQlpfVzSKEnXnGBquI59ExwDjxqoRFmanf2tALQW+XBooHRqjD01Y/bM0ey7OIi5maLFNmQHM+O7odTMHnxauRggnvgg5Ao3MwvkcoM8tsh0W6JJ8ir5nXfN1ztZi6MXwM7TTdWrEpDbAx2rZFYy2CJpA/1cxvEB8k+ZbUT8SzmbkChcNrIc0ztLBWpeG2AH2hNn2eUR/sHHZ6x4KtwpuNgGwGuqZ3ZSnv32LnRhY+VPE8moa6b/pEu4XByPLbgOTvG94e8ZQc0IfeZtLtmha3QFghC9XLI9B0WIAJ6C8GPM/zV+hxp6+BbkM35ZSTRfRg6+2gdxm6kBYsSBjrJvSN5Vsg28I4f6T5deoKtD+0/w68/Ym5BYQ+E9INPq6zMgHfPpNvyLZFHu+bwpwvI383cTazbj80BJR2y7DnC9pycUtpe6mtD0NeLwJb+2TP8y3CqbxRn0a1eL48CCHIJz3foUf+mDqrH0XrbZkogmwXlQn5Febmbx1rtUMdr4X4O4J5vOllFg2Ccihd5seeZl6vThcdLLGEoHNcbY2lbFKGeF0B/ql4V15J6P4s255/t8jyjz2Hkv8uSjuUUVm3r0JdkOZ18HXPFxRgZOeVtWrrXQH2egEqN58mbjuuAHR2qETJ9kpAfs5Uvlkx+MVsGf9m6BBIyoMiZ1QfvxSp3o2Ojj7mlQT4Q2WZvRzILmNPrZRt5jAZb1mVUf9lVA2Ur1HVcs+vUaNGjYr4F3CUUYBXO4JrAAAAAElFTkSuQmCC>