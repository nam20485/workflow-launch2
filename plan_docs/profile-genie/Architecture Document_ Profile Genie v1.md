# **Architecture Document: Profile Genie**

Version: 1.2  
Date: 2025-10-13  
Author(s): Gemini, User

### **1\. Introduction**

This document outlines the software architecture for **Profile Genie**, a web application designed to automate the application process for user research studies on platforms like userinterviews.com. The system intelligently learns a user's profile over time and uses this data to automatically fill out repetitive screening surveys, leveraging a reconnaissance "Scout Agent" to map out dynamic, multi-step questionnaires before the user's primary account engages with them.

1.1. Project Vision  
The core vision is to create a "smart assistant" that eliminates the most tedious and repetitive aspect of applying for user research studies: filling out the same personal and professional information repeatedly. By learning a user's profile once, the application saves the user significant time and effort, allowing them to focus on finding high-quality studies rather than on the application process itself. The system is designed to be a trusted agent, prioritizing the security and privacy of the user's data above all else.

### **2\. Architectural Goals**

* **Security:** As the application will handle both its own user credentials and, critically, the credentials for third-party websites, security is the paramount architectural driver. Every decision must be weighed against its security implications, from data storage to inter-service communication.  
* **Maintainability:** The architecture must be modular to facilitate clean, separated development. A change in the Blazor UI, for instance, should have zero impact on the Playwright Service's automation logic. This is achieved through a service-oriented approach with well-defined API contracts.  
* **Robustness:** Web scraping and browser automation are inherently brittle. The target website can change its layout, add anti-bot measures, or alter its survey flow at any time. The architecture must be resilient to these changes, incorporating strategies that are not dependent on fragile CSS selectors and can gracefully handle failures and unexpected states (like CAPTCHAs).  
* **Developer Productivity:** By leveraging the unified .NET ecosystem (.NET Aspire, ASP.NET Core, Blazor, EF Core), the development team can use a single language (C\#) and a consistent set of patterns across the entire stack. This reduces context-switching, simplifies the toolchain, and accelerates the development lifecycle.

### **3\. System Architecture**

Profile Genie will be implemented as a service-oriented architecture, orchestrated by **.NET Aspire**. This model provides a clear separation of concerns, enhances scalability, and simplifies local development and deployment.

**Core Components:**

* **Blazor UI (Frontend):** A **Blazor Server** application. This choice is deliberate; it allows for a highly interactive, "desktop-like" experience without the complexity of managing state on the client. Since the application is a power tool used in a stable environment (not a public-facing website), the requirement for a persistent SignalR connection is an acceptable trade-off for the rapid development it enables. It is responsible for rendering all UI and handling user interactions.  
* **ASP.NET Core API (Backend):** The central nervous system of the application. It is a stateless service that acts as the single source of truth for business logic. Its responsibilities include:  
  * Managing the user identity lifecycle via ASP.NET Core Identity.  
  * Serving as the sole interface to the PostgreSQL database.  
  * Securely handling the encryption and decryption of external credentials.  
  * Coordinating the high-level workflow of the Scout and Primary automation runs by making calls to the Playwright Service.  
* **Playwright Service (Automation Engine):** A minimal, standalone ASP.NET Core API whose sole responsibility is to execute browser automation tasks via **Playwright**. It is completely decoupled from the main application's business logic and database. It exposes a small, dedicated API for automation tasks and internally manages a pool of browser instances to execute jobs.  
* **PostgreSQL Database:** The primary data store. PostgreSQL was chosen for its robustness, extensibility, and powerful support for JSONB data types, which is critical for storing the flexible structure of user profile answers.

3.1. Component Communication Flow  
Communication between services is primarily handled via RESTful HTTP API calls, managed by .NET Aspire's service discovery. This ensures a loosely coupled system.  
sequenceDiagram  
    participant User  
    participant BlazorUI as Blazor UI  
    participant BackendAPI as Backend API  
    participant PlaywrightSvc as Playwright Service

    User-\>\>+BlazorUI: Initiates Scout Run  
    BlazorUI-\>\>+BackendAPI: POST /api/applications/scout  
    BackendAPI-\>\>BackendAPI: Decrypt Scout Credentials  
    BackendAPI-\>\>+PlaywrightSvc: POST /scrape (with credentials)  
    PlaywrightSvc--\>\>-BackendAPI: Returns \[full\_question\_list\] or {error: 'CAPTCHA\_DETECTED'}  
    BackendAPI--\>\>-BlazorUI: Returns unknown questions or error state  
    User-\>\>+BlazorUI: Fills answers & submits  
    BlazorUI-\>\>+BackendAPI: POST /api/applications/fill  
    BackendAPI-\>\>BackendAPI: Decrypt Primary Credentials  
    BackendAPI-\>\>+PlaywrightSvc: POST /fill (with credentials & answers)  
    PlaywrightSvc--\>\>-BackendAPI: Returns {success: true}  
    BackendAPI--\>\>-BlazorUI: Returns success status

The **"Interactive Loop Model"** fallback represents a significant deviation from this pattern. If triggered, the Backend API will establish a persistent **SignalR** (WebSocket) connection to the Playwright Service. This allows for the real-time, bi-directional communication necessary for the backend to feed the user's answers to the automation engine one by one as it navigates the survey.

### **4\. Data Architecture**

* **Database System:** PostgreSQL  
* **Data Access:** Entity Framework Core, using a code-first approach with migrations to manage schema evolution.

**Key Data Models (Expanded):**

1. **User (ASP.NET Core Identity):** Standard tables for user accounts.  
2. **UserProfileData:** Stores the atomic profile data points.  
   * CanonicalKey: A normalized key (e.g., "employment.job\_title"). This allows the system to group variations of the same question.  
   * QuestionVariants: A list of actual phrasings (e.g., "What is your role?", "Current Position?") that map to the CanonicalKey. This data is crucial for future semantic matching improvements.  
   * AnswerValue (jsonb): This flexible field stores the answer in a structured way.  
     * For a text answer: "Product Manager"  
     * For a number: 550  
     * For a multi-select answer: \["Jira", "Figma", "Slack"\]  
   * AnswerType: Metadata tag (e.g., "text", "single-choice", "multi-choice").  
3. **ExternalCredential:** Securely stores external credentials.  
   * EncryptedUsername, EncryptedPassword: Encrypted using .NET Data Protection APIs. The keys for this encryption are managed by the application's hosting environment and stored securely (e.g., in Azure Key Vault for production, or the local user's profile for development).

