# **2\. Development Plan: AI Resume Content Generator**

This plan outlines the staged approach for developing the Resume Content Database and Generator application, utilizing a detailed User Story template to ensure clarity and measurability for the development team.

## **2.1 Comprehensive User Story Template**

| Field | Description |
| :---- | :---- |
| **Story Title** | A concise, descriptive name for the feature. |
| **As a... I want to... So that I can...** | Standard User Story format defining the role, action, and goal. |
| **Acceptance Criteria (AC)** | A bulleted list of measurable, testable conditions that must be met for the story to be considered complete. |
| **Technical Details/Dependencies** | Specific backend endpoints, required libraries, and data flow instructions. |
| **Estimated Effort** | Small (1-2 days), Medium (3-5 days), Large (1+ week). |

## **2.2 Development Phases and Milestones**

### **Phase 1: Foundation & Data Ingestion (MVP)**

**Goal:** Establish the core infrastructure, authentication, and the ability to ingest and store raw data from uploaded files.

| Task | Description | Estimated Effort |
| :---- | :---- | :---- |
| **1.1 Infrastructure Setup** | Configure Django project, React frontend, Firestore connection, and GCS bucket access. | Medium |
| **1.2 Auth & User Model** | Implement Firebase Authentication and create user profiles/secure data paths. | Medium |
| **1.3 PDF/DOCX Parsing Logic** | Implement file upload endpoint and use PyPDF2/python-docx to extract raw text and store it in GCS/Firestore. | Medium |
| **1.4 Basic Chunking Logic** | Develop initial Python logic to coarsely break down raw\_text into sections (Experience, Education, Skills) for the structured\_content map. | Large |

### **Phase 2: Advanced Scraping & Data Normalization**

**Goal:** Integrate the complex LinkedIn scraping and finalize the data chunking logic for high-quality, normalized inputs.

| Task | Description | Estimated Effort |
| :---- | :---- | :---- |
| **2.1 LinkedIn OAuth 2.0 Flow** | Implement the full authorization and token exchange flow within the Django backend. | Large |
| **2.2 LinkedIn Profile Scraper** | Develop the Selenium/API logic to safely navigate and extract all key data points (Jobs, Education, Skills) from a profile, converting them into the ResumeChunk structure. | Large |
| **2.3 Data Normalization Engine** | Refine chunking logic to use NLP/regex to standardize dates, titles, and remove extraneous formatting from *all* ingested data. | Large |
| **2.4 Chunk Retrieval API** | Develop a secure API endpoint to fetch and filter ResumeChunk documents for a specific user based on simple keywords. | Small |

### **Phase 3: AI Generation & Frontend UI**

**Goal:** Deliver the final user-facing experience, enabling context-aware resume generation and download functionality.

| Task | Description | Estimated Effort |
| :---- | :---- | :---- |
| **3.1 Frontend: Template Selector UI** | Create the React component allowing the user to select from 3-5 pre-defined resume templates/styles. | Medium |
| **3.2 Frontend: Context Input Form** | Build the UI form where the user inputs the target job title, industry, and any specific context (e.g., "focus on AI skills"). | Small |
| **3.3 Gemini API Prompt Engineering** | Develop the Python logic to dynamically construct the AI prompt: **Context \+ Selected Data Chunks \+ Template/Style Instructions**. | Medium |
| **3.4 Resume Generation Endpoint** | Create the Django API endpoint that receives the user's context/template, executes the prompt engineering, calls the Gemini API, and returns the generated resume text. | Medium |
| **3.5 Final Preview & Download** | Implement the React ResumePreview component and the download functionality (converting the final text to a PDF/DOCX for download). | Medium |

## **2.3 Detailed User Stories**

