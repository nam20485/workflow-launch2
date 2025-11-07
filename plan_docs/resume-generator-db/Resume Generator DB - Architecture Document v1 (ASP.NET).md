# **1. Resume Content Database & Generator Architecture Document**

## **1.1 Overview and Goal**

This document defines the technical architecture for a web application designed to scrape resume and profile data, store it in an unstructured, chunked format, and use this data to generate highly customized, context-aware resumes via an advanced AI model.

## **1.2 Technology Stack**

| Layer | Component | Specification / Version | Rationale |
| :---- | :---- | :---- | :---- |
| **Frontend** | Blazor | Blazor Server or WebAssembly with .NET 8.0+, MudBlazor UI components | Modern, component-based, strongly-typed C# throughout the stack, excellent performance, real-time capabilities with SignalR (Server mode). |
| **Backend** | ASP.NET Core | .NET 8.0+, ASP.NET Core Controllers, Minimal APIs optional | Robust, high-performance framework with built-in dependency injection, middleware pipeline, excellent security features, and cross-platform support. |
| **Orchestration** | Aspire.NET | Latest stable version | Provides local development orchestration, service discovery, distributed tracing, and simplified microservices management. Excellent for cloud-native .NET apps. |
| **Database** | Firestore (NoSQL) | Google.Cloud.Firestore .NET SDK | Selected for flexible schema needed for "unstructured data chunks" and scalability. Data will be structured as flexible objects within documents using C# POCOs. |
| **File Storage** | Google Cloud Storage (GCS) | Google.Cloud.Storage.V1 .NET SDK | Highly scalable and reliable object storage for raw input files (PDFs, DOCX). |
| **AI/NLP** | Gemini API | gemini-2.5-flash-preview-09-2025 via HttpClient/RestSharp | Used for context-based resume generation, content tailoring, and style adaptation. |

## **1.3 Data Model: Firestore for Chunking**

The core of the application is the flexible storage of "unstructured data chunks." While using Firestore, we will structure the data using strongly-typed C# classes, focusing on user-specific data security.

**Security Path (Private Data):** /artifacts/__app_id/users/{userId}/resume_chunks

### **1.3.1 ResumeChunk Document Structure**

A single ResumeChunk document will store the parsed, categorized content extracted from one source (e.g., one PDF upload or one LinkedIn profile).

```csharp
public class ResumeChunk
{
    [FirestoreProperty("id")]
    public string Id { get; set; }
    
    [FirestoreProperty("source_url")]
    public string SourceUrl { get; set; }
    
    [FirestoreProperty("raw_text")]
    public string RawText { get; set; }
    
    [FirestoreProperty("extraction_date")]
    public Timestamp ExtractionDate { get; set; }
    
    [FirestoreProperty("structured_content")]
    public StructuredContent StructuredContent { get; set; }
    
    [FirestoreProperty("skills")]
    public List<string> Skills { get; set; }
    
    [FirestoreProperty("tags")]
    public List<string> Tags { get; set; }
}
```

| Field | Type | Description | Example |
| :---- | :---- | :---- | :---- |
| Id | string | Unique Document ID | "chunk-4b3f..." |
| SourceUrl | string | URL of the profile or file path (GCS) | "linkedin.com/in/user", "gs://my-bucket/file.pdf" |
| RawText | string | Complete text extracted from the source | "John Doe..." |
| ExtractionDate | Timestamp | Date/time of data ingestion | Firestore Timestamp |
| **StructuredContent** | **StructuredContent** | **The core, strongly-typed data structure** | See detail below |
| Skills | List\<string\> | Identified skills | ["Python", "Django", "React"] |
| Tags | List\<string\> | Auto-generated/user tags for easy context search | ["developer", "senior", "finance"] |

### **1.3.2 Structured Content Class Detail**

This strongly-typed class is where the core resume data is stored, allowing the generator to pull granular details.

```csharp
public class StructuredContent
{
    [FirestoreProperty("personal_info")]
    public PersonalInfo PersonalInfo { get; set; }
    
    [FirestoreProperty("experience")]
    public List<Experience> Experience { get; set; }
    
    [FirestoreProperty("education")]
    public List<Education> Education { get; set; }
    
    [FirestoreProperty("projects")]
    public List<Project> Projects { get; set; }
}

public class PersonalInfo
{
    [FirestoreProperty("name")]
    public string Name { get; set; }
    
    [FirestoreProperty("email")]
    public string Email { get; set; }
    
    [FirestoreProperty("phone")]
    public string Phone { get; set; }
    
    [FirestoreProperty("location")]
    public string Location { get; set; }
}

public class Experience
{
    [FirestoreProperty("title")]
    public string Title { get; set; }
    
    [FirestoreProperty("company")]
    public string Company { get; set; }
    
    [FirestoreProperty("start_date")]
    public string StartDate { get; set; }
    
    [FirestoreProperty("end_date")]
    public string EndDate { get; set; }
    
    [FirestoreProperty("description")]
    public string Description { get; set; }
}

public class Education
{
    [FirestoreProperty("degree")]
    public string Degree { get; set; }
    
    [FirestoreProperty("institution")]
    public string Institution { get; set; }
    
    [FirestoreProperty("start_date")]
    public string StartDate { get; set; }
    
    [FirestoreProperty("end_date")]
    public string EndDate { get; set; }
}

public class Project
{
    [FirestoreProperty("name")]
    public string Name { get; set; }
    
    [FirestoreProperty("description")]
    public string Description { get; set; }
    
    [FirestoreProperty("technologies")]
    public List<string> Technologies { get; set; }
}
```

