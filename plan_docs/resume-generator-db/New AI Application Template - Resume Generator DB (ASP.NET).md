# **New Application Implementation Specification**

## **App Title**

**AI Resume Content Generator**

## **Description**

### **Overview**

This application is a full-stack, cloud-native web service designed to revolutionize resume creation. Its core function is to aggregate a user's professional data from various sources (manual file uploads of PDF/DOCX resumes or direct scraping of LinkedIn profiles), intelligently store this information as reusable **unstructured data chunks** in Firestore, and use a large language model (**Gemini API**) to generate perfectly tailored, context-aware resumes. The goal is to maximize the user's chances of landing interviews by customizing the output based on a specific target job title and selected style template.

### **Document Links**

| Document Name | Purpose |
| :---- | :---- |
| **Resume Generator DB - Architecture Document v1 (ASP.NET)** | Defines the technology stack, data model, and high-level system component architecture. |
| **Resume Generator DB - Development Plan v1 (ASP.NET)** | Outlines the phased development plan, milestones, and detailed user stories with acceptance criteria. |

## **Requirements**

### **Features**

| Feature | Goal | Acceptance Criteria Source |
| :---- | :---- | :---- |
| **F1: Ingest Resume via File Upload** | Allow users to upload PDF/DOCX files and extract raw text for database population. | Development Plan, Feature 1 |
| **F2: Link LinkedIn and Scrape Profile Data** | Securely integrate with LinkedIn (OAuth 2.0) to import detailed professional history and skills. | Development Plan, Feature 2 |
| **F3: Generate AI-Tailored Resume Draft** | Enable users to input a target job context and template style to trigger an AI-based, customized resume generation. | Development Plan, Feature 3 |
| **F4: Resume Preview and Download** | Render the generated draft in a responsive preview and allow the user to export the final result as a high-quality PDF. | Development Plan, Feature 4 |
| **F5: Authentication & User Management** | Secure user sign-in via ASP.NET Core Identity with Firebase Auth integration and ensure all data is scoped to the authenticated user's ID. | Architecture Document, Auth Handler |

### **Test cases**

Test cases will be derived directly from the **Acceptance Criteria (AC)** defined for each User Story in the Development Plan. Key scenarios include:

1. **File Ingestion:** Uploading a 2-page PDF successfully results in a ResumeChunk document in Firestore with structured content populated.  
2. **LinkedIn Scraper:** A successful OAuth 2.0 connection results in a new ResumeChunk and the access token is securely stored (encrypted).  
3. **Context-Based Filtering:** The generation endpoint, when provided with a context (e.g., "AI Engineer"), only includes data chunks/skills relevant to 'AI' and 'Engineer' in the prompt payload sent to Gemini.  
4. **PDF Generation:** The final PDF output (via QuestPDF or similar) maintains the formatting and styling applied in the Blazor preview component.

### **Logging**

* **Level:** Set to **Debug** for local and dev environments; **Information/Warning** for production.  
* **Scope:** Detailed logging is mandatory for:  
  * **External API Calls:** Log request/response status for all calls to LinkedIn, Gemini API, and GCS using **ILogger<T>**.  
  * **Scraping/Parsing Errors:** Log file parsing failures (PdfPig/DocumentFormat.OpenXml errors) and Selenium navigation exceptions.  
  * **Data Transactions:** Log Firestore document creation, updates, and major query executions (via Google.Cloud.Firestore).

### **Containerization: Docker**

A primary Dockerfile will be created for the **ASP.NET Core Backend** application.

* **Base Image:** mcr.microsoft.com/dotnet/aspnet:8.0.  
* **Dependencies:** Must include installation of all system dependencies required for **QuestPDF** (for PDF generation) and **Selenium** (for browser automation, if used).  
* **Configuration:** Configure the container to accept Firebase credentials and Google Cloud service account keys securely via environment variables and User Secrets.

### **Containerization: Docker Compose**

Docker Compose will be used for a robust **local development environment (dev/test)**, orchestrating:

