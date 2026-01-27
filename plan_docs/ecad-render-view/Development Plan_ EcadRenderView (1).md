# **Development Plan: EcadRenderView**

## **1\. Executive Summary & Requirements**

**Project Name:** EcadRenderView

**Goal:** Create a robust, high-performance client-server system designed to parse proprietary ECAD JSON files, render complex PCB layouts in 2D with high fidelity, and export these visualizations to standard documentation formats (PDF, SVG, and PNG). The solution prioritizes separation of concerns, data integrity, and cross-platform compatibility.

### **Core Requirements**

1. **Parsing & Validation:**  
   * Implement a rigorous parsing engine capable of ingesting the proprietary ECAD JSON format.  
   * The system must go beyond simple deserialization to actively validate the logical integrity of the board design.  
   * It must identify and reject invalid boards based on strict rules, specifically covering the 14 known failure cases (e.g., missing layers, invalid net references, geometric inconsistencies).  
   * Rejections must be accompanied by precise, descriptive error messages to guide the user in correcting the source file.  
2. **Visualization:**  
   * Render the Board Boundary as a precise clip path or outline.  
   * Draw Components with accurate positioning and rotation transformations.  
   * Render Traces (tracks) with correct widths, color-coded by layer.  
   * Render Vias and Keepouts (restricted areas) with distinct visual styles.  
   * Ensure the rendering engine handles coordinate systems (Microns vs. Millimeters) seamlessly.  
3. **Architecture:**  
   * Adopts a **Client-Server model** to decouple heavy processing from the presentation layer.  
   * **Backend:** ASP.NET Core 10.0 Web API. Responsibilities include File I/O, parsing logic, geometric validation, unit normalization, and **Caching** of processed models to optimize performance for repeated access.  
   * **Frontend:** Avalonia UI. A cross-platform Desktop Client responsible for hardware-accelerated rendering and user interaction (Zoom/Pan/Toggle).  
4. **Export:**  
   * Generate high-fidelity, vector-based SVG and PDF exports that maintain the visual quality of the on-screen render.  
   * Generate high-resolution raster PNG images for quick previews or reports.  
   * Ensure "Write Once, Render Anywhere" consistency between the GUI and exported files.  
5. **Quality Assurance:**  
   * **Automated Testing:** Comprehensive testing suite using xUnit.  
   * **Backend:** Unit tests for parser logic and validation rules; Integration tests for API endpoints.  
   * **Frontend:** Headless UI testing via Avalonia.Headless to verify view models and rendering logic without a physical display.  
   * **Assertions:** Use FluentAssertions for readable test code.  
6. **DevOps:**  
   * Containerization via Docker for the Backend API to ensure consistent deployment environments using .NET 10 images.  
   * Continuous Integration/Continuous Deployment (CI/CD) pipelines using GitHub Actions to automate builds, testing, and artifact generation.

## **2\. User Stories**

### **Epic 1: File Ingestion & Caching**

*Focus: Getting data into the system securely and efficiently.*

| ID | Title | User Story | Acceptance Criteria |
| :---- | :---- | :---- | :---- |
| **US-1.1** | **Upload Board (Load)** | As a user, I want to upload a JSON file so that the server can parse, validate, and cache the result for rendering. | 1\. The API exposes POST /api/board/load which accepts multipart/form-data. 2\. The server processes the file and returns a unique boardId (GUID) upon success. 3\. The parsed result is stored in IMemoryCache with an absolute expiration (e.g., 1 hour) to manage server memory. 4\. Large files (\>10MB) are handled gracefully or rejected with a 413 Payload Too Large. |
| **US-1.2** | **Retrieve Board (Fetch)** | As a frontend client, I want to fetch the parsed board data using a unique ID, so I can render it without re-uploading. | 1\. The API exposes GET /api/board/{id}. 2\. If the ID exists in cache, the server returns the full BoardDto JSON. 3\. If the ID is expired or invalid, the server returns a standard 404 Not Found. 4\. The response includes appropriate Cache-Control headers. |
| **US-1.3** | **Validation Feedback** | As a designer, I want to see specific, actionable error messages if my board file is invalid, so I can fix the source design. | 1\. If parsing or validation fails, the POST response returns 400 Bad Request. 2\. The response body contains a structured list of errors (e.g., \[{ "code": "LAYER\_MISSING", "message": "Layer 'TOP' is referenced but not defined." }\]). 3\. The UI displays these errors in a prominent dialog or error panel. |
| **US-1.4** | **Unit Normalization** | As a system, I need to handle boards defined in different units (Millimeters or Microns) automatically to ensure consistent rendering scale. | 1\. The Backend parser detects the designUnits field in the JSON metadata. 2\. If units are Millimeters, all coordinate values are multiplied by 1000 to convert to Microns. 3\. The resulting BoardDto always contains integer-based Micron coordinates, simplifying frontend logic. |

