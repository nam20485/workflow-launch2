# **New Application**

## **App Title**

Profile Genie

## **Development Plan**

This project will follow an Agile development methodology, focusing on iterative delivery of the features outlined in the user story backlog. The development will be organized into logical phases, starting with the core application infrastructure and security, followed by the implementation of the automation engine and "Scout Agent" protocol, and culminating in the primary application workflow and user experience enhancements. The detailed, phased backlog is available in the "Detailed Development Plan: Profile Genie v1" document.

## **Description**

### **Overview**

Profile Genie is a web application designed to automate the tedious process of applying for user research studies. It functions as a smart assistant that learns a user's professional and personal profile over time. It then leverages this stored profile to automatically fill out repetitive screening surveys on platforms like userinterviews.com.

A key innovation is the "Scout Agent" protocol, which uses a disposable secondary account to perform reconnaissance on multi-step questionnaires. The Scout Agent navigates the entire survey, gathers all the questions, and presents only the unknown ones to the user. Once the user provides the new answers, the system uses the user's primary account to fill and submit the application in a single, fast, and human-like pass.

The architecture prioritizes security, maintainability, and robustness to create a trusted, reliable, and time-saving tool for user research participants.

### **Document Links**

* Architecture Document: Profile Genie v1  
* Detailed Development Plan: Profile Genie v1

## **Requirements**

### **Features**

* \[x\] **User Accounts:** Secure user registration, login (JWT-based), and logout.  
* \[x\] **Profile Management:** A dedicated UI for users to create, view, update, and delete their profile data (question/answer pairs).  
* \[x\] **Secure Credential Storage:** Encrypted storage (.NET Data Protection APIs) for third-party (Primary and Scout) account credentials.  
* \[x\] **Scout Agent Protocol:** An automation workflow to map multi-page surveys using a disposable account to discover all questions.  
* \[x\] **Intelligent Question Review:** A system to compare scouted questions against the user's profile and only prompt the user for answers to unknown questions.  
* \[x\] **Primary Application Workflow:** An automation workflow to log in with the user's primary account and fill out the entire survey using the complete profile data.  
* \[x\] **Informative Dashboard:** A central dashboard displaying profile completeness, recent activity, and suggested studies.  
* \[x\] **Advanced Filtering:** Tools for users to filter and sort available studies by criteria like payout, keywords, and match score.  
* \[x\] **Bot Evasion:** Human-like automation techniques (random delays, simulated typing, realistic browser fingerprint) to minimize the risk of detection.  
* \[x\] **CAPTCHA Handling:** Graceful failure upon detecting a CAPTCHA, notifying the user with a screenshot to allow for manual intervention.  
* \[ \] **Interactive Fallback Mode (Stretch Goal):** A SignalR-based real-time mode for handling surveys where the Scout protocol fails.

### **Test cases**

* Unit and integration tests will be written for all backend business logic, targeting a high code coverage percentage.  
* End-to-end tests will be developed for the core user workflows, including registration, profile editing, and the complete scout-then-fill application process.

### **Logging**

* Structured logging (e.g., using Serilog) will be implemented across all services.  
* Logs will be separated by service and will capture key events, errors, and automation outcomes. In production, logs will be shipped to a centralized logging provider.

### **Containerization: Docker**

* \[x\] Each service (Backend API, Playwright Service) will have a dedicated Dockerfile for containerization.  
* \[x\] The database will run in a Docker container for local development consistency.

### **Containerization: Docker Compose**

* \[x\] A docker-compose.yml file will be provided to orchestrate the entire application stack (UI, API, Automation Service, Database) for simplified local development setup.

### **Swagger/OpenAPI**

* \[x\] The ASP.NET Core API and the Playwright Service will expose an OpenAPI (Swagger) specification for clear API documentation and testing.

### **Documentation**

* \[x\] A README.md file will detail the project setup, configuration, and how to run the application locally.  
* \[x\] Code will be documented with comments, particularly for complex business logic and public-facing API methods.

### **Acceptance Criteria**

Acceptance for each feature is defined by the specific, testable criteria outlined in the user stories within the "Detailed Development Plan: Profile Genie v1" document. The project is considered complete when all stories are implemented and their respective acceptance criteria are met and validated.

## **Language**

C\#

## **Language Version**

.NET v9.0

\[x\] Include global.json? sdk: "9.0.0", rollForward: "latestFeature"

## **Frameworks, Tools, Packages**

| Category | Technology / Package | Rationale |
| :---- | :---- | :---- |
| **Orchestration** | .NET Aspire | Simplifies local development, service discovery, and deployment orchestration for a multi-service architecture. |
| **Backend Framework** | ASP.NET Core | High-performance, mature framework for building robust, cross-platform APIs. |
| **Frontend Framework** | Blazor Server | Enables a rich, interactive UI with C\#, reducing context switching and providing a "desktop-like" feel suitable for a power-user tool. |
| **Database** | PostgreSQL | Robust, open-source relational database with excellent support for JSONB, ideal for storing flexible profile data. |
| **Data Access** | Entity Framework Core | Modern ORM that simplifies data access and provides a code-first migrations workflow for schema management. |
| **Browser Automation** | Playwright | A modern, reliable, and powerful library for browser automation that is well-supported and offers a rich feature set. |
| **Authentication** | ASP.NET Core Identity | Provides a secure and battle-tested framework for managing user accounts, password hashing, and token generation (JWTs). |
| **Real-time Fallback** | SignalR | Enables real-time, bi-directional communication needed for the "Interactive Loop Model" stretch goal. |

## **Project Structure/Package System**

The solution will be organized as a service-oriented architecture managed by a .NET Aspire AppHost project.

* **ProfileGenie.AppHost**: The .NET Aspire project that orchestrates all other services.  
* **ProfileGenie.Web**: The Blazor Server project containing all UI components and client-side logic.  
* **ProfileGenie.ApiService**: The main ASP.NET Core backend API. It handles all business logic, user identity, and database interactions.  
* **ProfileGenie.PlaywrightService**: A minimal, standalone ASP.NET Core API dedicated exclusively to running Playwright automation jobs.  
* **ProfileGenie.Data**: A class library containing the Entity Framework DbContext and data models.  
* **ProfileGenie.Shared**: A class library for shared DTOs and contracts between the services.

## **GitHub**

### **Repo**

https://github.com/nam20485/ProfileGenie

### **Branch**

main

## **Deliverables**

1. A fully functional, containerized web application implementing all the features listed above.  
2. Complete source code hosted in the specified GitHub repository.  
3. Comprehensive documentation (README.md) covering setup, configuration, and local deployment.  
4. Dockerfiles for each service and a Docker Compose file for easy local orchestration.  
5. An OpenAPI specification for all backend services.