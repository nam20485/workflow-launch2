# **Architecture Document: ODB++ Web Viewer**

**Version:** 1.1

**Date:** 2025-09-12

**Author:** Gemini

**Status:** Proposed

## **1\. Introduction**

### **1.1. Project Overview**

This document outlines the software architecture for the ODB++ Web Viewer, a web-based application designed to render interactive 2D and 3D representations of PCB (Printed Circuit Board) designs from ODB++ archives. This tool is intended for engineers, designers, and project managers who need a quick, accessible way to visualize and inspect complex PCB layouts without requiring access to specialized, desktop-based CAD software.

The system will leverage the existing **OdbDesignServer**, a high-performance C++-based backend service that parses ODB++ archives and exposes the structured design data through a RESTful API. The primary focus of this document is the architecture of the new frontend client application that will consume this API and provide a rich, interactive visualization within a web browser.

### **1.2. Architectural Goals**

The architecture is designed to meet the following key objectives, ensuring the final product is robust, scalable, and delivers a high-quality user experience:

* **Phased Delivery:** The project will be developed in two main phases to manage complexity and deliver value incrementally.  
  * **Phase 1 (MVP):** Implement a 2.5D view. This is a top-down orthographic projection where all elements have a uniform, extruded height. This provides immediate utility for layer inspection and component placement verification in a familiar 2D layout.  
  * **Phase 2 (Full 3D):** Upgrade the viewer to a full, true-to-scale 3D representation. This involves consuming Z-axis data (component height, layer thickness) from the backend to create a realistic model that can be rotated and viewed from any angle. The architecture must support this transition seamlessly, without requiring a major refactor.  
* **Performance:** The application must efficiently render complex PCB designs, which can contain tens of thousands of individual geometric shapes and components, without degrading the browser's performance. This involves optimizing WebGL draw calls, managing memory effectively, and ensuring smooth frame rates during user interaction.  
* **Interactivity:** Provide a fluid and intuitive user experience. This includes smooth camera controls for navigation (pan, zoom, rotate), responsive feedback on user actions (e.g., hovering and selecting elements), and the ability to easily inspect the properties of any design element.  
* **Maintainability:** Utilize a modern, component-based architecture that is easy to understand, test, and extend with future features. This includes adopting best practices like static typing, code modularity, and a clear separation of concerns.  
* **Decoupling:** Maintain a clean separation between the backend data provider (OdbDesignServer) and the frontend client. The frontend should be agnostic to the backend's internal logic, communicating exclusively through the defined REST API contract.

## **2\. System Overview**

The system employs a classic two-tier client-server architecture. This model clearly separates the data processing and business logic (server) from the presentation and user interaction logic (client).

* **Backend (OdbDesignServer)**: A C++/Crow-based server that acts as the authoritative source for all PCB design data. Its responsibilities are:  
  * **File Ingestion:** Accepting uploads of ODB++ archives (typically .tgz or .zip files) through a dedicated API endpoint.  
  * **Parsing Engine:** Decompressing and parsing the complex ODB++ file structure to extract layer geometry (pads, traces, polygons), component placement data (X/Y coordinates, rotation), netlists, and other critical metadata.  
  * **API Hosting:** Exposing the parsed data through a well-defined RESTful API. The data is serialized into JSON for consumption by the frontend client.  
* **Frontend (ODB++ Web Viewer)**: A Single Page Application (SPA) that runs entirely in the user's web browser, with no installation required. Its responsibilities are:  
  * **User Interface:** Providing a clean and modern UI for uploading design files, managing view settings, and displaying information.  
  * **API Consumption:** Fetching the design data from the OdbDesignServer API after a file has been processed.  
  * **WebGL Rendering:** Rendering an interactive 2D/3D visualization of the PCB design using the Three.js library. This is the core of the application, responsible for translating the JSON data into visual geometry.  
  * **Interaction Logic:** Handling all user interactions, such as camera manipulation, object selection (raycasting), and displaying detailed information about selected design elements in a dedicated panel.

## **3\. Backend Architecture (Existing)**

The backend is the OdbDesignServer application. For the purpose of this document, its architecture is considered stable and is treated as a "black box" that provides a specific service.

