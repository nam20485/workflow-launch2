# **Architecture Document: Job Command Center**

**Version:** 1.0

**Date:** 2026-02-16

**Status:** Approved for Implementation

## **1\. Introduction**

The **Job Command Center** is a specialized, local-first automation suite designed to streamline the job application process on LinkedIn. Unlike traditional cloud-based scrapers that use ephemeral browser sessions (high ban risk), this system utilizes a "God Mode" architecture: it connects directly to the user's existing, authenticated local Chrome instance via the Chrome DevTools Protocol (CDP).

This architecture allows the application to "fly under the radar" by leveraging the user's real browser fingerprint, cookies, and history, effectively making the automation indistinguishable from manual user interaction.

## **2\. Architectural Goals**

1. **Maximum Stealth ("God Mode"):** The primary driver is account safety. The automation must operate within an existing, human-used browser context, not a fresh, clean-slate bot instance.  
2. **Local Sovereignty:** All data (job listings, notes, status tracking) must reside in a local database (or user-controlled cloud DB), ensuring the user owns their pipeline data.  
3. **Unified Orchestration:** The system must run as a cohesive unit. The database, background harvesters, and frontend UI should launch together and share configuration seamlessly.  
4. **Type Safety & Ecosystem:** The entire stack (Orchestration, UI, Automation, Database Access) must leverage .NET 9 and C\# to maximize code sharing and developer velocity.

## **3\. System Architecture**

The solution follows a **Service-Oriented Architecture (SOA)** managed by **.NET Aspire**.

### **3.1 High-Level Diagram**

graph TD  
    User\[User's Local Chrome\] \<--\>|CDP Port 9222| Harvester  
      
    subgraph ".NET Aspire Host (Orchestrator)"  
        Harvester\[LinkedIn Harvester\<br/\>(Worker Service)\]  
        CommandCenter\[Job Command Center\<br/\>(Blazor Server UI)\]  
        Postgres\[(PostgreSQL Container)\]  
    end

    Harvester \--\>|Writes Jobs| Postgres  
    CommandCenter \<--\>|Reads/Updates Jobs| Postgres  
    CommandCenter \--\>|Configures| Harvester

### **3.2 Core Components**

#### **A. The Orchestrator (ProfileGenie.AppHost)**

* **Technology:** .NET Aspire  
* **Responsibility:** Manages the lifecycle of all resources. It spins up the PostgreSQL container, launches the Harvester as a background process, and starts the Blazor web server.  
* **Critical Configuration:** It injects the connection string into both services and sets the CHROME\_DEBUG\_PORT environment variable for the Harvester.

#### **B. The Harvester (ProfileGenie.Harvester)**

* **Technology:** .NET Worker Service \+ Microsoft.Playwright  
* **Execution Model:** Runs as a **Process** (not a Docker container) on the host machine.  
  * *Why?* Docker containers generally cannot access localhost ports of the host machine easily across all OSs. Running as a process allows effortless connection to the user's Desktop Chrome instance on port 9222\.  
* **Responsibility:** \* Connects to Chrome over CDP.  
  * Navigates LinkedIn Search.  
  * Scrapes job data (Title, Pay, "Top Applicant" status).  
  * Persists data to PostgreSQL.  
  * Implements "Humanizing" logic (random delays, mouse jitter).

#### **C. The Command Center (ProfileGenie.Web)**

* **Technology:** Blazor Server (.NET 9\)  
* **Responsibility:**  
  * **Dashboard:** Kanban-style view of the job pipeline.  
  * **Scoring Engine:** Calculates job scores based on a user-defined matrix (e.g., Remote \+15pts, Pay \> $100 \+20pts).  
  * **Asset Management:** Editors for tailoring resumes/cover letters per job.

#### **D. Data Store (ProfileGenie.Data)**

* **Technology:** PostgreSQL (Dev: Container, Prod: Supabase/Cloud SQL)  
* **Access:** Entity Framework Core. \* **Schema:** Relational tables for Jobs, HistoryLog, and Settings.

## **4\. Key Technical Decisions**

### **4.1 The "CDP" Connection Strategy**

Standard Playwright scripts launch a new browser (browserType.LaunchAsync). This system is strictly forbidden from doing so for harvesting.

* **Constraint:** The Harvester must utilize browserType.ConnectOverCDPAsync($"http://localhost:{port}").  
* **Fallback:** If the connection fails, it may launch a persistent context pointed at a local user data directory, but never an ephemeral/incognito browser.

### **4.2 Data Flow**

1. **User** launches Chrome with \--remote-debugging-port=9222.  
2. **User** starts the .NET Aspire solution.  
3. **Harvester** wakes up, connects to Chrome, and begins the "Search Cycle."  
4. **Harvester** writes new job records to the Jobs table in Postgres.  
5. **Command Center** uses IObservable or Polling to detect new DB records and updates the UI "Found" column.  
6. **User** reviews jobs in the UI, marking them as "Pending Approval" or "Rejected."

## **5\. Security Considerations**

* **Credential Handling:** The application **never** handles LinkedIn passwords. Authentication is handled entirely by the user in the external Chrome window. The app only piggybacks on the existing session cookies.  
* **Database:** In Development, the DB password is managed by Aspire user secrets. In Production, connection strings must be injected via secure environment variables.

## **6\. Directory Structure**

/ProfileGenie  
├── ProfileGenie.sln  
├── /ProfileGenie.AppHost       \# Orchestrator  
├── /ProfileGenie.ServiceDefaults \# OpenTelemetry/HealthChecks  
├── /ProfileGenie.Data          \# EF Core Context & Migrations  
├── /ProfileGenie.Shared        \# Shared DTOs (Job.cs, JobStatus.cs)  
├── /ProfileGenie.Harvester     \# Playwright Worker Service  
└── /ProfileGenie.Web           \# Blazor Server UI  
