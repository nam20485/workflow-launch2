# **New Application Implementation Specification**

## **App Title**

**AI Resume Content Generator**

## **Description**

### **Overview**

This application is a full-stack, cloud-native web service designed to revolutionize resume creation. Its core function is to aggregate a user's professional data from various sources (manual file uploads of PDF/DOCX resumes or direct scraping of LinkedIn profiles), intelligently store this information as reusable **unstructured data chunks** in Firestore, and use a large language model (**Gemini API**) to generate perfectly tailored, context-aware resumes. The goal is to maximize the user's chances of landing interviews by customizing the output based on a specific target job title and selected style template.

### **Document Links**

| Document Name | Purpose |
| :---- | :---- |
| **Resume Generator DB \- Architecture Document v1** | Defines the technology stack, data model, and high-level system component architecture. |
| **Resume Generator DB \- Development Plan v1** | Outlines the phased development plan, milestones, and detailed user stories with acceptance criteria. |

## **Requirements**

### **Features**

| Feature | Goal | Acceptance Criteria Source |
| :---- | :---- | :---- |
| **F1: Ingest Resume via File Upload** | Allow users to upload PDF/DOCX files and extract raw text for database population. | Development Plan, Feature 1 |
| **F2: Link LinkedIn and Scrape Profile Data** | Securely integrate with LinkedIn (OAuth 2.0) to import detailed professional history and skills. | Development Plan, Feature 2 |
| **F3: Generate AI-Tailored Resume Draft** | Enable users to input a target job context and template style to trigger an AI-based, customized resume generation. | Development Plan, Feature 3 |
| **F4: Resume Preview and Download** | Render the generated draft in a responsive preview and allow the user to export the final result as a high-quality PDF. | Development Plan, Feature 4 |
| **F5: Authentication & User Management** | Secure user sign-in via Firebase Auth and ensure all data is scoped to the authenticated user's ID. | Architecture Document, Auth Handler |

### **Test cases**

Test cases will be derived directly from the **Acceptance Criteria (AC)** defined for each User Story in the Development Plan. Key scenarios include:

1. **File Ingestion:** Uploading a 2-page PDF successfully results in a ResumeChunk document in Firestore with structured content populated.  
2. **LinkedIn Scraper:** A successful OAuth 2.0 connection results in a new ResumeChunk and the access token is securely stored (encrypted).  
3. **Context-Based Filtering:** The generation endpoint, when provided with a context (e.g., "AI Engineer"), only includes data chunks/skills relevant to 'AI' and 'Engineer' in the prompt payload sent to Gemini.  
4. **PDF Generation:** The final PDF output (via weasyprint or similar) maintains the formatting and styling applied in the React preview component.

### **Logging**

* **Level:** Set to **Debug** for local and dev environments; **Info/Warning** for production.  
* **Scope:** Detailed logging is mandatory for:  
  * **External API Calls:** Log request/response status for all calls to LinkedIn, Gemini API, and GCS.  
  * **Scraping/Parsing Errors:** Log file parsing failures (PyPDF2/python-docx errors) and Selenium navigation exceptions.  
  * **Data Transactions:** Log Firestore document creation, updates, and major query executions (via firebase-admin).

### **Containerization: Docker**

A primary Dockerfile will be created for the **Django Backend** application.

* **Base Image:** Python 3.11 slim.  
* **Dependencies:** Must include installation of all system dependencies required for **weasyprint** (for PDF generation) and **Selenium** (for browser automation, if used).  
* **Configuration:** Configure the container to accept Firebase credentials and Google Cloud service account keys securely via environment variables.

### **Containerization: Docker Compose**

Docker Compose will be used for a robust **local development environment (dev/test)**, orchestrating:

1. **Django Service:** The main backend application.  
2. **Frontend Service:** React development server (if needed, but typically run standalone).  
3. **Local Firestore/Emulator:** Recommended for testing data model changes before deployment.

### **Swagger/OpenAPI**

An OpenAPI specification (v3) will be generated and hosted from the Django backend using **Django Rest Framework documentation tools** (e.g., drf-spectacular). Endpoints to be documented include:

* POST /api/v1/ingest/file/  
* GET /api/v1/auth/linkedin/login/  
* GET /api/v1/auth/linkedin/callback/  
* POST /api/v1/generate/resume/ (Request body: context, template\_style)  
* GET /api/v1/generate/download/pdf/

### **Documentation**

Documentation will be maintained using **MkDocs** or **Sphinx** and will focus on:

* **Architectural Overviews:** Data Flow diagrams.  
* **Data Model:** Detailed schema for the ResumeChunk Firestore document.  
* **Prompt Engineering Guide:** Best practices and structure for the prompt sent to the Gemini API.  
* **Deployment Guide:** Step-by-step instructions for deploying the React frontend and the Django backend (e.g., to Google Cloud Run or a VM).

