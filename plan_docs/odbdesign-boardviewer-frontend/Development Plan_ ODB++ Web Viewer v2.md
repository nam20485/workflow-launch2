# **Development Plan: ODB++ Web Viewer**

Version: 1.1  
Date: 2025-09-12  
Project Lead: \[Lead Name\]

## **1\. Project Summary**

This document outlines the comprehensive development plan, timeline, and deliverables for the ODB++ Web Viewer project. This project is designed to address a critical need for accessible, platform-independent PCB design visualization. The final product will empower electrical engineers, layout designers, and project stakeholders to review, inspect, and collaborate on designs directly in a web browser, eliminating the friction of installing and licensing specialized desktop software.

The project will be executed using an agile, iterative methodology, structured into a series of two-week sprints. We will begin by delivering a foundational 2.5D viewer that provides immediate value for 2D layout verification, and progressively enhance it into a full-featured, true-to-scale 3D design analysis tool.

**Primary Goal:** To develop a high-performance, web-based frontend application that provides an interactive 2D/3D visualization of ODB++ design data. This application will be a client to the existing OdbDesignServer backend, consuming its REST API to render designs.

## **2\. Team and Roles**

A successful project requires a clear definition of roles and responsibilities. The following outlines the core team structure:

* **Frontend Lead / Architect**: Responsible for the overall technical vision and integrity of the frontend application. This includes making key architectural decisions (e.g., final choice of state management patterns), establishing and enforcing coding standards, performing code reviews, and mentoring other frontend engineers. They will own the initial project setup and the CI/CD pipeline.  
* **Frontend Engineer(s)**: Responsible for the hands-on implementation of components, features, and tests as defined by the sprint goals. They will work closely with the lead to translate architectural concepts into clean, efficient, and testable code.  
* **Backend Engineer**: (As needed, primarily for Phase 3\) Responsible for extending the OdbDesignServer API. This involves modifying the C++ parsing logic to extract Z-axis data (component height, layer thickness) and updating the API endpoints and JSON serialization to expose this new information. Close collaboration with the frontend team will be required to define a clear and efficient data contract.  
* **QA Engineer**: Responsible for ensuring the quality and stability of the application throughout the development lifecycle. This includes creating and executing a comprehensive test plan that covers manual exploratory testing, automated end-to-end testing (e.g., using Cypress or Playwright), and performance benchmarking, especially on large and complex designs.  
* **Project Manager**: Responsible for the overall project execution. This includes facilitating agile ceremonies (sprint planning, stand-ups, retrospectives), tracking progress against the timeline, managing the product backlog, and acting as the primary point of contact for stakeholders to remove any impediments for the development team.

## **3\. Timeline & Major Milestones**

The project is estimated to take **\~12 weeks**, broken into three major phases, each culminating in a significant milestone.

* **Milestone 1 (End of Week 4): Core Application Foundation.** The project's technical foundation is solid. A user can upload an ODB++ file, the frontend can successfully fetch the parsed data from the backend, and a basic, non-interactive 2.5D representation of the board's layers and components is rendered on the screen. This milestone validates the end-to-end data pipeline.  
* **Milestone 2 (End of Week 8): Minimum Viable Product (MVP) Launch.** The application is now a useful tool. This version provides a fully interactive 2.5D viewer where users can pan and zoom, toggle the visibility of individual layers, and click on any component to see its detailed properties in an information panel. This version is suitable for an internal release or a beta for key users.  
* **Milestone 3 (End of Week 12): Full 3D Feature Launch.** The viewer achieves its full potential. A new UI control allows users to switch between the 2.5D top-down view and a full 3D perspective view with orbital camera controls. The 3D rendering utilizes real height and thickness data from the backend API, creating a true-to-scale model. This version is considered feature-complete and ready for a full production deployment.

### **Gantt Chart Overview**

| Sprints (2 weeks each) | Sprint 1-2 | Sprint 3-4 | Sprint 5-6 |
| :---- | :---- | :---- | :---- |
| **Phase** | Foundation & Core Rendering | MVP Features & Interactivity | 3D & Production Readiness |
| **Milestone** | Milestone 1 | Milestone 2 (MVP) | Milestone 3 (Production) |

## **4\. Sprint Breakdown**

### **Sprint 0: Project Initialization (1 Week \- Pre-development)**