### **Epic 2: Visualization & Interaction**

*Focus: The user experience of viewing and manipulating the PCB layout.*

| ID | Title | User Story | Acceptance Criteria |
| :---- | :---- | :---- | :---- |
| **US-2.1** | **Render Board** | As a user, I want to see the visual representation of the board immediately after fetching the data. | 1\. The board renders within the central canvas area. 2\. The Board Boundary forms a visual outline or clipping mask. 3\. Components are drawn at their specific coordinates with correct rotation applied. 4\. Traces and Vias are rendered according to their geometric properties (width, diameter). |
| **US-2.2** | **Layer Visibility** | As a reviewer, I want to toggle specific copper layers on or off to inspect complex internal routing without visual obstruction. | 1\. The application Sidebar populates a list of all layers found in the board's Stackup. 2\. Each layer has an associated checkbox to toggle visibility. 3\. Toggling a checkbox triggers an immediate redraw of the canvas, hiding or showing the associated elements (traces, pads). |
| **US-2.3** | **Zoom & Pan** | As a user, I want to navigate the board view smoothly to inspect fine details like 0201 pads or thin traces. | 1\. Scrolling the mouse wheel zooms the view in and out, centered on the mouse cursor. 2\. Clicking and dragging the middle mouse button (or holding Space) pans the viewport. 3\. Zoom levels are clamped to prevent getting lost (e.g., min 0.1x, max 100x). 4\. Navigation performance maintains 60 FPS for standard boards. |

### **Epic 3: Export & Output**

*Focus: Generating artifacts for external use.*

| ID | Title | User Story | Acceptance Criteria |
| :---- | :---- | :---- | :---- |
| **US-3.1** | **Export PDF/SVG/PNG** | As a documentation engineer, I want to save the current view to standard documentation formats for reports and datasheets. | 1\. An "Export" menu provides options for PDF, SVG, and PNG. 2\. **PDF/SVG:** The output preserves vector paths, ensuring text is selectable and lines remain sharp at any zoom level. 3\. **PNG:** The output is a raster image, respecting the current viewport or full board extent. 4\. All exports respect the currently visible layers (e.g., hidden layers are not exported). |

## **3\. Detailed Step-by-Step Implementation Plan**

### **Phase 0: Project Scaffolding**

*Goal: Initialize the solution structure ensuring clean separation of concerns and dependency management.*

1. **Create Solution (EcadRenderView.sln):** Establish the root solution file.  
2. **Create EcadRender.Shared (Class Library):**  
   * Target **.NET 10**.  
   * **DTOs:** Define robust data transfer objects (BoardDto, ComponentDto, TraceDto) that represent the normalized board data.  
   * **Enums:** Define UnitType (Micron/Millimeter) and LayerType (Top/Bottom/Inner/Plane).  
   * **Results:** Create a ParsingResult\<T\> wrapper to handle success/failure states uniformly.  
3. **Create EcadRender.Api (ASP.NET Core 10.0 Web API):**  
   * Add project reference to Shared.  
   * Configure Dependency Injection (DI) containers.  
   * Setup IMemoryCache for storing parsed board models.  
4. **Create EcadRender.Desktop (Avalonia UI):**  
   * Target **.NET 10**.  
   * Add project reference to Shared.  
   * Install NuGet packages: Avalonia.Diagnostics, SkiaSharp, SkiaSharp.NativeAssets.\*.

### **Phase 1: The Parsing Engine & Caching (Backend)**

*Goal: Build the "Brain" of the application that handles data ingestion and integrity.*

1. **Implement BoardParser Service:**  
   * Utilize System.Text.Json for high-performance, low-allocation deserialization.  
   * Implement UnitConverter: Logic to detect designUnits and normalize all spatial data (Points, LineStrings, Rectangles) to Microns.  
2. **Implement ValidationEngine (The "14 Checks"):**  
   * **Stackup:** Ensure layer indices are sequential and unique.  
   * **Components:** Verify that component pins map to valid net names defined in the netlist.  
   * **Traces:** Ensure traces reference valid layer names existing in the stackup.  
   * **Geometry:** Check for degenerate geometries (e.g., negative width, zero-length paths).  
