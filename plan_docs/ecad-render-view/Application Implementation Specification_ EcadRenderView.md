# **Application Implementation Specification: EcadRenderView**

## **New Application**

**App Title:** EcadRenderView

**Development Plan:**

The project follows a 6-phase development lifecycle:

1. **Project Scaffolding:** Solution setup, Shared DTOs, and basic CI/CD.  
2. **Parsing Engine & Caching (Backend):** "Brain" of the system. Parsing, validation (14 checks), unit normalization, and caching.  
3. **Testing Infrastructure:** Comprehensive xUnit suite for backend logic and headless frontend logic.  
4. **Rendering Core (Shared/Client):** "Draw Once, Render Everywhere" pipeline using SkiaSharp.  
5. **Desktop UI & Interaction:** Avalonia UI implementation, API client, Zoom/Pan logic, and Layer management.  
6. **DevOps & CI/CD:** Automated build/test pipelines and Docker containerization.

**Description:**

EcadRenderView is a robust, high-performance client-server system designed to ingest proprietary ECAD JSON files, validate their geometric integrity, and render complex PCB layouts in 2D with high fidelity. The system prioritizes a "Thin Client, Smart Server" architecture, ensuring that heavy parsing and validation logic is centralized, while the frontend focuses purely on hardware-accelerated visualization and user interaction. The application also supports exporting these visualizations to standard documentation formats (PDF, SVG, PNG).

**Overview:**

* **Architecture:** Client-Server (Thin Client, Smart Server).  
* **Backend:** ASP.NET Core 8.0 Web API (Linux Docker Container). Handles parsing, the "14 integrity checks," normalization to Microns, and caching.  
* **Frontend:** Avalonia UI (Desktop). Handles user interaction, API communication, and SkiaSharp rendering.  
* **Data Contract:** Shared DTOs ensuring coordinate standardization (Microns).

**Document Links:**

* Architecture Guide: EcadRenderView  
* Development Plan: EcadRenderView

## **Requirements**

**Features:**

* **File Ingestion:** Upload proprietary ECAD JSON via POST /api/board/load.  
* **Validation:** rigorous validation engine checking for 14 specific failure cases (e.g., missing layers, invalid nets).  
* **Caching:** Server-side IMemoryCache to store parsed board models for quick retrieval.  
* **Visualization:** High-performance 2D rendering of Board Boundaries, Components, Traces, Vias, and Keepouts using SkiaSharp.  
* **Interaction:** Real-time Zoom, Pan, and Layer Visibility toggling.  
* **Export:** Generate vector (PDF, SVG) and raster (PNG) exports of the current view.  
* **Unit Handling:** Automatic normalization of Millimeters/Microns to integer-based Microns.

**Test cases:**

* **Backend Unit Tests:** Verify BoardParser and ValidationEngine against the 14 known "bad" files.  
* **Backend Integration Tests:** Verify POST /load and GET /{id} endpoints and Cache behavior.  
* **Frontend Headless Tests:** Verify ViewModel state transitions and Command execution without a physical display (Avalonia.Headless).  
* **Visual Regression:** (Optional) Compare rendered output against "Gold Standard" images.

**Logging:**

* **Backend:** Structured logging (e.g., Serilog or default ILogger) to capture parsing errors, validation failures, and request latencies.  
* **Frontend:** Client-side logging for API errors and rendering exceptions, potentially written to a local log file or debug console.

**Containerization: Docker:**

* **Service:** EcadRender.Api  
* **Base Image:** mcr.microsoft.com/dotnet/aspnet:8.0  
* **Build Image:** mcr.microsoft.com/dotnet/sdk:8.0  
* **Port:** 8080

**Containerization: Docker Compose:**

* Orchestrates the Backend API service for local development and simplified deployment.

**Swagger/OpenAPI:**

* Enabled by default in ASP.NET Core to document POST /api/board/load and GET /api/board/{id}.

**Documentation:**

* API Documentation (Swagger/ReDoc).  
* User Guide for the Desktop Client (Key bindings, Export workflows).  
* Developer Setup Guide (Docker compose up, etc.).

**Acceptance Criteria:**

* **Performance:** Parsing and rendering standard boards must occur within acceptable timeframes (e.g., \< 2s for fetch, 60fps for nav).  
* **Accuracy:** Rendered output must match source geometry exactly (verified via test cases).  
* **Stability:** Invalid files must return 400 Bad Request with descriptive JSON errors, never crashing the server.  
* **Export:** PDF/SVG text must be selectable; lines must remain vector-sharp.

## **Tech Stack**

**Language:**

C\#

**Language Version:**

.NET 8.0 (Aligned with Architecture Guide)

**Include global.json?**

Yes (sdk: "8.0.0", rollForward: "latestFeature")

**Frameworks, Tools, Packages:**

* **Backend:**  
  * Microsoft.AspNetCore.App (Web API)  
  * System.Text.Json (High-performance JSON)  
  * FluentAssertions (Testing)  
  * Moq (Testing)  
  * xUnit (Testing)  
* **Frontend (Desktop):**  
  * Avalonia (UI Framework)  
  * Avalonia.Desktop  
  * Avalonia.Diagnostics  
  * Avalonia.ReactiveUI (MVVM)  
  * SkiaSharp (Rendering Engine)  
  * SkiaSharp.NativeAssets.Linux/macOS/Win  
* **Shared:**  
  * SkiaSharp (For drawing logic shared between View and Export)

**Project Structure/Package System:**

* **Solution:** EcadRenderView.sln  
  * src/  
    * EcadRender.Shared (Class Library \- DTOs, Enums, Interfaces)  
    * EcadRender.Api (ASP.NET Core Web API)  
    * EcadRender.Desktop (Avalonia UI App)  
  * tests/  
    * EcadRender.Api.Tests (xUnit)  
    * EcadRender.Desktop.Tests (xUnit \+ Headless)

**GitHub Repo:**

https://www.google.com/url?sa=E\&source=gmail\&q=https://github.com/nam20485/EcadRenderView (Placeholder)

**Branch:**

main

## **Deliverables**

1. **Source Code:** Complete C\# solution with separated concerns.  
2. **Docker Image:** Production-ready image for EcadRender.Api.  
3. **Desktop Executables:** Self-contained binaries for Windows, macOS, and Linux.  
4. **Test Reports:** Coverage report verifying handling of the 14 failure cases.