1. **ASP.NET Core API Service:** The main backend application with controllers.  
2. **Blazor Service:** Blazor Server or WebAssembly application (depending on hosting choice).  
3. **Local Firestore/Emulator:** Recommended for testing data model changes before deployment.
4. **Aspire Dashboard:** For orchestration, monitoring, and service discovery during development.

### **Swagger/OpenAPI**

An OpenAPI specification (v3) will be generated and hosted from the ASP.NET Core backend using **Swashbuckle.AspNetCore**. Endpoints to be documented include:

* POST /api/v1/ingest/file  
* GET /api/v1/auth/linkedin/login  
* GET /api/v1/auth/linkedin/callback  
* POST /api/v1/generate/resume (Request body: context, templateStyle)  
* GET /api/v1/generate/download/pdf

### **Documentation**

Documentation will be maintained using **DocFX** and will focus on:

* **Architectural Overviews:** Data Flow diagrams.  
* **Data Model:** Detailed schema for the ResumeChunk Firestore document.  
* **Prompt Engineering Guide:** Best practices and structure for the prompt sent to the Gemini API.  
* **Deployment Guide:** Step-by-step instructions for deploying the Blazor frontend and the ASP.NET Core backend (e.g., to Azure App Service or Google Cloud Run).

### **Acceptance Criteria**

The application is considered complete upon meeting all the Acceptance Criteria detailed in the "Resume Generator DB - Development Plan v1 (ASP.NET)," particularly:

1. **Full Data Ingestion:** User data from both file uploads and LinkedIn is successfully normalized and stored as **StructuredContent** in a **ResumeChunk** document.  
2. **AI Functionality:** The **Gemini API** call is successfully executed, and the response is a high-quality, relevant resume draft formatted as **robust Markdown/HTML**.  
3. **User Experience:** The application is fully responsive (mobile-optimized) and allows seamless context input and template selection using Blazor components.  
4. **Export Functionality:** Generated content can be reliably converted and downloaded as a standard, high-fidelity PDF file.

## **Language**

| Component | Language | Version/Specification |
| :---- | :---- | :---- |
| **Backend/API** | **C#** | **.NET 8.0+** |
| **Frontend/UI** | **C#/Razor** | **Blazor with .NET 8.0+** |

### **C#**

**Primary Language** - C# is chosen for its strong typing, excellent performance, seamless integration with Azure and Google Cloud services, and mature ecosystem for web development.

### **Language Version**

**C# 12 with .NET 8.0+**

### **Include global.json?**

**YES** - A global.json file will be included to pin the .NET SDK version to 8.0.x for consistency across development environments.

```json
{
  "sdk": {
    "version": "8.0.100",
    "rollForward": "latestFeature"
  }
}
```

## **Frameworks, Tools, Packages**

| Component | Framework/Tool | Key Packages/Libraries |
| :---- | :---- | :---- |
| **Frontend** | **Blazor** | **MudBlazor** (UI components), **Blazored.FluentValidation** (form validation), **Microsoft.AspNetCore.Components.WebAssembly** or **Server** (depending on hosting model). |
| **Backend** | **ASP.NET Core** | **ASP.NET Core Controllers**, **Swashbuckle.AspNetCore** (Swagger/OpenAPI), **Microsoft.AspNetCore.Authentication.JwtBearer**, **Aspire.Hosting**. |
| **Orchestration** | **Aspire.NET** | **Aspire.Hosting**, **Aspire.Dashboard**, service discovery and configuration management for microservices/distributed apps. |
| **Data/Auth** | **Firebase & Google Cloud** | **Google.Cloud.Firestore** (.NET SDK), **FirebaseAdmin** (.NET SDK), **Google.Cloud.Storage.V1** (for GCS). |
| **Data Parsing** | .NET Ecosystem | **PdfPig** (PDF parsing), **DocumentFormat.OpenXml** (DOCX parsing), **QuestPDF** (PDF generation). |
| **Scraping** | .NET Ecosystem | **IdentityModel.OidcClient** (for OAuth), **Selenium.WebDriver** (for LinkedIn profile scraping, if necessary), **HtmlAgilityPack** (for HTML parsing). |
| **AI/NLP** | **Gemini API** | **RestSharp** or **HttpClient** for REST calls to the generateContent endpoint, model: **gemini-2.5-flash-preview-09-2025**. |
| **HTTP Client** | .NET | **System.Net.Http.HttpClient** with **IHttpClientFactory** for resilient HTTP calls. |