* **Goal:** Prepare a robust and efficient development environment and project structure to ensure smooth development velocity from day one.  
* **Tasks:**  
  * \[ \] Set up Git repository with branch policies (e.g., requiring pull requests and successful builds for merges into main).  
  * \[ \] Initialize the React project using Vite with the official TypeScript template.  
  * \[ \] Install and configure core dependencies: three.js (and its React-Three-Fiber wrapper for better integration), zustand, axios, tailwindcss.  
  * \[ \] Configure ESLint, Prettier, and Husky to enforce code style, perform static analysis, and run pre-commit checks automatically. This maintains high code quality across the team.  
  * \[ \] Set up a basic CI/CD pipeline in GitHub Actions. This initial pipeline will run linting, type-checking, and a production build on every pull request to catch errors early.

### **Phase 1: Foundation & Core Rendering (Sprints 1-2)**

#### **Sprint 1: API Integration & Data Management (2 Weeks)**

* **Goal:** Establish robust communication with the backend and create a centralized, predictable state management structure.  
* **Epics:** Backend Communication, State Management.  
* **Stories/Tasks:**  
  * \[ \] Based on the OdbDesignServer's Swagger/OpenAPI specification, define a comprehensive set of TypeScript types/interfaces for all expected API responses (e.g., Design, Layer, Component, Net). Place these in a shared types directory.  
  * \[ \] Create a dedicated, abstracted API service module (/services/api.ts) using a configured Axios instance (with base URL and timeout). This module will encapsulate all backend calls (e.g., uploadDesign, getDesignById).  
  * \[ \] Implement the FileUpload component. This includes the UI for file selection and visual feedback for the upload process (e.g., a progress bar).  
  * \[ \] Set up a Zustand store (/store/designStore.ts) to hold the entire parsed design data, as well as global UI state (e.g., isLoading, errorMessage) and user selections (selectedComponentId).  
  * \[ \] Implement the core data-fetching logic that orchestrates the upload and subsequent fetch, handling loading states and potential API errors gracefully.

#### **Sprint 2: Basic 2.5D Scene Rendering (2 Weeks)**

* **Goal:** Translate the fetched design data into a visual, albeit static, representation on the screen, validating the rendering pipeline.  
* **Epics:** Viewer Rendering (2.5D).  
* **Stories/Tasks:**  
  * \[ \] Implement the ViewerCanvas component with the fundamental Three.js scene setup: WebGLRenderer, Scene, OrthographicCamera, and basic lighting (AmbientLight for general illumination and a DirectionalLight for subtle shading).  
  * \[ \] Create a BoardGeometryFactory utility. This class or module will be responsible for taking the raw JSON data from the store and converting it into Three.js geometries and materials.  
  * \[ \] Implement logic within the factory to render PCB layers. This will involve creating Shape objects from the vector data and using ExtrudeGeometry to give them a default, uniform thickness.  
  * \[ \] Implement logic to render components as simple BoxGeometry meshes, using their X/Y coordinates and rotation, but with a default, uniform height.  
  * \[ \] Add basic OrbitControls configured for 2D interaction (panning and zooming only).  
  * **Deliverable: Milestone 1 Achieved.**

### **Phase 2: MVP Features & Interactivity (Sprints 3-4)**

#### **Sprint 3: UI Panels & Layer Visibility (2 Weeks)**

* **Goal:** Build out the primary user interface panels and provide the core functionality of layer control.  
* **Epics:** User Interface.  
* **Stories/Tasks:**  
  * \[ \] Develop the main Sidebar layout component, which will act as a container for all control panels.  
  * \[ \] Develop the LayerPanel component. This will fetch the list of layers from the Zustand store and render each layer with a checkbox, its name, and a color swatch.  
  * \[ \] Implement the state and logic to toggle the visibility of layer groups in the Three.js scene. Clicking a checkbox in the LayerPanel will update a visibility flag in the store, which the ViewerCanvas will react to.  
  * \[ \] Develop the initial InfoPanel component, which will be populated in the next sprint.  
  * \[ \] Display general design information (e.g., design name, units, creation date) in a persistent header or within the Sidebar.

#### **Sprint 4: Component Selection & Inspection (2 Weeks)**

