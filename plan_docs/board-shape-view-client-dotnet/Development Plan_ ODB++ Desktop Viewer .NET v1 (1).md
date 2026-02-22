# **Development Plan: ODB++ Desktop Viewer**

Version: 7.0  
Date: 2025-10-21  
Project Lead: \[Lead Name\]

## **1\. Project Summary**

This document outlines the development plan for the ODB++ Desktop Viewer, a cross-platform application for Windows, macOS, and Linux built with Avalonia and .NET 10.0. This plan details the features, architecture, and development phases required to deliver a native desktop client that interfaces with the existing OdbDesignServer backend via a high-performance gRPC API. The primary business driver for this project is to provide a superior user experience over the existing web client, offering significant performance gains in rendering, native OS integrations (like file associations), and the ability to work with extremely large design files that are infeasible for a browser environment.

**Primary Goal:** To develop a high-performance, cross-platform desktop application providing interactive 2D/3D visualization of ODB++ design data, focusing on delivering features in distinct, value-driven phases. This application will serve as the premier tool for engineers requiring detailed, fluid, and reliable inspection of complex PCB layouts.

## **2\. Referenced Documents**

This plan should be read in conjunction with the **Architecture Overview: ODB++ Viewer (Version 4.0+)**, which contains the detailed gRPC technical design, data flow diagrams, and technology stack justifications.

## **3\. Major Milestones**

* **Milestone 1: Core Rendering Engine.** The application successfully establishes a gRPC connection, fetches and processes a complete data stream from the server, and renders a static, but accurate, 2.5D representation of a sample board. Foundational UI elements, including a functional status bar displaying connection status and coordinates, and non-blocking loading indicators, are implemented. The "Definition of Done" for this milestone is the ability to load and view a medium-complexity board without user interaction.  
* **Milestone 2: Interactive MVP.** The application evolves into a fully interactive 2.5D viewer. This includes a robust layer control panel with individual and group toggle functionality, precise component selection with visual highlighting, a detailed property inspection panel, and fluid pan/zoom navigation. A basic point-to-point measurement tool is also included. This version will be feature-complete for core 2D inspection tasks and ready for internal QA and feedback from a pilot group of engineers.  
* **Milestone 3: Full Feature & 3D.** The application incorporates a full 3D perspective view, allowing users to orbit and inspect the board's physical structure, leveraging component height data from the API. Advanced visualization controls, such as cross-section views and dynamic lighting, are implemented. The application includes data export capabilities (PNG, CSV) and is packaged into signed, native installers for Windows, macOS, and Linux, making it ready for production deployment.

## **4\. Development Phases & Features**

### **Phase 0: Project Initialization (Pre-development)**

* **Goal:** Establish a solid, scalable, and maintainable foundation for the .NET project with the correct gRPC toolchain and CI/CD pipeline.  
* **Tasks:**  
  * **Solution Setup:** Create a new .NET 10.0 solution with a shared Directory.Build.props file to manage common package versions and project properties.  
  * **Project Scaffolding:** Add a main Avalonia project (.Desktop), a core project for business logic (.Core), and a unit test project (.Tests).  
  * **Dependency Management:** Add NuGet packages: CommunityToolkit.Mvvm, HelixToolkit.Avalonia, NetTopologySuite, MathNet.Numerics, Serilog, **Grpc.Net.Client**, **Google.Protobuf**, and **Grpc.Tools**.  
  * **Protobuf Setup:** Integrate the shared .proto file into the .Core project. Configure Grpc.Tools to auto-generate the C\# client stub and message classes, ensuring generated files are correctly namespaced.  
  * **MVVM Architecture:** Create the foundational folder structure (Views, ViewModels, Models, Services, Converters) in the Avalonia project. Establish a base ViewModel class implementing common logic.  
  * **Version Control & CI:** Initialize a Git repository with a .gitignore for .NET. Configure a GitHub Actions workflow that triggers on pull requests to build, run unit tests, and perform static analysis on all target platforms (Windows, macOS, Linux).

### **Phase 1: Foundation & Core Rendering**