### **5\. API Endpoints (Detailed)**

**Backend API Endpoints:**

* /api/applications/scout: Initiates the reconnaissance run.  
  * **Request Body:** { "targetUrl": "..." }  
  * **Success Response Body (200):** { "unknownQuestions": \[{ "questionText": "...", "type": "single-choice", "options": \["A", "B"\] }\] }  
  * **Error Response Body (409 \- Conflict):** { "error": "CAPTCHA\_DETECTED", "message": "Scout run halted by a CAPTCHA. Manual intervention may be required." }  
* /api/applications/fill: Initiates the final form-filling.  
  * **Request Body:** { "targetUrl": "...", "answers": \[{ "questionText": "...", "answer": "..." }\] }  
  * **Response Body (200):** { "success": true, "message": "Application submitted successfully." }

**Playwright Service Endpoints:**

* /scrape: Executes the Scout run.  
  * **Request Body:** { "targetUrl": "...", "username": "...", "password": "..." }  
  * **Success Response Body (200):** { "discoveredQuestions": \["...", "...", ...\] }  
* /fill: Executes the primary account's run.  
  * **Request Body:** { "targetUrl": "...", "username": "...", "password": "...", "actions": \[{ "type": "fill", "label": "...", "value": "..." }\] }  
  * **Success Response Body (200):** { "success": true, "finalScreenshotPath": "..." }

### **6\. Authentication and Security**

* **Internal Authentication:** Standard ASP.NET Core Identity.  
* **API Security:** JWTs are issued upon login and contain claims such as UserId and email. They have a defined, short-lived expiration (e.g., 1 hour) and are refreshed using a long-lived refresh token to maintain a secure user session.  
* **External Credential Security:** The encryption/decryption process is handled exclusively within the Backend API. Decrypted credentials exist only in memory for the brief duration of a request to the Playwright Service and are never logged or stored elsewhere. This prevents them from ever touching disk in an unencrypted state.

### **7\. Risk Mitigation Summary (Expanded)**

1. **Bot Detection:** This is mitigated through a multi-layered strategy within the **Playwright Service**.  
   * **Human-like Timing:** Actions are not instantaneous. The service will use Task.Delay with randomized millisecond values between navigations and clicks. For text entry, it will use locator.PressSequentiallyAsync() to simulate keystrokes.  
   * **Realistic Browser Fingerprint:** Playwright will be launched in **headed mode** on a virtual frame buffer (Xvfb) on the server. The user-agent string will be set to a common, modern browser, and the viewport will be set to a standard desktop resolution.  
   * **Stateful Sessions:** The service will perform a login, save the session state (cookies, local storage) using browserContext.StorageStateAsync(), and then inject this state into subsequent contexts.  
   * **CAPTCHA Handling:** The service will be programmed to detect selectors for common CAPTCHA providers. If detected, it will immediately halt automation, take a screenshot of the page, and return a specific error to the Backend API. The Blazor UI will then display this screenshot to the user with instructions to resolve it in a manual browser session.  
2. **Dynamic/Sequential Surveys:**  
   * **Primary Mitigation: "Scout Agent" Protocol:** This is the default, preferred strategy. It isolates the inherently "bot-like" behavior of rapidly clicking through a survey to a disposable account, ensuring the primary user's account activity remains clean, fast, and human-like.  
   * **Fallback Mitigation: "Interactive Loop Model":** If a Scout run fails (e.g., the Scout account is locked or encounters an unhandled error), the system will offer the user the option to switch to this mode. This provides a robust fallback that can handle almost any survey structure, at the cost of a more complex, interruptive user experience. The decision to use this model is an explicit choice made by the user on a case-by-case basis.