## **1.4 System Component Architecture**

### **1.4.1 Frontend (Blazor)**

* **Components:** 
  - `AuthHandler.razor` - Authentication UI using ASP.NET Core Identity
  - `TemplateSelector.razor` - Template selection component
  - `ContextInputForm.razor` - Job context input form with validation
  - `ResumePreview.razor` - Live preview of generated resume
  - `ScraperForm.razor` - File upload and LinkedIn integration UI
* **Interaction:** Communicates with the ASP.NET Core Backend via typed HttpClient using dependency injection.  
* **UI/UX:** Fully responsive using MudBlazor components, optimized for mobile and desktop experiences.
* **State Management:** Uses Blazor's built-in state management with optional Fluxor for complex state scenarios.

### **1.4.2 Backend (ASP.NET Core)**

* **Authentication & User Management:** 
  - ASP.NET Core Identity with Firebase Auth integration
  - JWT Bearer token authentication for API endpoints
  - Role-based authorization policies
* **API Layer (Controllers):** 
  - `IngestController` - Handles file uploads and data extraction
  - `AuthController` - Manages LinkedIn OAuth flow
  - `GenerateController` - Resume generation and download endpoints
  - Swagger/OpenAPI documentation via Swashbuckle
* **Services & Business Logic:**
  - `IFileUploadService` - Manages GCS upload and triggers text extraction
  - `IPdfParserService` (PdfPig) - Extracts text from PDF files
  - `IDocxParserService` (DocumentFormat.OpenXml) - Extracts text from Word files
  - `ILinkedInService` (Selenium/OAuth) - Handles authentication and data extraction
  - `IContextAnalyzer` - Filters ResumeChunk data based on user context
  - `IGeminiApiService` - Constructs prompts and communicates with Gemini API
  - `IPdfGenerationService` (QuestPDF) - Generates final PDF output

### **1.4.3 Aspire.NET Orchestration**

* **AppHost Project:** Defines all services, their relationships, and configuration
* **Service Discovery:** Automatic service-to-service communication setup
* **Dashboard:** Real-time monitoring of all services during development
* **Configuration:** Centralized configuration management across services
* **Observability:** Built-in distributed tracing and logging aggregation

## **1.5 APIs and Integrations**

| Integration | Purpose | Technology/Library | Authentication Method |
| :---- | :---- | :---- | :---- |
| **LinkedIn** | Profile Data Ingestion | Selenium.WebDriver / LinkedIn API via IdentityModel.OidcClient | OAuth 2.0 (User delegation) |
| **Gemini API** | Resume Generation | HttpClient with IHttpClientFactory / RestSharp | API Key (Server-side, secure configuration) |
| **Google Cloud Storage** | Raw File Management | Google.Cloud.Storage.V1 | Service Account / Default Credentials |
| **Firestore** | Data Chunk Storage | Google.Cloud.Firestore | Service Account / Default Credentials |

## **1.6 Security Considerations**

* **Authentication:** ASP.NET Core Identity with JWT tokens
* **Authorization:** Role-based and policy-based authorization
* **Data Protection:** Use Data Protection API for encrypting sensitive data (OAuth tokens)
* **CORS:** Properly configured CORS policies for Blazor-API communication
* **HTTPS:** Enforce HTTPS in production using HSTS middleware
* **Input Validation:** FluentValidation for all API inputs
* **Secrets Management:** User Secrets for development, Azure Key Vault or Google Secret Manager for production

## **1.7 Performance Considerations**

* **Caching:** Use IMemoryCache and IDistributedCache for frequently accessed data
* **Async/Await:** All I/O operations use async patterns
* **Connection Pooling:** HttpClient factory with proper lifetime management
* **Background Jobs:** Use Hangfire or Quartz.NET for long-running operations (file processing)
* **Response Compression:** Enable response compression middleware
* **Blazor Optimization:** Use virtualization for large lists, proper component lifecycle management