### **Acceptance Criteria**

The application is considered complete upon meeting all the Acceptance Criteria detailed in the "Resume Generator DB \- Development Plan v1," particularly:

1. **Full Data Ingestion:** User data from both file uploads and LinkedIn is successfully normalized and stored as **structured\_content** in a **ResumeChunk** document.  
2. **AI Functionality:** The **Gemini API** call is successfully executed, and the response is a high-quality, relevant resume draft formatted as **robust Markdown/HTML**.  
3. **User Experience:** The application is fully responsive (mobile-optimized) and allows seamless context input and template selection.  
4. **Export Functionality:** Generated content can be reliably converted and downloaded as a standard, high-fidelity PDF file.

## **Language**

| Component | Language | Version/Specification |
| :---- | :---- | :---- |
| **Backend/API** | **Python** | **3.11+** |
| **Frontend/UI** | **TypeScript/JavaScript** | **Latest Stable** |

### **C\#**

**N/A** (Python/Django chosen for its maturity in the AI/NLP ecosystem, as per the Architecture Document)

### **Language Version**

**Python 3.11+**

### **Include global.json?**

**N/A** (This is a .NET-specific configuration, not applicable to Python/React)

## **Frameworks, Tools, Packages**

| Component | Framework/Tool | Key Packages/Libraries |
| :---- | :---- | :---- |
| **Frontend** | **React** | **Tailwind CSS**, axios (for API calls), react-router-dom (for routing), modern Hooks/functional components. |
| **Backend** | **Django** | **Django Rest Framework (DRF)**, gunicorn/uvicorn (for production serving). |
| **Data/Auth** | **Firebase** | **firebase-admin SDK** (Python), **firebase-js SDK** (React), **Google Cloud Storage SDK** (Python). |
| **Data Parsing** | Python Ecosystem | **PyPDF2**, **python-docx**, beautifulsoup4 (for scraping/parsing help), **weasyprint** (or similar for PDF generation). |
| **Scraping** | Python Ecosystem | **requests-oauthlib** (for LinkedIn OAuth), **Selenium** (for deep LinkedIn profile scraping, if necessary). |
| **AI/NLP** | **Gemini API** | **requests** (or a dedicated SDK) for POST calls to the generateContent endpoint, model: **gemini-2.5-flash-preview-09-2025**. |

## **Project Structure/Package System**

The repository will be a **Monorepo** with a clear separation between frontend and backend.

/ai-resume-generator  
├── /backend  
│   ├── /generator\_api        \# Django project root  
│   ├── /auth                 \# Django app for authentication  
│   ├── /ingestion            \# Django app for file/LinkedIn ingestion logic  
│   ├── /generation           \# Django app for AI prompt and generation  
│   ├── requirements.txt  
│   └── Dockerfile  
└── /frontend  
    ├── /src  
    │   ├── /components       \# React components (e.g., TemplateSelector, ResumePreview)  
    │   ├── /pages            \# React page-level components  
    │   └── /services         \# Frontend Firebase/API service layer  
    ├── package.json  
    └── tailwind.config.js

## **GitHub**

| Field | Value |
| :---- | :---- |
| **Repo** | https://github.com/project-placeholder/ai-resume-generator (Placeholder) |
| **Branch** | develop (Default for feature integration) |
| **Deliverables** | Fully functional, containerized backend API, responsive React frontend, passing unit and integration tests, and the final PDF documentation. |

## **Key Development Guidance & Risks**

### **Data Model Criticality**

* **Watch Out:** The core business logic depends entirely on the structure and quality of the **structured\_content map** within the ResumeChunk Firestore document. Any inconsistency in key names (e.g., experience vs job\_history) will break the AI prompt generation.  
* **Mitigation:** Enforce a strict schema for the structured\_content map across all ingestion modules (PDF, DOCX, LinkedIn). Use Python type hints and Pydantic models (if adopted) or dataclasses to ensure data fidelity.

### **AI Prompt Engineering**

* **Risk:** Poorly constructed prompts will lead to low-quality, generic resume outputs, failing the core goal of "customized, context-aware resumes."  
* **Mitigation:** **Iterative Prompt Design** is mandatory. Phase 3 should dedicate significant effort to refining the system instruction and user prompt components (Context, Filtered Data, Template Style) to ensure the Gemini model reliably returns well-structured (e.g., Markdown or JSON) and highly relevant content.

### **Third-Party Integration Instability (LinkedIn/Scraping)**

* **Risk:** Reliance on the LinkedIn API (OAuth) and especially any Selenium-based scraping logic is fragile and prone to breaking changes.  
* **Mitigation:** **Abstract all external integrations** behind dedicated service classes (LinkedInManager, GeminiAPIManager). Implement robust **retry logic** and **clear error logging** for all external calls. If Selenium is used, ensure continuous monitoring for changes in the LinkedIn UI selectors.