* **Goal:** Make the viewer interactive by allowing users to select individual components and inspect their detailed properties.  
* **Epics:** User Interaction.  
* **Stories/Tasks:**  
  * \[ \] Implement raycasting logic within the ViewerCanvas to detect mouse clicks on component meshes. User data (like the component ID) will be attached to each mesh to identify it.  
  * \[ \] On a successful click, implement a highlighting effect for the selected component. This could be by changing its material's emissive color or by using a post-processing outline effect.  
  * \[ \] Update the selectedComponentId in the Zustand store with the ID of the selected component.  
  * \[ \] Fully populate the InfoPanel with the detailed data of the selected component (RefDes, Part Name, package, location, etc.) by subscribing to the selectedComponentId.  
  * \[ \] Implement a "clear selection" action, for example, by clicking on the background of the canvas.  
  * **Deliverable: Milestone 2 (MVP) Achieved.**

### **Phase 3: 3D & Production Readiness (Sprints 5-6)**

#### **Sprint 5: Full 3D Data & Rendering (2 Weeks)**

* **Goal:** Evolve the viewer from a 2.5D representation into a true, to-scale 3D model.  
* **Epics:** 3D Upgrade, Backend Collaboration.  
* **Stories/Tasks:**  
  * \[ \] **(Backend Task)** Update OdbDesignServer to parse, store, and serve component heights and layer thicknesses in its API responses. A new API version might be required.  
  * \[ \] Update the frontend API service and all relevant TypeScript types to accommodate the new height and thickness data fields.  
  * \[ \] Modify the BoardGeometryFactory to use these new real height/thickness values from the API when generating the ExtrudeGeometry and BoxGeometry, instead of the hardcoded defaults.  
  * \[ \] Add a UI toggle (e.g., a "2D/3D" button) that updates a viewMode state in the store. This will programmatically switch the ViewerCanvas camera between OrthographicCamera and PerspectiveCamera.  
  * \[ \] Refine the scene lighting for better 3D definition, potentially adding more PointLight or SpotLight sources to create realistic highlights and shadows.

#### **Sprint 6: 3D Controls, Testing & Deployment (2 Weeks)**

* **Goal:** Finalize the 3D user experience, conduct thorough testing, optimize performance, and prepare the application for a production launch.  
* **Epics:** User Interaction, Quality Assurance, Deployment.  
* **Stories/Tasks:**  
  * \[ \] Implement full OrbitControls for the PerspectiveCamera mode, allowing users to intuitively rotate, pan, and zoom around the 3D model.  
  * \[ \] Conduct performance optimization. Investigate using InstancedMesh for components that appear many times (like capacitors) to dramatically reduce draw calls. Merge static layer geometries where possible.  
  * \[ \] Conduct comprehensive cross-browser testing (latest versions of Chrome, Firefox, Safari, Edge) to ensure consistent rendering and functionality.  
  * \[ \] Write unit tests (using Jest and React Testing Library) for critical utility functions (like the geometry factory) and complex components to prevent regressions.  
  * \[ \] Create a production-ready multi-stage Dockerfile for the frontend application, which builds the app and serves the static files via a lightweight web server like Nginx.  
  * \[ \] Deploy the final application to a staging environment for final User Acceptance Testing (UAT).  
  * **Deliverable: Milestone 3 Achieved.**

## **5\. Risks and Mitigation**

| Risk | Probability | Impact | Mitigation Strategy |
| :---- | :---- | :---- | :---- |
| **Performance Issues with Large Designs** | Medium | High | Proactively use performance-oriented Three.js features from the start, such as InstancedMesh for repeated geometries and merging static geometries to reduce draw calls. We will allocate dedicated time for performance profiling and optimization in Sprint 6 and set performance budgets (e.g., target frame rate) for a baseline hardware configuration. |
| **Delay in Backend API Update for 3D** | Medium | Medium | The frontend and backend tasks for the 3D upgrade will be developed in parallel. The frontend team can proceed with developing the 3D rendering logic using mock data or hardcoded height values. This de-risks the timeline; if the backend is delayed, the full 3D features can be pushed to a subsequent release without impacting the MVP. |
| **Inconsistent or Missing ODB++ Data** | Low | Medium | Implement a robust data validation layer within the frontend's API service. When processing API responses, we will check for the presence and correct type of required fields. We will fall back gracefully to default values (e.g., a uniform height of 0.1) if Z-axis data is missing or invalid for certain components, and log these inconsistencies to the console for debugging. |
| **WebGL Browser/Hardware Compatibility** | Low | High | We will define a baseline hardware and browser requirement for WebGL2 support. The application will perform a feature detection check on startup. If the user's browser or hardware does not meet the requirements, we will display a clear, user-friendly message explaining the issue, rather than letting the application fail silently or render incorrectly. |

