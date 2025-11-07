# **1\. Resume Content Database & Generator Architecture Document**

## **1.1 Overview and Goal**

This document defines the technical architecture for a web application designed to scrape resume and profile data, store it in an unstructured, chunked format, and use this data to generate highly customized, context-aware resumes via an advanced AI model.

## **1.2 Technology Stack**

| Layer | Component | Specification / Version | Rationale |
| :---- | :---- | :---- | :---- |
| **Frontend** | React | Functional Components (Hooks), Tailwind CSS | Modern, component-based, high performance, excellent theming. |
| **Backend** | Python & Django | Python 3.11+, Django 5.x (DRF) | Robust framework for rapid development, built-in ORM, security, and session management. Python is ideal for AI/NLP/Scraping libraries. |
| **Database** | Firestore (NoSQL) | Standard Firestore (via Firebase SDK) | Selected for flexible schema needed for "unstructured data chunks" and scalability. Data will be structured as flexible JSON maps within documents. |
| **File Storage** | Google Cloud Storage (GCS) | Standard Bucket Storage | Highly scalable and reliable object storage for raw input files (PDFs, DOCX). |
| **AI/NLP** | Gemini API | gemini-2.5-flash-preview-09-2025 | Used for context-based resume generation, content tailoring, and style adaptation. |

## **1.3 Data Model: Firestore for Chunking**

The core of the application is the flexible storage of "unstructured data chunks." While using Firestore, we will structure the data to mimic a schemaless document store, focusing on user-specific data security.

**Security Path (Private Data):** /artifacts/\_\_app\_id/users/{userId}/resume\_chunks

### **1.3.1 ResumeChunk Document Structure**

A single ResumeChunk document will store the parsed, categorized content extracted from one source (e.g., one PDF upload or one LinkedIn profile).

| Field | Type | Description | Example |
| :---- | :---- | :---- | :---- |
| id | String | Unique Document ID | chunk-4b3f... |
| source\_url | String | URL of the profile or file path (GCS) | linkedin.com/in/user, gs://my-bucket/file.pdf |
| raw\_text | String | Complete text extracted from the source. | "John Doe |
| extraction\_date | Timestamp | Date/time of data ingestion. |  |
| **structured\_content** | **Map (JSON)** | **The core, flexible, categorized data structure.** | See detail below. |
| skills | Array of Strings | Identified skills (e.g., \['Python', 'Django', 'React'\]) |  |
| tags | Array of Strings | Auto-generated/user tags for easy context search. | \['developer', 'senior', 'finance'\] |

### **1.3.2 Structured Content Map Detail (structured\_content)**

This flexible map is where the core resume data is stored, allowing the generator to pull granular details.

| Key (within Map) | Type | Description | Example Content |
| :---- | :---- | :---- | :---- |
| personal\_info | Map | Name, Email, Phone, Location. | {"name": "Jane", "email": "j@ex.com"} |
| experience | Array of Maps | Detailed job history (title, company, dates, description). | \[{"title": "Sr. Dev", "company": "Acme Inc.", "description": "Managed team..."}\] |
| education | Array of Maps | Degrees, Institutions, Dates, Grades. | \[{"degree": "B.S. CS", "institution": "State Univ."}\] |
| projects | Array of Maps | Side projects, with description and technologies used. |  |

## **1.4 System Component Architecture**

### **1.4.1 Frontend (React)**

* **Components:** AuthHandler, TemplateSelector, ContextInputForm, ResumePreview, ScraperForm (for file upload/LinkedIn login).  
* **Interaction:** Communicates with the Django Backend via RESTful APIs (fetch/axios).  
* **UI/UX:** Must be fully responsive (Tailwind CSS) and optimized for mobile input.

### **1.4.2 Backend (Django)**

* **Authentication & User Management:** Handles user sessions and OAuth 2.0 flow for LinkedIn integration.  
* **API Layer (Django Rest Framework):** Exposes endpoints for data access, scraping initiation, and resume generation.  
* **Scraping & Parsing Module:**  
  * FileUploadHandler: Manages GCS upload and triggers text extraction.  
  * PDFParser (PyPDF2/Tesseract): Extracts text from PDF files.  
  * DOCXParser (python-docx): Extracts text from Word files.  
  * LinkedInManager (Selenium/API): Handles login, navigation, and data extraction.  
* **Generator Module:**  
  * ContextAnalyzer: Takes user context (job title, industry) and filters ResumeChunk data from Firestore.  
  * GeminiAPIManager: Constructs a detailed prompt (Context \+ Filtered Data \+ Template Instructions) and sends it to the Gemini API for generation.

## **1.5 APIs and Integrations**

| Integration | Purpose | Technology/Library | Authentication Method |
| :---- | :---- | :---- | :---- |
| **LinkedIn** | Profile Data Ingestion | Selenium (Web Scraper) / LinkedIn API | OAuth 2.0 (User delegation) |
| **Gemini API** | Resume Generation | Python requests (POST to generateContent) | API Key (Server-side use) |
| **Google Cloud Storage** | Raw File Management | Python google-cloud-storage SDK | Service Account / Default Credentials |
| **Firestore** | Data Chunk Storage | Python firebase-admin SDK | Service Account / Default Credentials |