## **Project Structure/Package System**

The repository will be organized using **.NET Solution** structure with clear separation of concerns using **Aspire.NET** for orchestration.

```
/ai-resume-generator
├── ai-resume-generator.sln
├── global.json
├── /src
│   ├── /ResumeGenerator.AppHost           # Aspire.NET orchestration host
│   ├── /ResumeGenerator.ServiceDefaults   # Shared Aspire service defaults
│   ├── /ResumeGenerator.Api               # ASP.NET Core Web API (Controllers)
│   │   ├── /Controllers
│   │   ├── /Models
│   │   ├── /Services
│   │   └── Program.cs
│   ├── /ResumeGenerator.Web               # Blazor application
│   │   ├── /Components
│   │   │   ├── /Pages
│   │   │   └── /Shared
│   │   ├── /Services
│   │   └── Program.cs
│   ├── /ResumeGenerator.Shared            # Shared DTOs and contracts
│   └── /ResumeGenerator.Infrastructure    # Data access, external services
│       ├── /Firestore
│       ├── /GeminiApi
│       ├── /LinkedIn
│       └── /Storage
└── /tests
    ├── /ResumeGenerator.Api.Tests
    └── /ResumeGenerator.Infrastructure.Tests
```

## **GitHub**

| Field | Value |
| :---- | :---- |
| **Repo** | https://github.com/project-placeholder/ai-resume-generator-dotnet (Placeholder) |
| **Branch** | develop (Default for feature integration) |
| **Deliverables** | Fully functional, containerized ASP.NET Core API, responsive Blazor frontend, passing unit and integration tests, and comprehensive API documentation. |

## **Key Development Guidance & Risks**

### **Data Model Criticality**

* **Watch Out:** The core business logic depends entirely on the structure and quality of the **StructuredContent** property within the ResumeChunk Firestore document. Any inconsistency in key names (e.g., Experience vs JobHistory) will break the AI prompt generation.  
* **Mitigation:** Enforce a strict schema using **C# records or classes** with strong typing. Use **FluentValidation** to ensure data fidelity across all ingestion modules (PDF, DOCX, LinkedIn). Consider using **System.Text.Json** source generators for efficient serialization.

### **AI Prompt Engineering**

* **Risk:** Poorly constructed prompts will lead to low-quality, generic resume outputs, failing the core goal of "customized, context-aware resumes."  
* **Mitigation:** **Iterative Prompt Design** is mandatory. Phase 3 should dedicate significant effort to refining the system instruction and user prompt components (Context, Filtered Data, Template Style) to ensure the Gemini model reliably returns well-structured (e.g., Markdown or JSON) and highly relevant content.

### **Third-Party Integration Instability (LinkedIn/Scraping)**

* **Risk:** Reliance on the LinkedIn API (OAuth) and especially any Selenium-based scraping logic is fragile and prone to breaking changes.  
* **Mitigation:** **Abstract all external integrations** behind dedicated service interfaces (ILinkedInService, IGeminiApiService). Implement robust **Polly retry policies** and **comprehensive logging using ILogger<T>** for all external calls. If Selenium is used, ensure continuous monitoring for changes in the LinkedIn UI selectors.

### **Aspire.NET Integration**

* **Consideration:** Aspire.NET provides excellent tooling for local development and orchestration but is relatively new in the .NET ecosystem.
* **Mitigation:** Follow official Microsoft Aspire documentation closely. Use Aspire Dashboard for monitoring service health during development. Ensure proper configuration of service-to-service communication and service discovery.
