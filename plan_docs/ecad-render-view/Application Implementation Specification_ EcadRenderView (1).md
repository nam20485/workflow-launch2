# **New Application: EcadRenderView**

## **App Title**

**EcadRenderView**

## **Development Plan**

### **Description**

EcadRenderView is a robust, high-performance client-server system designed to parse proprietary ECAD JSON files, render complex PCB layouts in 2D with high fidelity, and export these visualizations to standard documentation formats (PDF, SVG, and PNG). The solution prioritizes separation of concerns, data integrity, and cross-platform compatibility by offloading heavy parsing logic to a centralized API ("Smart Server") while utilizing a hardware-accelerated desktop client ("Thin Client") for fluid interaction.

### **Overview**

The application follows a "Thin Client, Smart Server" architecture.

* **Backend (Brain):** ASP.NET Core 10.0 Web API responsible for file I/O, strict schema validation, geometric normalization (unifying units to Microns), and caching processed models.  
* **Frontend (Face):** Avalonia UI Desktop Client responsible for hardware-accelerated rendering via SkiaSharp, user interaction (Zoom/Pan), and layer management.

### **Document Links**

* *Reference:* Development Plan: EcadRenderView  
* *Reference:* Architecture Guide: EcadRenderView

## **Requirements**

### **Core Requirements**

1. **Parsing & Validation**:  
   * Ingest proprietary ECAD JSON format.  
   * Validate logical integrity using 14 specific rules (e.g., checking for missing layers, invalid net references, geometric inconsistencies).  
   * Return precise, descriptive error messages for invalid files.  
2. **Visualization**:  
   * Render Board Boundary (clip path/outline).  
   * Render Components (accurate position/rotation).  
   * Render Traces (color-coded by layer, correct width).  
   * Render Vias and Keepouts.  
   * Normalize coordinates (Microns vs. Millimeters).  
3. **Architecture**:  
   * Client-Server model to decouple processing from presentation.  
   * Stateless rendering logic ("Write Once, Render Anywhere") for consistency between Screen, PDF, and SVG.  
4. **Export**:  
   * Vector: PDF, SVG.  
   * Raster: High-res PNG.

### **Features**

* **File Ingestion**: Upload JSON, parse, validate, and cache on server.  
* **Board Retrieval**: Fetch processed BoardDto via UUID.  
* **Interactive Rendering**: 60 FPS Zoom/Pan navigation; Hardware acceleration.  
* **Layer Management**: Toggle visibility of specific copper layers (Top, Bottom, Inner).  
* **Validation Feedback**: Dialogs presenting specific error codes for rejected designs.  
* **Export Tools**: One-click generation of documentation artifacts.

### **Test Cases**

* **Backend Unit Tests (EcadRender.Api.Tests)**:  
  * Load known "bad" files to assert the "14 Checks" trigger correct error codes.  
  * Verify UnitConverter correctly scales Millimeters to Microns.  
* **Frontend UI Tests (EcadRender.Desktop.Tests)**:  
  * **Headless Testing**: Use Avalonia.Headless to verify ViewModel state transitions (e.g., Loading \-\> Loaded).  
  * Verify Command execution (e.g., ToggleLayerCommand updates VisibleLayers collection).  
* **Integration Tests**:  
  * Verify POST /load returns 400 for invalid data and 200+GUID for valid data.  
  * Verify Cache expiration policies.

### **Logging**

* **Framework**: Serilog  
* **Sinks**: Console (Development), File (Production).  
* **Events**:  
  * Performance metrics (Parsing time, Rendering time).  
  * Validation failures (Log the specific rule broken and file hash).  
  * API Request/Response cycles.

### **Containerization: Docker**

* **Target**: EcadRender.Api (Backend).  
* **Base Image**: mcr.microsoft.com/dotnet/aspnet:10.0  
* **Build Image**: mcr.microsoft.com/dotnet/sdk:10.0  
* **Strategy**: Multi-stage build to minimize final image size.  
* **Optimization**: Layer caching for NuGet restore.

### **Containerization: Docker Compose**

* **Service**: ecad-api  
* **Port Mapping**: 8080:8080  
* **Environment Variables**:  
  * ASPNETCORE\_ENVIRONMENT=Development  
  * CacheSettings\_\_ExpirationMinutes=60

### **Swagger/OpenAPI**

* **Enable**: Yes, strictly required for frontend client generation.  
* **Version**: v1  
* **Path**: /swagger/v1/swagger.json  
* **UI Path**: /swagger

### **Documentation**

* **README**: Setup instructions for local dev (requires .NET 10 SDK).  
* **API Docs**: Swagger UI.  
* **Architecture**: Context diagrams and Data Flow diagrams in repository root.

### **Acceptance Criteria**

* **Upload**: User receives a GUID for valid files; specific error JSON for invalid files.  
* **Visuals**: Rendering matches the source JSON geometry within 1 micron tolerance.  
* **Performance**: Large boards render at \>30 FPS during pan/zoom.  
* **Export**: PDF export text is selectable (vector based), not rasterized.

## **Technical Stack**

### **Language**

* **Language**: C\#  
* **Language Version**: 13.0 (Preview/Latest associated with .NET 10\)

### **Runtime**

* **Framework**: .NET 10.0  
* **Global.json**:  
  {  
    "sdk": {  
      "version": "10.0.100",  
      "rollForward": "latestFeature"  
    }  
  }

### **Frameworks, Tools, Packages**

| Category | Package/Tool | Purpose |
| :---- | :---- | :---- |
| **Backend** | ASP.NET Core 10.0 | Web API Framework |
| **Backend** | System.Text.Json | High-performance JSON parsing |
| **Backend** | Microsoft.Extensions.Caching.Memory | In-memory storage for parsed boards |
| **Frontend** | Avalonia UI | Cross-platform Desktop UI Framework |
| **Frontend** | SkiaSharp | 2D Graphics Engine (Rendering Core) |
| **Frontend** | Polly | HTTP Retry and resilience policies |
| **Shared** | CommunityToolkit.Mvvm | MVVM Source Generators (Observables/Commands) |
| **Testing** | xUnit | Test Runner |
| **Testing** | FluentAssertions | Readable assertions |
| **Testing** | Avalonia.Headless | UI Testing without display |
| **Testing** | Moq | Mocking dependencies |

### **Project Structure**

EcadRenderView.sln  
├── src  
│   ├── EcadRender.Shared        \# DTOs, Enums, Interfaces (Standard 2.1 or .NET 10\)  
│   ├── EcadRender.Api           \# ASP.NET Core Web API  
│   └── EcadRender.Desktop       \# Avalonia UI Client  
└── tests  
    ├── EcadRender.Api.Tests     \# Backend Unit/Integration Tests  
    └── EcadRender.Desktop.Tests \# Frontend Headless Tests

### **GitHub**

* **Repo**: https://github.com/intel-agency/EcadRenderView  
* **Branch Strategy**: Main (Protected) \<- Develop \<- Feature/\*

### **Deliverables**

1. **Source Code**: Full .NET 10 solution committed to GitHub.  
2. **Docker Image**: ecad-render-api:latest for backend deployment.  
3. **Desktop Binaries**: Self-contained executables for Windows (.exe), macOS (.app), and Linux.  
4. **Test Report**: xUnit coverage report \> 80%.