* **Language/Framework**: C++, Crow  
* **Responsibilities**: ODB++ Parsing, Data Caching, REST API Hosting.  
* **API Interface**: The frontend will communicate with the backend exclusively through its REST API, which uses JSON as its data interchange format. A stable, versioned API is crucial for maintaining decoupling. A key future requirement for Phase 2 is the extension of this API to provide Z-axis data (height/thickness) for components and layers. This will likely involve modifications to the backend's parsing logic and data serialization models.

## **4\. Frontend Architecture**

The frontend will be a modern, modular Single Page Application designed for performance and maintainability.

### **4.1. Technology Stack**

| Category | Technology | Justification |
| :---- | :---- | :---- |
| **UI Framework** | **React 18+** with **TypeScript** | React's component-based model is ideal for building a complex, modular UI like a design viewer. Its virtual DOM ensures efficient UI updates. TypeScript adds critical static typing, which reduces runtime errors and makes the codebase easier to refactor and maintain, especially when dealing with the complex, nested data structures that will come from the ODB++ API. |
| **3D Rendering** | **Three.js** | As the de-facto standard for WebGL, Three.js provides the power and flexibility needed for this project. It offers low-level control for performance optimization (e.g., geometry instancing, merging) while abstracting away the complexities of the WebGL API. Its ability to support both OrthographicCamera and PerspectiveCamera makes it the perfect choice for our phased 2.5D to 3D delivery strategy. |
| **State Management** | **Zustand** | For an application of this complexity, a dedicated state management solution is essential. Zustand is chosen over more verbose options like Redux because it provides a simple, hook-based API that minimizes boilerplate and is easy to integrate into React components. It allows for the creation of a centralized store for design data and UI state, making the application's data flow predictable and easy to debug. |
| **API Client** | **Axios** | Axios provides a mature, promise-based HTTP client that simplifies communication with the backend. We will create a dedicated, abstracted "API service" layer that uses Axios internally. This isolates all data-fetching logic from the UI components. Features like interceptors will be valuable for future additions like authentication token handling or global error reporting. |
| **Styling** | **Tailwind CSS** | A utility-first CSS framework that allows for rapid development of a clean, modern, and responsive user interface directly within the JSX. This approach avoids large CSS files, promotes consistency, and makes component styling self-contained and easy to manage. |
| **Build Tool** | **Vite** | Vite offers a superior developer experience compared to older build tools. Its use of native ES modules in development leads to near-instant server start times and hot module replacement (HMR), significantly speeding up the development and debugging cycle. For production, it provides a highly optimized build out of the box. |

### **4.2. Component Structure**

The application will be broken down into a hierarchy of reusable React components, promoting separation of concerns.