* **Goal:** Fetch data from the backend using gRPC and render a static, accurate 2.5D representation of the PCB, ensuring the core data pipeline is robust and performant.  
* **Epic: gRPC Data Access & MVVM Foundation**  
  * **User Story 1:** As a Developer, I want to establish a connection to the backend and stream feature data using gRPC, so that the application has a high-performance data pipeline.  
    * **Tasks:**  
      * Implement a singleton OdbDesignGrpcService that encapsulates the gRPC channel configuration (address, credentials, transport security) and the auto-generated client stub.  
      * Implement a public method in the service that calls the server-streaming RPC (e.g., GetLayerFeaturesStream). This method should accept a CancellationToken and expose the incoming stream of FeatureRecord messages, potentially as an IAsyncEnumerable\<FeatureRecord\>.  
      * In MainViewModel, implement a file selection \[RelayCommand\] that opens a file dialog and then invokes the OdbDesignGrpcService, handling the async stream and passing data to the appropriate processing services.  
      * Implement robust error handling for the gRPC connection (e.g., RpcException) and display user-friendly error messages.  
  * **User Story 2:** As a User, I want to see a loading indicator and progress feedback while data is being streamed and processed so I know the application is working and not frozen.  
    * **Tasks:**  
      * Use an \[ObservableProperty\] boolean (e.g., IsLoading) in the MainViewModel to control the visibility of a primary loading overlay.  
      * Add an \[ObservableProperty\] string (e.g., LoadingStatusText) to provide more context, such as "Connecting to server...", "Streaming layer data...", or "Generating geometry...".  
      * Bind a progress indicator's visibility and status text in MainView.axaml to these properties.  
      * Ensure the gRPC call and all subsequent data processing occur on a background thread using Task.Run to prevent any UI lockup.  
* **Epic: Basic 2.5D Scene Rendering**  
  * **User Story 3:** As an Engineer, I want to see a 2.5D representation of the PCB after loading a file for an immediate overview.  
    * **Tasks:**  
      * Create a GeometryFactory service that translates the **auto-generated Protobuf model objects** into Visual3D objects compatible with Helix Toolkit. This service will contain the core geometric logic.  
      * For Surface features, use **NetTopologySuite** to robustly tessellate complex polygons defined in the Protobuf messages, correctly handling islands and self-intersections.  
      * The ViewportViewModel will consume the stream of FeatureRecord objects from the gRPC service and use the GeometryFactory to progressively build the scene. Use an ObservableCollection\<Visual3D\> for the geometry and add new objects in batches to avoid overwhelming the UI thread.  
      * Implement logic to calculate the total bounding box of all features and automatically adjust the initial camera position and zoom to frame the entire board perfectly upon loading.  
  * **User Story 4:** As a Developer, I want structured logging implemented from the start so I can easily debug the gRPC communication and rendering pipeline.  
    * **Tasks:**  
      * Configure Serilog in the application's entry point to log to a rolling file and the debug console with configurable log levels.  
      * Add detailed logs for key events: application start, gRPC call initiation with request parameters, number of messages received per stream, stream completion/errors with status codes, and timing for the geometry generation process.

### **Phase 2: MVP Features & Interactivity**

* **Goal:** Empower users with a fluid, interactive toolset to inspect and analyze the 2.5D design effectively.  
* **Epic: UI & Layer Control**  
  * **User Story 5:** As an Engineer, I want to toggle the visibility of individual design layers to isolate specific areas for inspection.  
    * **Tasks:**  
      * Create a LayerViewModel class with Name, Color, and IsVisible observable properties.  
      * Implement a LayerPanelView with a virtualized ItemsControl (e.g., ListBox) containing a CheckBox list bound to a collection of LayerViewModels. Virtualization is key for designs with many layers.  
      * Link LayerViewModel.IsVisible changes to the .IsVisible property of the corresponding group of Visual3D objects.  
      * Add "Select All" and "Deselect All" buttons for convenience.  
* **Epic: User Interaction & Inspection**  
  * **User Story 6:** As an Engineer, I want to pan and zoom the 2.5D view fluidly to navigate the board.  
    * **Tasks:**  
      * Ensure HelixViewport3D is configured for intuitive mouse controls: pan (middle-mouse drag or SHIFT \+ left-drag) and zoom (mouse wheel).  
      * Implement zoom-to-cursor behavior, where the zoom is centered on the mouse pointer's location.  
  * **User Story 7:** As an Engineer, I want to click on a component in the view to see its detailed properties.  
    * **Tasks:**  
      * Use the built-in hit-testing of HelixViewport3D to identify a clicked Visual3D element.  
      * Create a data structure (e.g., a Dictionary\<Visual3D, FeatureRecord\>) to associate each Visual3D with its source Protobuf FeatureRecord model.  
      * Create a SelectedComponentViewModel property on the MainViewModel to hold the currently selected model.  
      * Implement an InfoPanelView that binds to the properties of the selected component's model, displaying them in a user-friendly key-value format.  
      * Implement a highlighting effect for the selected component, such as changing its color or adding an emissive material, and ensure the previous selection is un-highlighted.  
  * **User Story 8:** As an Engineer, I want to see the real-world coordinates of my mouse cursor in a status bar for quick reference.  
    * **Tasks:**  
      * Add a StatusBar to MainView.axaml with distinct sections for different information.  
      * Capture mouse move events over the HelixViewport3D control.  
      * Perform a reverse transformation (un-project) from 2D screen coordinates to the 3D world coordinates on the board's plane.  
      * Display the X/Y coordinates in the status bar, formatted to a reasonable precision (e.g., 4 decimal places).