### **Feature 1: Manual File Upload & Ingestion (PDF/DOCX)**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Ingest Resume via File Upload |
| **As a** User, **I want to** upload a PDF or DOCX file containing my resume, **so that I can** populate my personal data database automatically. |  |
| **Acceptance Criteria (AC)** | 1\. User can select and upload a PDF or DOCX file via the Frontend. 2\. File is securely uploaded to a private path in Google Cloud Storage. 3\. Backend service successfully extracts all raw text from the file. 4\. The raw text is processed into a ResumeChunk document in Firestore with coarse structured\_content. 5\. User receives a confirmation message upon successful ingestion. |
| **Technical Details/Dependencies** | **Backend/API Endpoint:** POST /api/v1/ingest/file/ **Required Libraries:** PyPDF2, python-docx, google-cloud-storage SDK. **Data Flow:** React \-\> Django Endpoint \-\> GCS \-\> Text Extraction \-\> Firestore Document Save. |
| **Estimated Effort** | Large |

### **Feature 2: LinkedIn Profile Scraper & Link**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Link LinkedIn and Scrape Profile Data |
| **As a** User, **I want to** securely link my LinkedIn account, **so that I can** import my professional history and skills directly into the database. |  |
| **Acceptance Criteria (AC)** | 1\. User is redirected to the LinkedIn OAuth login screen and grants permission. 2\. Django backend successfully exchanges the code for an access token. 3\. Backend uses the token to access the profile data via the LinkedIn API. 4\. Extracted profile data (Jobs, Education, Skills) is successfully mapped to a ResumeChunk document in Firestore. 5\. The access token is securely stored (encrypted) and associated with the user's account. |
| **Technical Details/Dependencies** | **Backend/API Endpoint:** GET /api/v1/auth/linkedin/login/ and GET /api/v1/auth/linkedin/callback/ **Required Libraries:** requests-oauthlib, potential use of Selenium if API is restrictive or for deeper scraping. **Data Flow:** React \-\> Django Auth Redirect \-\> LinkedIn \-\> Django Callback (Token Exchange) \-\> LinkedIn API Call \-\> Firestore Save. |
| **Estimated Effort** | Large |

### **Feature 3: Context-Based Resume Generation**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Generate AI-Tailored Resume Draft |
| **As a** User, **I want to** input a target job title and choose a template style, **so that I can** generate a resume perfectly tailored to the opportunity. |  |
| **Acceptance Criteria (AC)** | 1\. User can select a template (e.g., 'Modern', 'Academic', 'Tech'). 2\. User must provide a target **Job Context** (e.g., "Senior AI Engineer at Google"). 3\. Backend successfully filters all user's ResumeChunk data based on context keywords (e.g., 'AI', 'Senior'). 4\. The prompt sent to the Gemini API is comprehensive: **Filtered Data \+ Template Style \+ Job Context**. 5\. The generated response is returned as formatted text ready for display. |
| **Technical Details/Dependencies** | **Backend/API Endpoint:** POST /api/v1/generate/resume/ **Required Libraries:** requests (for Gemini API call). **Prompt Engineering:** Focus on JSON output or robust Markdown output from the AI for easy rendering. **Data Flow:** React (Context/Template) \-\> Django Endpoint \-\> Firestore Query (Filtering) \-\> Prompt Construction \-\> Gemini API \-\> Django Response \-\> React UI. |
| **Estimated Effort** | Large |

### **Feature 4: Resume Preview and Download**

| Field | Detail |
| :---- | :---- |
| **Story Title** | Preview and Export Generated Resume |
| **As a** User, **I want to** review the generated resume and download it, **so that I can** submit it to the job application. |  |
| **Acceptance Criteria (AC)** | 1\. The generated resume text is rendered in the ResumePreview component using the selected template's CSS styles. 2\. The preview is fully responsive and clean across all breakpoints. 3\. A "Download PDF" button is visible and functional. 4\. Clicking "Download PDF" triggers a backend process that converts the final, styled content into a downloadable PDF file. |
| **Technical Details/Dependencies** | **Frontend/UI:** Use Tailwind CSS for highly stylized and responsive template rendering. **Backend/API Endpoint:** GET /api/v1/generate/download/pdf/ **Required Libraries:** weasyprint or a similar Python library for HTML/Markdown to PDF conversion (requires the generated output to be rendered as HTML server-side). |
| **Estimated Effort** | Medium |

