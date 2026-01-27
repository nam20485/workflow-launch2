# **board-shape-view-client: Architecture**

This document details the internal architecture of the board-shape-view-client Single Page Application (SPA).

## **1\. High-Level Architecture**

The application follows a standard client-server model. This architecture document is concerned exclusively with the **client**. The client is a modern SPA built with React, designed to be run entirely within a web browser. Its primary responsibility is to fetch data from the OdbDesignServer, transform that data into visual objects, and render them in an interactive 3D scene.

## **2\. Client Application Architecture**

The client is designed with a modular, component-based structure to ensure a clean separation of concerns. This makes the application easier to develop, test, and maintain.

### **Key Components**

* **api/ (API Client Service)**  
  * **Responsibility**: Manages all communication with the OdbDesignServer REST API.  
  * **Implementation**: A thin wrapper around axios. It will handle request/response logic, error handling, and encapsulate all API endpoints. It will be agnostic of any UI framework.  
* **models/ (Data Models)**  
  * **Responsibility**: Defines the shape of the data used throughout the application.  
  * **Implementation**: A collection of TypeScript interface or type definitions that strictly type the JSON data received from the API. This ensures data consistency and provides autocompletion during development.  
* **store/ (State Management)**  
  * **Responsibility**: Manages global application state that needs to be shared across different components.  
  * **Implementation**: A zustand store. For the MVP, this might be minimal, but it will later hold state such as the list of layers, their visibility status, and information about any currently selected feature.  
* **rendering/ (Rendering Engine)**  
  * **Responsibility**: The core of the application, responsible for all 3D rendering logic.  
  * **Implementation**: A set of React components and hooks that use react-three-fiber and three.js.  
    * **ShapeFactory.tsx**: A component that takes the raw ODB++ data as props and translates it into a hierarchy of three.js meshes (e.g., \<Pad\>, \<Line\>). This is where the primary data-to-visual transformation occurs.  
    * **Scene.tsx**: The main component that sets up the Three.js scene, including lights, environment, and camera controls (OrbitControls). It will contain the ShapeFactory.  
* **components/ (UI Components)**  
  * **Responsibility**: All user-facing, non-3D interface elements.  
  * **Implementation**: Standard React components for the user interface.  
    * **BoardViewer.tsx**: The top-level component that houses the react-three-fiber \<Canvas\> and the Scene.  
    * **Toolbar.tsx**: (Phase 2\) A component containing UI buttons for actions like "Zoom to Fit".  
    * **LayerPanel.tsx**: (Phase 2\) A component to display layer names and visibility toggles.

### **Directory Structure**

src/  
├── api/  
│   └── odbDesignClient.ts   \# Axios wrapper for the REST API  
├── models/  
│   └── odb.ts               \# TypeScript interfaces for ODB++ data  
├── rendering/  
│   ├── Scene.tsx            \# Main 3D scene setup  
│   └── shapes/  
│       ├── ShapeFactory.tsx \# Converts JSON data to 3D meshes  
│       └── Pad.tsx          \# Example component for a single shape  
├── components/  
│   ├── BoardViewer.tsx      \# Main component hosting the 3D canvas  
│   └── ui/                  \# UI components (Toolbar, LayerPanel, etc.)  
├── store/  
│   └── useBoardStore.ts     \# Zustand store for global state  
└── App.tsx                  \# Main application component

## **3\. Data Flow**

The data flow is unidirectional, which makes the application's behavior predictable and easier to debug.

1. **Load**: The main App.tsx component mounts.  
2. **Fetch**: A useEffect hook triggers the odbDesignClient to fetch board data from the server.  
3. **Store**: The fetched data is stored in a component's state (or passed down as props).  
4. **Render**: The BoardViewer receives the data and passes it to the ShapeFactory.  
5. **Transform**: The ShapeFactory iterates through the data and renders the appropriate Three.js mesh components.  
6. **Interact**: The user interacts with the scene using OrbitControls (pan/zoom/rotate). These controls directly manipulate the Three.js camera without needing to go through the React state management system, ensuring smooth performance.  
7. **State Change (Phase 2\)**: When a user interacts with a UI element (e.g., toggles a layer in LayerPanel), it calls an action in the zustand store. The store's state is updated, which causes any components subscribed to that state (like ShapeFactory) to re-render with the new visibility information.

This architecture provides a solid, scalable foundation for the MVP and allows for the straightforward addition of more complex features in subsequent phases.