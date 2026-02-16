# **Job Command Center: Detailed Development Plan**

**Version:** 1.1

**Date:** 2026-02-16

## **1\. Motivation & Guiding Principles**

**Motivation:** The modern job hunt is a numbers game, but "easy apply" bots often lead to account bans or low-quality matches. The **Job Command Center** solves this by combining the speed of automation with the safety of manual browsing. It targets power users who want to aggregate LinkedIn data without risking their reputation score, providing a "God Mode" dashboard to filter, rank, and track applications efficiently.

**Guiding Principles:**

1. **Stealth First:** The automation must never behave in a way that flags the account. This means prioritizing "Human" delays and utilizing the user's real browser session (CDP) over headless browsers.  
2. **Native Integration:** The system leverages the .NET ecosystem (.NET 9, Aspire, Blazor) to provide a robust, type-safe, and high-performance experience that runs locally on the user's machine.  
3. **Data Ownership:** Users own their pipeline. All data is stored in a structured SQL database (PostgreSQL), allowing for complex querying and long-term history tracking, unlike ephemeral browser extensions.

## **2\. Architectural Decisions**

We have selected the following architecture to meet our Stealth and Performance goals:

1. **Orchestration via .NET Aspire:** Selected to manage the complexity of running a database, a web UI, and a background worker simultaneously. It simplifies the "F5 to Run" experience for developers.  
2. **Blazor Server UI:** Chosen over React to keep the stack 100% C\#. This allows us to share Job models and scoring logic directly between the UI and the Harvester without duplication or API translation layers.  
3. **Playwright over CDP:** Chosen over Selenium/Puppeteer. Playwright's modern API allows robust handling of dynamic content (LinkedIn's Shadow DOM), and its CDP connection capabilities are first-class, enabling the "God Mode" requirement.

## **3\. Core Technologies**

* **Language:** C\# 12  
* **Framework:** .NET 9 (Aspire)  
* **UI Framework:** Blazor Server (Bootstrap/Tailwind styling)  
* **Automation:** Microsoft.Playwright (via CDP)  
* **Database:** PostgreSQL (via Entity Framework Core)  
* **Orchestration:** .NET Aspire

## **4\. Phased Development Plan**

### **Phase 1: Foundation & Infrastructure**

* **Objective:** Scaffold the Aspire solution, set up the PostgreSQL database, and ensure all projects can communicate.  
* **Task 1.1: Solution Scaffolding**  
  * Create ProfileGenie.sln with AppHost, ServiceDefaults, Data, Shared, Web, and Harvester projects.  
  * Configure AppHost to spin up a PostgreSQL container.  
* **Task 1.2: Data Modeling**  
  * Define Job entity in ProfileGenie.Shared.  
  * Implement AppDbContext in ProfileGenie.Data.  
  * Run initial EF Core migrations to create the DB schema.  
* **Deliverables:** A running Aspire dashboard where the Web and Harvester projects connect successfully to the database.

### **Phase 2: The "God Mode" Harvester**

* **Objective:** Implement the stealth automation logic to read from a local Chrome instance.  
* **Task 2.1: CDP Connection Logic**  
  * Implement logic in Harvester to connect to localhost:9222.  
  * Add fallback logic to launch a persistent context if connection fails.  
* **Task 2.2: LinkedIn Scraper Implementation**  
  * Implement ScrollJobsList and ExtractJobData using Playwright locators.  
  * Add logic to parse "Top Applicant" badges and Pay Rates.  
  * **Crucial:** Implement HumanDelay (randomized sleeps) and mouse jitter algorithms.  
* **Task 2.3: Database Persistence**  
  * Ensure the Harvester saves new unique jobs to the DB and updates existing ones (deduplication).  
* **Deliverables:** A background process that populates the PostgreSQL database with real LinkedIn data when the user browses a search page.

### **Phase 3: The Command Center (UI)**

* **Objective:** Build the user interface for managing the job pipeline.  
* **Task 3.1: The Dashboard**  
  * Create a Metric Cards row (Total Found, Top Matches).  
  * Create a List/Grid view of jobs, sorted by "Score."  
* **Task 3.2: Scoring Matrix Configuration**  
  * Build a Settings page to adjust weights (e.g., "Remote \= 15pts").  
  * Implement the scoring algorithm in C\# to dynamically update job scores.  
* **Task 3.3: Job Detail & Workflow**  
  * Create a Detail view to see the full job description.  
  * Implement "Move Status" functionality (Found \-\> Drafting \-\> Sent).  
* **Deliverables:** A fully interactive Blazor UI that reflects the data harvested in Phase 2\.

## **5\. User Stories (Epics)**

### **Epic: Stealth Harvesting**

* **Story 1: Connect to Chrome**  
  * **As a** Developer,  
  * **I want** the system to connect to my open Chrome window on port 9222,  
  * **So that** I don't have to log in to LinkedIn manually inside a bot browser.  
  * *Acceptance Criteria:* The app starts without launching a new browser window; it attaches to the existing one. If the existing one is closed, it logs a clear error or instructions.  
* **Story 2: Intelligent Scraping**  
  * **As a** User,  
  * **I want** the harvester to extract the "Top Applicant" badge and Salary info,  
  * **So that** I can prioritize high-probability jobs.  
  * *Acceptance Criteria:* Database records correctly reflect the "MatchLevel" and "PayRate" visible on the screen.

### **Epic: Pipeline Management**

* **Story 3: Scoring Matrix**  
  * **As a** User,  
  * **I want** to set a custom weight for "Remote" and "Contract" roles,  
  * **So that** the jobs list automatically ranks my ideal roles at the top.  
  * *Acceptance Criteria:* A slider in UI updates the config; the job list immediately re-sorts based on the new calculation.  
* **Story 4: Status Workflow**  
  * **As a** User,  
  * **I want** to move a job from "Found" to "Pending Approval",  
  * **So that** I can build a queue of applications to work on later.  
  * *Acceptance Criteria:* Changing status visually moves the item or updates its badge. The change persists after restart.

## **6\. Risks and Mitigations**

| Risk | Description | Mitigation Strategy |
| :---- | :---- | :---- |
| **Chrome Port Conflict** | Port 9222 might be in use or Chrome might not be started with the flag. | The Harvester will implement a "Pre-flight Check" to ping localhost:9222/json. If it fails, it will log a distinct error in the Aspire Dashboard instructing the user to restart Chrome with the specific command line arguments. |
| **LinkedIn DOM Changes** | LinkedIn frequently changes CSS class names (e.g., .job-card-container becomes .job-card-v2). | Use robust text-based locators (e.g., GetByRole) where possible. Abstract selectors into a configuration file or a Constants.cs class so they can be updated in one place without recompiling logic. |
| **Bot Detection** | Even with CDP, rapid scraping can trigger limits. | Enforce "Human Delays." Implement a "cool-down" period after harvesting X pages. Ensure the harvester does not run 24/7 but is triggered by user intent or a conservative timer. |
| **Docker Networking** | The Harvester container (if containerized) cannot reach host Chrome. | **Strict Rule:** The Harvester project must be added to Aspire as a Project (process), NOT a container, to share the host network stack. |

