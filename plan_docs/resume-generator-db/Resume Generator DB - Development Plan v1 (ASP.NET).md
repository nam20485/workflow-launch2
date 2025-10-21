# **2. Development Plan: AI Resume Content Generator (ASP.NET Core)**

This plan outlines the staged approach for developing the Resume Content Database and Generator application using ASP.NET Core, Blazor, and Aspire.NET, utilizing a detailed User Story template to ensure clarity and measurability for the development team.

## **2.1 Comprehensive User Story Template**

| Field | Description |
| :---- | :---- |
| **Story Title** | A concise, descriptive name for the feature. |
| **As a... I want to... So that I can...** | Standard User Story format defining the role, action, and goal. |
| **Acceptance Criteria (AC)** | A bulleted list of measurable, testable conditions that must be met for the story to be considered complete. |
| **Technical Details/Dependencies** | Specific API endpoints, required NuGet packages, and data flow instructions. |
| **Estimated Effort** | Small (1-2 days), Medium (3-5 days), Large (1+ week). |

## **2.2 Development Phases and Milestones**

### **Phase 1: Foundation & Data Ingestion (MVP)**

**Goal:** Establish the core infrastructure, authentication, and the ability to ingest and store raw data from uploaded files.

| Task | Description | Estimated Effort |
| :---- | :---- | :---- |
| **1.1 Project Setup & Aspire Configuration** | Initialize .NET solution with Aspire.NET, create ASP.NET Core API project, Blazor project, configure Firestore and GCS access. | Medium |
| **1.2 Auth & User Model** | Implement ASP.NET Core Identity with Firebase Auth integration, create user profiles, and secure data paths with authorization policies. | Medium |
| **1.3 PDF/DOCX Parsing Logic** | Implement file upload API endpoint, use PdfPig and DocumentFormat.OpenXml to extract raw text, store in GCS and Firestore. | Medium |
| **1.4 Basic Chunking Logic** | Develop C# service to parse RawText into sections (Experience, Education, Skills) for the StructuredContent object using regex and NLP libraries. | Large |

### **Phase 2: Advanced Scraping & Data Normalization**

**Goal:** Integrate the complex LinkedIn scraping and finalize the data chunking logic for high-quality, normalized inputs.

| Task | Description | Estimated Effort |
| :---- | :---- | :---- |
| **2.1 LinkedIn OAuth 2.0 Flow** | Implement full authorization and token exchange flow using IdentityModel.OidcClient in ASP.NET Core controllers. | Large |
| **2.2 LinkedIn Profile Scraper** | Develop Selenium.WebDriver logic to safely navigate and extract key data points (Jobs, Education, Skills) from a profile, converting to ResumeChunk structure. | Large |
| **2.3 Data Normalization Engine** | Refine chunking logic using regex and potential ML.NET for NLP to standardize dates, titles, and clean formatting from all ingested data. | Large |
| **2.4 Chunk Retrieval API** | Develop secure API endpoints to fetch and filter ResumeChunk documents for a specific user based on keywords and context. | Small |

### **Phase 3: AI Generation & Blazor UI**

**Goal:** Deliver the final user-facing experience, enabling context-aware resume generation and download functionality.

| Task | Description | Estimated Effort |
| :---- | :---- | :---- |
| **3.1 Blazor: Template Selector Component** | Create Blazor component using MudBlazor allowing users to select from 3-5 pre-defined resume templates/styles. | Medium |
| **3.2 Blazor: Context Input Form** | Build form component with FluentValidation where user inputs target job title, industry, and specific context (e.g., "focus on AI skills"). | Small |
| **3.3 Gemini API Prompt Engineering** | Develop C# service to dynamically construct AI prompt: **Context + Selected Data Chunks + Template/Style Instructions**. | Medium |
| **3.4 Resume Generation Endpoint** | Create API endpoint that receives user's context/template, executes prompt engineering, calls Gemini API via HttpClient, and returns generated resume. | Medium |
| **3.5 Blazor Preview & Download** | Implement ResumePreview Blazor component and download functionality using QuestPDF to convert final text to PDF for download. | Medium |

## **2.3 Detailed User Stories**

### **Feature 1: Manual File Upload & Ingestion (PDF/DOCX)**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Ingest Resume via File Upload |
| **As a** User, **I want to** upload a PDF or DOCX file containing my resume, **so that I can** populate my personal data database automatically. |  |
| **Acceptance Criteria (AC)** | 1. User can select and upload a PDF or DOCX file via the Blazor Frontend. 2. File is securely uploaded to a private path in Google Cloud Storage via API. 3. Backend service successfully extracts all raw text from the file using PdfPig or DocumentFormat.OpenXml. 4. The raw text is processed into a ResumeChunk document in Firestore with populated StructuredContent. 5. User receives a real-time confirmation message (via Blazor SignalR if using Server mode) upon successful ingestion. |
| **Technical Details/Dependencies** | **Backend API Endpoint:** POST /api/v1/ingest/file **Required NuGet Packages:** PdfPig, DocumentFormat.OpenXml, Google.Cloud.Storage.V1, Google.Cloud.Firestore. **Data Flow:** Blazor Component -> HttpClient -> ASP.NET Controller -> IFileUploadService -> GCS Upload -> Text Extraction Service -> Firestore Save. **Services:** IFileUploadService, IPdfParserService, IDocxParserService, IFirestoreRepository. |
| **Estimated Effort** | Large |

