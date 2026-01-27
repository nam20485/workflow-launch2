# **Architecture Guide: EcadRenderView**

## **1\. Architectural Overview**

**EcadRenderView** follows a **Thin Client, Smart Server** architecture leveraging the .NET ecosystem.

* **Backend (Brain):** Centralizes complexity. It handles file parsing, geometric normalization, validation rules, caching, and data structuring.  
* **Frontend (Face):** Focused purely on high-performance rendering and user interaction.  
* **Rendering Engine:** **SkiaSharp** is used as the unified rendering engine (Screen/PDF/SVG).

### **System Context Diagram**

\[ User \]  
   |  
   | (1) Selects File  
   v  
\[ Desktop Client (Avalonia UI) \]  
   |  
   \+--- (2) POST /api/board/load (Upload) \---------\> \[ ASP.NET Core Web API \]  
   |                                                        |  
   |                                          (Parses, Validates, Normalizes)  
   |                                                        |  
   |      \<--- (3) Returns { "id": "guid" } \------------+   |  
   |                                                    |   v  
   \+--- (4) GET /api/board/{id} \-------------------\> \[ IMemoryCache \]  
   |                                                    ^  
   |      \<--- (5) Returns BoardDto (JSON) \-------------+  
   |  
   \+--- (6) Renders to Screen (SkiaSharp)

## **2\. Component Detail**

### **A. EcadRender.Shared**

* **Role:** Data Contract.  
* **Key Components:** BoardDto, ComponentDto, ParsingResult.  
* **Standardization:** Coordinates are always **Microns**.

### **B. EcadRender.Api (ASP.NET Core 8.0)**

* **Role:** Parsing, Validation, Caching.  
* **Endpoints:**  
  * POST /api/board/load: Uploads file. Returns 400 if invalid (validation checks), or 200 with ID if valid.  
  * GET /api/board/{id}: Retrieves cached DTO.  
* **Services:**  
  * IBoardParser: Deserialization logic.  
  * IValidationEngine: Runs the 14 integrity checks.  
  * ICacheService: Wraps IMemoryCache for storage.  
* **Infrastructure:** Dockerized (Linux container).

### **C. EcadRender.Desktop (Avalonia UI)**

* **Role:** Visualization.  
* **Key Components:** BoardCanvas (Skia Control), BoardRenderer (Drawing Logic).

## **3\. Testing Strategy**

### **Automated Testing Libraries**

We employ a robust testing stack to ensure the "14 failures" are always caught and the UI logic holds up.

| Layer | Type | Libraries | Purpose |
| :---- | :---- | :---- | :---- |
| **Backend** | Unit | **xUnit**, **FluentAssertions** | Verify parser logic and validation rules against sample files. |
| **Backend** | Integration | **Microsoft.AspNetCore.Mvc.Testing** | Verify HTTP endpoints and Cache interaction. |
| **Frontend** | Unit/UI | **xUnit**, **Avalonia.Headless** | Test ViewModels and UI rendering logic without a physical display. |
| **Shared** | Mocks | **Moq** | Mocking file systems or API responses. |

## **4\. DevOps & Deployment**

### **Docker (Backend)**

The backend is containerized to ensure consistent execution across dev and production.

* **Base Image:** mcr.microsoft.com/dotnet/aspnet:8.0  
* **Build Image:** mcr.microsoft.com/dotnet/sdk:8.0  
* **Exposed Port:** 8080

### **CI/CD (GitHub Actions)**

The workflow triggers on push to main.

1. **Checkout Code.**  
2. **Setup .NET 8\.**  
3. **Restore & Build.**  
4. **Test:** Runs dotnet test (includes Backend Unit/Integration and Frontend Headless tests).  
5. **Docker Build & Push:** (Optional) Pushes the API image to a container registry (GHCR/DockerHub).  
6. **Publish Desktop:** Publishes the Avalonia client as a self-contained executable artifact.

## **5\. Nice to Have: High-Performance Data Transfer (gRPC)**

While the current architecture uses REST (JSON), large PCB boards can result in massive JSON payloads (MBs of text).

### **Proposal: gRPC & Protobuf**

* **Goal:** Reduce payload size and serialization time.  
* **Implementation:**  
  1. Define .proto files mirroring BoardDto.  
  2. Add a GrpcBoardService in the Backend.  
  3. Add Grpc.Net.Client to the Desktop App.  
* **Benefit:** Binary serialization is significantly faster and smaller than JSON, making the "Fetch" step (GET /{id}) nearly instantaneous for complex boards.  
* **Why not now?** JSON is easier to debug and fulfills the initial requirements. gRPC is a clear optimization path.