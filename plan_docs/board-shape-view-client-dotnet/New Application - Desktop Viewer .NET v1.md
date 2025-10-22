### **New Application**

**App Title:** ODB++ Desktop Viewer

### **Development Plan**

Description  
A cross-platform native desktop application for Windows, macOS, and Linux. It is designed to provide high-performance, interactive 2D/3D visualization of ODB++ (Open Database++) design data for printed circuit boards (PCBs).  
Overview  
The application is a .NET 9.0 client built using the Avalonia UI framework. It functions as a modern, high-performance front-end for the existing OdbDesignServer backend, replacing a previous REST/JSON web client.  
The primary business driver is to provide a superior user experience with significant performance gains in rendering and, crucially, the ability to work with "extremely large design files that are infeasible for a browser environment".

Communication with the backend is handled exclusively via a high-performance gRPC API over HTTP/2, with data payloads serialized using Protocol Buffers (Protobuf). This approach avoids the performance bottlenecks of JSON serialization/deserialization on large datasets.

**Document Links**

* Architecture Overview: ODB++ Viewer (Version 4.0+)  
* ODB++ Shape Definitions and Feature Architecture (Serves as the technical reference for implementing the geometry rendering engine)
* DOTNET_TECHNOLOGIES.md (.NET technology evaluation and selection document)
* ODB_SHAPE_DEFINITIONS.md (Technical reference for ODB++ shape definitions)

### **Requirements**

Features  
The project is broken into three main delivery milestones:

* **Milestone 1: Core Rendering Engine**  
  * Establish a gRPC connection to the server.  
  * Fetch and process a complete data stream.  
  * Render a static, but accurate, 2.5D representation of a sample board.  
  * Implement foundational UI elements: a functional status bar (showing connection status, coordinates) and non-blocking loading indicators.  
* **Milestone 2: Interactive MVP**  
  * Evolve the application into a fully interactive 2.5D viewer.  
  * **Layer Control:** A robust panel to toggle the visibility of individual layers and layer groups.  
  * **Component Interaction:** Precise component selection with visual highlighting.  
  * **Property Inspection:** A panel to display detailed properties of a selected component.  
  * **Navigation:** Fluid pan and zoom (including zoom-to-cursor).  
  * **Tools:** A basic point-to-point measurement tool.  
  * **UI Feedback:** Status bar dynamically displays the real-world X/Y coordinates of the mouse cursor.  
* **Milestone 3: Full Feature & 3D**  
  * **3D View:** Implement a full 3D perspective view, allowing users to orbit, pan, and inspect the board's physical structure. This leverages component height and layer stackup data from the API.  
  * **Advanced Visualization:** Include controls for cross-section views and dynamic lighting.  
  * **Export:** Add capabilities to export the current view as a high-resolution PNG and data to CSV.  
  * **Deployment:** Package the application into signed, native installers for Windows, macOS, and Linux.

**Test cases**

* **CI Pipeline:** The GitHub Actions workflow must, on every pull request, automatically build, run all unit tests, and perform static analysis on all three target platforms (Windows, macOS, Linux).  
* **Geometry Unit Tests:** A comprehensive unit test suite for the GeometryFactory must be created. This suite must include known problematic shapes (e.g., self-intersecting polygons, polygons with collinear vertices) defined as test .proto messages.  
* **Performance & Stress Tests:** The application must be profiled for memory usage and CPU performance using exceptionally large design files (e.g., \>500k features) to identify and fix bottlenecks.  
* **Manual & Cross-Platform Testing:** Thorough manual testing must be conducted on all target operating systems (Windows, macOS, Linux) to ensure UI consistency, performance, and correct native integrations.

**Logging**

* **Framework:** **Serilog** will be used for structured and configurable logging.  
* **Sinks:** Logs will be written to both a rolling file and the debug console.  
* **Key Log Events:** Detailed logs are required for:  
  * Application start.  
  * gRPC call initiation (including request parameters).  
  * Number of messages received per stream.  
  * Stream completion or errors (with gRPC status codes).  
  * Timing for the geometry generation process.

**Containerization: Docker**

* Not specified for the desktop client application.

**Containerization: Docker Compose**

* Not specified for the desktop client application.

**Swagger/OpenAPI**

* Not applicable. This application is a gRPC client, not a REST API server. The API contract is strictly defined by shared **.proto files** (e.g., odb\_api.proto), which are the single source of truth for the client-server data contract.

**Documentation**

