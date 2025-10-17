# **New Application: board-shape-view-client**

|  |  |
| :---- | :---- |
| **App Title** | board-shape-view-client |
| **Development Plan** | [development\_plan.md](https://www.google.com/search?q=development_plan.md) |
| **Architecture Doc** | [architecture.md](http://docs.google.com/architecture.md) |

## **Description**

### **Overview**

board-shape-view-client is a web-based client application designed to visualize 2D/3D Printed Circuit Board (PCB) designs. It operates in a client-server architecture, where the client is responsible for fetching parsed ODB++ design data from the existing OdbDesignServer REST API. The client then renders this data visually in a browser using a 3D graphics library, allowing users to inspect the PCB layout with interactive pan, zoom, and rotate controls. The primary goal is to provide a lightweight, accessible tool for PCB visualization.

### **Document Links**

| Document | Link |
| :---- | :---- |
| **User Stories** | [development\_plan.md\#5-user-stories](https://www.google.com/search?q=development_plan.md%235-user-stories) |
| **Swagger/OpenAPI** | [OdbDesignServer v0.9 OpenAPI Spec](https://github.com/nam20485/OdbDesign/blob/development/swagger/odbdesign-server-0.9-swagger.yaml) |
| **Containerization** | A Dockerfile will be created in a later phase to containerize the final web application for deployment. |
| **Acceptance Criteria** | See User Stories in the Development Plan. A story is complete when its described functionality is implemented and verifiable. |

## **Technology Stack**

| Category | Technology | Version / Details |
| :---- | :---- | :---- |
| **Language** | TypeScript | \~5.x |
| **Framework** | React | \~18.x |
| **3D Rendering** | Three.js | \~0.160.x |
| **React Renderer** | React Three Fiber | \~8.x |
| **Build Tool** | Vite | \~5.x |
| **Styling** | Tailwind CSS | \~3.x |
| **API Client** | Axios | \~1.x |
| **State Management** | Zustand | \~4.x |

## **Project & Delivery**

|  |  |
| :---- | :---- |
| **Project Structure** | Monorepo containing a single Vite-based SPA package. |
| **GitHub Repo** | https://github.com/nam20485/board-shape-view-client (to be created) |
| **Branch** | development |
| **Deliverables** | A URL to the deployed web application (MVP). Source code available in the GitHub repository. |