### **Feature 2: LinkedIn Profile Scraper & Link**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Link LinkedIn and Scrape Profile Data |
| **As a** User, **I want to** securely link my LinkedIn account, **so that I can** import my professional history and skills directly into the database. |  |
| **Acceptance Criteria (AC)** | 1. User is redirected to the LinkedIn OAuth login screen via OAuth redirect and grants permission. 2. ASP.NET Core backend successfully exchanges the authorization code for an access token using IdentityModel.OidcClient. 3. Backend uses the token to access profile data via LinkedIn API or Selenium scraping. 4. Extracted profile data (Jobs, Education, Skills) is successfully mapped to a ResumeChunk document in Firestore using strongly-typed C# classes. 5. The access token is securely stored using ASP.NET Core Data Protection API and associated with the user's account. |
| **Technical Details/Dependencies** | **Backend API Endpoints:** GET /api/v1/auth/linkedin/login and GET /api/v1/auth/linkedin/callback **Required NuGet Packages:** IdentityModel.OidcClient, Selenium.WebDriver (optional), HtmlAgilityPack, Microsoft.AspNetCore.DataProtection. **Data Flow:** Blazor UI -> Controller Redirect -> LinkedIn OAuth -> Callback Controller (Token Exchange) -> ILinkedInService -> Firestore Save. **Services:** ILinkedInService, IOAuthTokenService, IDataProtectionService. |
| **Estimated Effort** | Large |

### **Feature 3: Context-Based Resume Generation**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Generate AI-Tailored Resume Draft |
| **As a** User, **I want to** input a target job title and choose a template style, **so that I can** generate a resume perfectly tailored to the opportunity. |  |
| **Acceptance Criteria (AC)** | 1. User can select a template using MudBlazor Select component (e.g., 'Modern', 'Academic', 'Tech'). 2. User must provide a target **Job Context** via validated form (e.g., "Senior AI Engineer at Google"). 3. Backend successfully filters all user's ResumeChunk data based on context keywords using LINQ queries (e.g., 'AI', 'Senior'). 4. The prompt sent to the Gemini API is comprehensive: **Filtered StructuredContent + Template Style + Job Context**. 5. The generated response is returned as formatted Markdown/HTML ready for Blazor rendering. |
| **Technical Details/Dependencies** | **Backend API Endpoint:** POST /api/v1/generate/resume **Request DTO:** GenerateResumeRequest { Context: string, TemplateStyle: string } **Required NuGet Packages:** System.Net.Http (HttpClient), Newtonsoft.Json or System.Text.Json. **Prompt Engineering:** Use strongly-typed C# classes for prompt structure. Target JSON or Markdown output from Gemini. **Data Flow:** Blazor Form Component -> HttpClient POST -> GenerateController -> IContextAnalyzer (LINQ filtering) -> IGeminiApiService (Prompt Construction) -> Gemini API Call -> Response -> Blazor UI. **Services:** IContextAnalyzer, IGeminiApiService, IPromptBuilder. |
| **Estimated Effort** | Large |

### **Feature 4: Resume Preview and Download**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Preview and Export Generated Resume |
| **As a** User, **I want to** review the generated resume and download it, **so that I can** submit it to the job application. |  |
| **Acceptance Criteria (AC)** | 1. The generated resume text is rendered in the ResumePreview Blazor component using MudBlazor components and the selected template's CSS styles. 2. The preview is fully responsive using MudBlazor's responsive grid system across all breakpoints. 3. A "Download PDF" MudButton is visible and functional. 4. Clicking "Download PDF" triggers a backend API call that uses QuestPDF to convert the styled content into a high-quality PDF file and returns it as a downloadable file stream. |
| **Technical Details/Dependencies** | **Frontend Component:** ResumePreview.razor using MudBlazor components for rendering. **Backend API Endpoint:** GET /api/v1/generate/download/pdf/{resumeId} **Required NuGet Packages:** QuestPDF for PDF generation, MudBlazor for UI components. **Data Flow:** Blazor Preview Component displays rendered resume -> User clicks Download -> HttpClient GET -> GenerateController -> IPdfGenerationService (QuestPDF) -> File Stream Response -> Browser Download. **Services:** IPdfGenerationService, ITemplateRenderingService. |
| **Estimated Effort** | Medium |

## **2.4 Additional Technical Considerations**

### **Testing Strategy**

* **Unit Tests:** xUnit with Moq for service layer testing
* **Integration Tests:** WebApplicationFactory for API endpoint testing
* **Blazor Component Tests:** bUnit for component testing
* **E2E Tests:** Playwright or Selenium for full user flow testing

### **DevOps & Deployment**

* **CI/CD:** GitHub Actions for automated build, test, and deployment
* **Containerization:** Multi-stage Dockerfiles for optimized images
* **Cloud Deployment:** 
  - Azure App Service or Azure Container Apps
  - Google Cloud Run or GKE
  - Aspire deployment support for cloud-native deployment

### **Monitoring & Observability**

* **Application Insights:** For Azure deployments
* **OpenTelemetry:** For distributed tracing
* **Serilog:** Structured logging with various sinks
* **Health Checks:** ASP.NET Core Health Check middleware
* **Aspire Dashboard:** Development-time monitoring and diagnostics