* **Project Docs:** The Development Plan and Architecture Overview serve as the primary project and architecture guides.  
* **API Contract:** The shared .proto files (e.g., features.proto, odb\_api.proto, layerdirectory.proto) are the definitive, auto-generated API contract.  
* **Rendering Logic:** The ODB++ Shape Definitions document serves as the comprehensive technical reference for the geometry rendering engine \[cite: ODB\_SHAPE\_DEFINITIONS.md\].

**Acceptance Criteria**

* **M1:** The application successfully loads and renders a static 2.5D view of a medium-complexity board without user interaction.  
* **M2:** The application is feature-complete for all core 2D inspection tasks and is ready for internal QA and feedback from a pilot group.  
* **M3:** The application incorporates the 3D view, data export, and is successfully packaged into signed, native installers for Windows, macOS, and Linux.  
* **Performance:** All data loading and processing (gRPC calls, geometry generation) must occur on background threads to prevent any UI lockup. The UI must remain responsive and display loading indicators during this process.  
* **Streaming:** The UI must update *progressively* as data is received over the gRPC stream. The user must not have to wait for the entire dataset to download before seeing geometry appear.  
* **Risk Mitigation:** The final product must successfully mitigate key identified risks, especially:  
  * **Performance:** Handled via gRPC server-streaming and background-threaded geometry generation.  
  * **Geometry Failures:** Handled by using the robust NetTopologySuite library for all polygon tessellation.  
  * **API Drift:** Handled by auto-generating C\# client code directly from the shared .proto file using Grpc.Tools.

### **Language**

**C\#**

### **Language Version**

**.NET v9.0**

**Include global.json? sdk: "9.0.0" rollwForward: "latestFeature"**

* Yes (Based on template structure and the explicit .NET 9.0 requirement).

### **Frameworks, Tools, Packages**

* **Core Framework:** .NET 9  
* **UI Framework:** Avalonia UI  
* **MVVM Framework:** CommunityToolkit.Mvvm  
* **3D Graphics:** Helix Toolkit for Avalonia (HelixToolkit.Avalonia)  
* **API/RPC Client:** Grpc.Net.Client, Google.Protobuf, Grpc.Tools (for .proto code generation)  
* **Geometry Processing:** NetTopologySuite (for robustly tessellating complex polygons)  
* **Numerical Computing:** MathNet.Numerics (for coordinate transformations)  
* **Logging:** Serilog  
* **CI/CD:** GitHub Actions  
* **Installer Tooling:** Will require tools to build MSIX (Windows), create notarized .dmg (macOS), and package .deb & .rpm (Linux).

### **Project Structure/Package System**

* **Solution:** A single .NET 9.0 solution.  
* **Package Management:** A shared Directory.Build.props file will be used to manage common NuGet package versions and project properties across the solution.  
* **Core Projects:**  
  * .Desktop: The main Avalonia project (UI layer).  
  * .Core: A .NET standard library for business logic, services, and the gRPC client code. The shared .proto files will be integrated here to auto-generate the C\# client stubs.  
  * .Tests: The unit test project.  
* **Architectural Pattern:** The application will strictly follow the **Model-View-ViewModel (MVVM)** pattern.  
  * **Models:** These are the C\# classes auto-generated by Grpc.Tools from the .proto files (e.g., FeatureRecord).  
  * **Views:** These are the Avalonia .axaml files (e.g., MainView.axaml, LayerPanelView.axaml).  
  * **ViewModels:** These classes contain all presentation logic and state (e.g., MainViewModel, ViewportViewModel). They will use \[ObservableProperty\] and \[RelayCommand\] from CommunityToolkit.Mvvm.  
  * **Services:** Logic is abstracted into services, such as a singleton OdbDesignGrpcService to encapsulate all gRPC communication and a GeometryFactory service to translate Protobuf models into Visual3D objects for Helix Toolkit.

### **GitHub**

Repo  
https://github.com/intel-agency/OdbDesignDesktopViewer  
(Note: Base URL https://github.com/intel-agency/ updated as requested. The repository name OdbDesignDesktopViewer is inferred from the project title ODB++ Desktop Viewer.)  
Branch  
(Not specified in the provided documents.)  
**Deliverables**

* All source code for the .NET 9 Avalonia application, structured in the MVVM pattern as described.  
* A configured GitHub Actions CI/CD workflow that automatically builds, runs unit tests, and packages the application for Windows, macOS, and Linux.  
* Signed, native, production-ready installers:  
  * **Windows:** MSIX package  
  * **macOS:** Notarized .dmg disk image  
  * **Linux:** .deb and .rpm packages