* **App.tsx**: The root component. It handles top-level concerns like routing (if ever needed) and context providers, and renders the main application layout.  
* **pages/ViewerPage.tsx**: The main page component that composes the primary UI, housing the ViewerCanvas and the Sidebar.  
* **components/**  
  * **viewer/ViewerCanvas.tsx**: The heart of the application. This component is responsible for all Three.js-related logic. It will initialize the scene, renderer, and camera. It subscribes to the Zustand store and contains the logic for creating, updating, and removing geometric objects (layers, components) from the scene based on the application state. It will also handle user interactions within the canvas, like mouse clicks, using raycasting.  
  * **viewer/Controls.tsx**: This component encapsulates the camera control logic. It will instantiate and configure Three.js's OrbitControls and will listen to a state variable (e.g., viewMode: '2D' | '3D') to dynamically enable or disable rotation, effectively switching between 2D and 3D navigation modes.  
  * **ui/Sidebar.tsx**: A container component that provides the layout for all the UI control panels, ensuring a consistent look and feel.  
  * **ui/FileUpload.tsx**: A self-contained component that handles the file selection UI and the logic for uploading the selected ODB++ archive to the backend server. It will manage its own state for the upload progress.  
  * **ui/LayerPanel.tsx**: Fetches and displays a list of all design layers from the global state. Each layer will have a checkbox and other controls (e.g., color picker) that dispatch actions to update the visibility and appearance of layers in the ViewerCanvas.  
  * **ui/InfoPanel.tsx**: Subscribes to the selectedObject part of the global state. When a user selects a component or net in the viewer, this panel will re-render to display its detailed properties (e.g., RefDes, Part Name, Net Name, coordinates).  
  * **ui/LoadingSpinner.tsx**: A simple, reusable visual indicator that will be displayed globally based on the isLoading state from the store, providing feedback to the user during data fetching and processing.

### **4.3. Data Flow**

The data flow is designed to be unidirectional and predictable, with Zustand serving as the single source of truth for all shared application state. This prevents state inconsistencies and makes the application easier to debug.

1. **Upload & Process**: The user interacts with the FileUpload.tsx component to select and upload an ODB++ archive. The component calls the API service, which sends the file to the OdbDesignServer. The application enters a global isLoading state.  
2. **Data Fetching**: Upon a successful upload response, the API service makes a subsequent call to a /designs/{id} endpoint to fetch the parsed design data as a large JSON object.  
3. **State Hydration**: The fetched JSON data (containing arrays of layers, components, nets, etc.) is processed and saved into the Zustand global store. The isLoading state is set to false.  
4. **Scene Rendering**: The ViewerCanvas.tsx component is subscribed to the store. When it detects that the design data has been populated, it triggers a rebuildScene function. This function clears any existing objects and iterates through the new data arrays, generating and adding the corresponding Three.js Mesh objects to the scene graph.  
5. **User Interaction Loop**:  
   * **Action (UI)**: A user toggles a layer's visibility in the LayerPanel.tsx. The component's onClick handler calls an action in the Zustand store (e.g., toggleLayerVisibility(layerId)).  
   * **State Update**: The store's action updates the state for that specific layer.  
   * **Reaction (Canvas)**: The ViewerCanvas.tsx component, through its subscription, detects the state change. It finds the corresponding Three.js Object3D in its scene and updates its .visible property, causing the layer to appear or disappear. This entire loop happens without direct communication between the UI panels and the canvas component. A similar flow is used for component selection via raycasting, where a click updates a selectedComponentId in the store, which in turn causes the InfoPanel.tsx to re-render.

### **4.4. Rendering Strategy**

The phased 2.5D to 3D approach is a core architectural concept that will be managed primarily within the ViewerCanvas and Controls components, allowing for a seamless upgrade path.

* **Phase 1 (2.5D View)**: The initial deliverable will provide a familiar, CAD-like top-down view.  
  * **Camera**: An OrthographicCamera will be used. This camera type renders the scene without perspective, meaning objects appear the same size regardless of their distance from the camera. This is essential for creating a 2D-like, blueprint feel.  
  * **Geometry**: All board layers and components will be rendered using 3D geometries like ExtrudeGeometry (for traces and polygons) or BoxGeometry (for components). However, the depth/height for these geometries will be a small, uniform, hard-coded value (e.g., 0.1 units). This creates the "extruded" 2.5D effect.  
  * **Controls**: The OrbitControls will be configured to disable rotation (enableRotate \= false). This limits the user to panning (right/middle mouse) and zooming (scroll wheel), reinforcing the 2D experience.  
* **Phase 2 (3D View)**: This phase introduces true depth and perspective.  
  * **Backend Dependency**: This phase is contingent on the OdbDesignServer API being updated to include height and thickness properties in its JSON responses for components and layers, respectively.  
  * **Camera**: A PerspectiveCamera will be used to provide a realistic sense of depth and scale. A UI toggle will be implemented to allow the user to switch between the OrthographicCamera (for a "Top View") and the PerspectiveCamera (for a "3D View").  
  * **Geometry**: The geometry generation logic will be updated. Instead of using a hard-coded value, it will now read the actual height and thickness properties from the API payload for each object, creating a true-to-scale model.  
  * **Controls**: When the user switches to the 3D view, the Controls component will reconfigure the OrbitControls to enable full orbital rotation (enableRotate \= true), allowing the user to inspect the board from any angle.  
  * **Lighting**: The scene's lighting will be enhanced with PointLight or SpotLight sources to create shadows and highlights, which are crucial for giving the 3D model a sense of volume and realism.