3. **Implement Caching Logic:**  
   * **Endpoint 1 (POST /load):** Orchestrates the Parse \-\> Validate \-\> Normalize flow. Stores the valid BoardDto in IMemoryCache keyed by a new Guid. Returns the Guid to the client.  
   * **Endpoint 2 (GET /{id}):** specific retrieval endpoint. Checks cache for the Guid. If found, returns the DTO; otherwise, 404\.  
4. **Dockerization:**  
   * Create a multi-stage Dockerfile for the API using **.NET 10** SDK and Runtime images.  
   * Create docker-compose.yml to orchestrate the service, exposing port 8080\.

### **Phase 2: Testing Infrastructure**

*Goal: Ensure reliability through automated verification.*

1. **Backend Tests (EcadRender.Api.Tests):**  
   * **Libraries:** xUnit (Runner), FluentAssertions (Readable assertions), Moq (Dependency mocking).  
   * **Scope:** Extensive unit tests for BoardParser and ValidationEngine. Load the 14 known "bad" files and assert that specific validation errors are raised.  
2. **Frontend Tests (EcadRender.Desktop.Tests):**  
   * **Libraries:** xUnit, Avalonia.Headless (runs UI tests without a GPU/Display), FluentAssertions.  
   * **Scope:** Test ViewModel state transitions (e.g., loading state \-\> success state). Verify Command execution logic.

### **Phase 3: The Rendering Core (Shared/Client)**

*Goal: Establish the "Draw Once, Render Everywhere" rendering pipeline.*

1. **Create BoardRenderer Class:**  
   * Define a static or stateless method: void Render(SKCanvas canvas, BoardDto board, RenderOptions options).  
   * **Logic:** Implement the translation of ECAD primitives to SkiaSharp commands.  
     * *Coordinates:* Map Micron integers to Skia floating-point coordinates.  
     * *Styling:* Apply colors based on layer type (e.g., Red for Top, Blue for Bottom).  
     * *Optimization:* Use SKPaint caching to avoid allocation in render loops.  
2. **Avalonia Control (BoardCanvas):**  
   * Create a custom control inheriting from Control.  
   * Override the Render method to acquire the SKCanvas via the ISkiaDrawingContextImpl interface or SkiaSharp.Views.Avalonia.  
   * Bridge the Avalonia layout system with the Skia drawing commands.

### **Phase 4: Desktop UI & Interaction**

*Goal: Create a responsive and intuitive user interface.*

1. **API Client:**  
   * Implement BoardServiceClient using HttpClient.  
   * Handle the two-step Upload/Fetch flow seamlessly.  
   * Implement error handling and retry logic (using Polly) for network resilience.  
2. **Main Layout:**  
   * **Sidebar:** A collapsible panel containing the Layer List (ItemsControl with Checkboxes), Netlist summary, and Export buttons.  
   * **Canvas:** The central rendering area taking up the remaining space.  
3. **Interaction Logic:**  
   * Implement ViewMatrix logic for Zoom/Pan.  
   * Capture PointerWheelChanged to modify the scale factor of the matrix.  
   * Capture PointerPressed/Moved to modify the translation components of the matrix.  
   * Apply this matrix to the SKCanvas before invoking BoardRenderer.Render.

### **Phase 5: DevOps & CI/CD**

*Goal: Automate the delivery pipeline to ensure code quality and build integrity.*

1. **GitHub Actions Workflow (.github/workflows/dotnet.yml):**  
   * **Trigger:** Push to main or Pull Request.  
   * **Build:** Execute dotnet restore and dotnet build for all projects using the **.NET 10** SDK.  
   * **Test:** Run dotnet test with code coverage collection. This encompasses both Backend logic tests and Frontend Headless UI tests.  
   * **Docker:** Build the ecad-render-api Docker image based on .NET 10\.  
   * **Artifacts:** Publish the Desktop App (dotnet publish) as a self-contained executable for Windows/Linux/macOS and store it as a build artifact.

### **Phase 6: Nice to Have (Future Enhancements)**

* **gRPC Implementation:**  
  * As board designs grow in complexity, JSON payload sizes increase.  
  * **Plan:** Convert the GET /{id} endpoint to a gRPC service using Protobuf.  
  * **Benefit:** Binary serialization is significantly faster and smaller than JSON, making the "Fetch" step nearly instantaneous for massive boards with high via/trace counts.  
  * **Strategy:** Define .proto files mirroring BoardDto and generate C\# clients/servers automatically for **.NET 10**.