### **Phase 3: Full Feature Set & 3D Readiness**

* **Goal:** Introduce a true 3D perspective view, provide advanced analysis and export tools, and prepare the application for production deployment.  
* **Epic: 3D Upgrade**  
  * **User Story 9:** As an Engineer, I want to switch to a true 3D perspective view to understand the physical structure and component stacking.  
    * **Tasks:**  
      * Coordinate with the backend team to **add component height, board thickness, and layer stackup data to the .proto definitions**.  
      * **Re-generate the gRPC C\# client** to include the new Z-axis data fields.  
      * Modify the GeometryFactory to use the actual height and thickness values from the Protobuf models when creating Visual3D objects. This includes creating extruded solids for components and a base plate for the PCB substrate.  
  * **User Story 10:** As an Engineer, I want to orbit, pan, and zoom the 3D camera to inspect the board from any angle.  
    * **Tasks:**  
      * Add a UI toggle (e.g., a "2D/3D" button) to switch the ViewportViewModel's active camera between OrthographicCamera and PerspectiveCamera.  
      * Enable mouse rotation controls (e.g., left-mouse drag) on the HelixViewport3D control only when in 3D mode.  
      * Implement a "Reset View" command to return the camera to a default isometric or top-down perspective.  
* **Epic: Advanced Tools & Export**  
  * **User Story 11:** As an Engineer, I want a basic measurement tool to find the distance between two points on the board.  
    * **Tasks:**  
      * Implement a "Measure" mode toggle button.  
      * In measure mode, capture two user clicks on the viewport, snapping to feature vertices if possible for accuracy.  
      * Draw a temporary line on the viewport between the two points.  
      * Calculate and display the Euclidean distance, dX, and dY between the two points in board units (inches and mm).  
  * **User Story 12:** As an Engineer, I want to export the current view as a high-resolution PNG image for inclusion in reports and documentation.  
    * **Tasks:**  
      * Add an "Export to PNG" command in the main menu.  
      * Use the Viewport3DHelper.SaveBitmap method from Helix Toolkit to save the contents of the HelixViewport3D control to a PNG file.  
      * Provide options in the save dialog for resolution scaling (e.g., 2x, 4x) and a transparent background.  
* **Epic: Quality Assurance & Deployment**  
  * **User Story 13:** As a Project Manager, I want the application to be easily and safely installable on Windows, macOS, and Linux.  
    * **Tasks:**  
      * Profile application memory usage and CPU performance with exceptionally large design files (\>500k features) to identify and fix bottlenecks.  
      * Conduct thorough manual testing on all target operating systems, focusing on UI consistency, performance, and native integrations.  
      * Enhance the GitHub Actions workflow to automatically build, **code-sign**, and package the application on release tags.  
      * Create native installers: **MSIX** for Windows (for Microsoft Store), a **notarized .dmg** disk image for macOS, and both **.deb & .rpm** packages for Linux.

## **5\. Risks and Mitigation**

| Risk Description | Likelihood | Impact | Mitigation Strategy |
| :---- | :---- | :---- | :---- |
| **Performance with Large Datasets** | Medium | High | \- Actively use gRPC server-streaming to process data chunks as they arrive, providing a responsive UI even before all data has been received. \- Offload all geometry generation and processing to a dedicated background thread. \- Aggressively investigate and implement geometry instancing and Level of Detail (LOD) techniques in Helix Toolkit for repeated symbols (e.g., vias, pads) to reduce GPU load. |
| **Complex Geometry Rendering Failures** | Medium | High | \- Rely on the robust and battle-tested NetTopologySuite library for all polygon tessellation and boolean operations. \- Create a comprehensive unit test suite for the GeometryFactory that includes known problematic shapes (self-intersecting polygons, polygons with collinear vertices) defined as .proto messages. \- Implement extensive logging to gracefully handle and report invalid data received from the gRPC stream. Invalid geometries should be skipped without crashing the application, and the source data logged for backend debugging. |
| **Cross-Platform UI Inconsistencies** | Medium | Medium | \- Set up the CI/CD pipeline in Phase 0 to build and run automated headless UI tests on Windows, macOS, and Linux continuously. \- Conduct regular manual testing on physical or virtual machines for all target platforms throughout the development cycle, specifically after any major UI changes. \- Maintain a strict policy of avoiding platform-specific code in ViewModels; any OS-level interaction must be abstracted behind an interface. |
| **API Contract Drift** | Low | High | \- Establish the shared .proto file in a version-controlled Git submodule or a dedicated internal repository. This ensures it remains the single source of truth for both client and server. \- The client-side C\# code is auto-generated by Grpc.Tools, which programmatically eliminates manual mapping errors and guarantees that the client and server models are always synchronized. Any breaking change to the .proto file will result in a compile-time error on the client, preventing runtime failures. |

