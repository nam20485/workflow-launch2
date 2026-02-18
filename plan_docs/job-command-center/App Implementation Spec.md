# **New Application: Job Command Center (job-command-center)**

## **1\. Description**

### **Overview**

The **Job Command Center** is a high-performance, local-first automation platform engineered for aggressive yet stealthy job searching on LinkedIn. In an era where LinkedIn employs sophisticated behavioral analysis and fingerprinting to block automated agents, this application adopts a "God Mode" architecture. Instead of launching a fresh, suspicious browser instance, it attaches to an existing, human-authenticated user session via the **Chrome DevTools Protocol (CDP)**.

By leveraging a browser that is already logged in, has a consistent history, and possesses a legitimate hardware fingerprint, the application effectively "co-pilots" the user's search. This approach prioritizes **Account Safety** above all else, ensuring that the automation is virtually indistinguishable from manual browsing while providing the data-processing power of a modern .NET 9 backend.

### **Document Links**

* **Architecture Guide**:<./Architecture Document_ Job Command Center.md>
  \- Detailed breakdown of the CDP handshake and network topology.  
* [Development Plan](./Development Plan - Job Command Center.md)  
  \- Multi-phase roadmap covering the Harvester, Data, and UI iterations.  
* **API Specs**: (TBD \- Internal Only) \- Documentation for the Minimal API layer used by the Blazor frontend.

## **2\. Requirements**

### **Features**

* **God Mode Harvester (CDP Worker)**:  
  * A dedicated .NET Worker service that performs a "handshake" with localhost:9222.  
  * It utilizes browserType.ConnectOverCDPAsync() to assume control of the active tab.  
  * It must handle "Tab Management," identifying the LinkedIn search tab or opening a new one within the existing authenticated context.  
* **Human-Mimicry Engine (Anti-Detection)**:  
  * Implements **Non-Linear Delays**: Instead of a static Thread.Sleep(5000), it uses a Gaussian distribution to determine wait times between actions.  
  * **Micro-Interactions**: Includes randomized mouse "jitters," organic scrolling speeds that mimic a human reading a page, and occasional "distraction" clicks on non-essential elements to break mechanical patterns.  
* **Relational Pipeline (PostgreSQL)**:  
  * A robust schema that tracks the full job lifecycle.  
  * **Stages**: Found (Scraped but unreviewed), Scored (Processed by engine), Pending (User approved), Applied, Interviewing, and Archive.  
  * Supports many-to-many relationships for Job Categories and Skill Tags.  
* **Dynamic Scoring Matrix**:  
  * A user-editable weighting system. For example: Remote \= \+50pts, Python \> 3 years \= \+30pts, Promoted/Ad \= \-20pts.  
  * The engine runs locally in the Shared library, allowing both the Harvester (for pre-filtering) and the Web UI (for re-ranking) to use identical logic.  
* **Command Center Dashboard (Blazor Kanban)**:  
  * A high-density dashboard built with **MudBlazor**.  
  * Features a "Live Feed" component that shows the Harvester's current action (e.g., "Scanning Page 4...", "Extracting Job ID 3829...").

### **Test Cases**

* **TC-01 (Connectivity)**: Verify the Harvester throws a descriptive ChromeNotRunningException when port 9222 is unreachable, rather than a generic timeout.  
* **TC-02 (Data Extraction)**: Validate that the Scraper can correctly identify "Ghost Postings" (jobs that are no longer accepting applications) by parsing specific sub-elements in the LinkedIn Shadow DOM.  
* **TC-03 (Persistence)**: Ensure that updating a Job's status in the Blazor UI triggers a "Concurrency Check" in EF Core to prevent overwriting data if the Harvester is simultaneously updating that record.  
* **TC-04 (Scoring Real-time)**: Adjusting a keyword weight from 10 to 50 in the Settings panel must trigger a background re-calculation of all Found jobs within \< 500ms.

### **Logging & Observability**

* **OpenTelemetry**: Fully integrated via .NET Aspire Service Defaults. Includes traces for every "Search Cycle" and metrics for "Jobs Per Minute."  
* **Harvester Verbosity**: Uses structured logging (Serilog) to capture the exact CSS selector that failed during a scrape, facilitating rapid maintenance when LinkedIn updates their UI.  
* **The Audit Log (HistoryLog)**: Every state change (e.g., moving a job from "Found" to "Applied") is timestamped and attributed to either "System" (Harvester) or "User" (UI).

### **Containerization & Deployment**

* **PostgreSQL**: Managed as a containerized resource via .AddPostgres() in the Aspire AppHost.  
* **Web Dashboard**: Container-ready for production deployment on a home server or local workstation.  
* **The Harvester Exception**: **MANDATORY RULE:** The Harvester *must* run as a native host process (.AddProject\<Projects.JobCommandCenter\_Harvester\>()). If placed in a Docker container, it will lose access to the host's loopback interface where the Chrome CDP port resides, causing connectivity failure.

## **3\. Technology Stack**

* **Language**: C\# 12 / .NET 9.0 (Utilizing performance-oriented LINQ features).  
* **Orchestration**: **.NET Aspire** (The "glue" that connects the DB, UI, and Worker).  
* **Automation**: **Playwright for .NET** (The industry standard for reliable browser automation).  
* **Frontend**: **Blazor Server** (Chosen to allow direct DB access via EF Core without the overhead of a REST API for local usage).  
* **Database**: **PostgreSQL** with **Entity Framework Core** (Migrations managed via the Data project).  
* **UI Components**: **MudBlazor** (Provides the DataGrids and Kanban components needed for high-density information).

## **4\. Project Structure**

/JobCommandCenter  
├── JobCommandCenter.AppHost          \# Orchestrates startup and resource injection.  
├── JobCommandCenter.ServiceDefaults  \# Standardized telemetry and health checks.  
├── JobCommandCenter.Data             \# Persistence layer: DbContext and Migrations.  
├── JobCommandCenter.Shared           \# Domain models: Job, ScoringConfig, and common logic.  
├── JobCommandCenter.Harvester        \# The Playwright Worker: CDP loops and scraping logic.  
└── JobCommandCenter.Web              \# The Management Dashboard: Blazor Server UI.

## **5\. Deliverables**

1. **Solution AppHost**: A runnable orchestrator that manages the lifecycle of all services.  
2. **Database Migration Engine**: Automated migration of the PostgreSQL schema on application startup.  
3. **The "God Mode" Binary**: A high-performance Harvester capable of running as a background service.  
4. **Operational Dashboard**: A browser-accessible UI for real-time monitoring and manual intervention.  
5. **Configuration Guide**: A README specifically detailing how to launch Chrome with the required \--remote-debugging-port flag.

## **6\. Acceptance Criteria**

* **Connectivity**: The system must successfully attach to an existing Chrome window and perform a "WhoAmI" check to verify the LinkedIn session is active.  
* **Performance**: The Harvester must be capable of processing 100 job listings (extraction \+ scoring) in under 5 minutes without triggering a rate limit.  
* **Responsiveness**: The Blazor dashboard must reflect database changes (new jobs found) within 2 seconds.  
* **Resilience**: If Chrome is closed during a scrape, the Harvester must enter a "Retry-Backoff" state and resume once the port becomes available again.  
* **Data Integrity**: No duplicate Job IDs allowed in the database; "Easy Apply" vs "External Apply" must be correctly categorized 100% of the time.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAmwAAAAtCAYAAAATDjfFAAAFB0lEQVR4Xu3c3YtWRRgA8F0yCvqksK189z3vqmVBgWZF9IEigmFEEXUb1JVUFN0V3flxJwhJlF0USReBECRJ3YRElIQkqFQYBhGKhBCCf4A9z+6MzR53wcyw6PeD4cw8M2fOx9XDzHnfsTEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA+M+YmpqaqCWal/X7z8doNNo9MTFxVT9+qQ0GgxtqfeXKlZfHYbzp/tvynXVdt74fq2XJkiU3tX0AABekJB1napIxHA6fjfae/rj5xPj3Y/wXUXb1+y61TJjivnbmM5WE9KKKhPC2fHdNaHyO9/lybTfjAADO36JFi27sJR1j2V68ePHtbWw+Zex1Yxe4OvdPi/s70o9dLKPRaFXMf6CNzfM+10Q52cYAAM5bJBJbo+xvQuPRPt20x5YuXbowkpPVbSxlUhdjj/XjaTgcPtRuCQ4Gg6V5jHOGf46aEXOvq/XcxqzJYsTvKFuZs8Q178m+NhbXWxzxFW1s2bJl1/STp75uZktz1lZpzH1z/3nzevEerm1jce6+iD/ai+X73NfGFi5ceHX/PnK+KFe2sRTP8fhczwwA/I9FInEkkoRXcpWsrBid6vXvqQlE16wmZTKW231xzidtYpZJTYzbmPXof7ic916Uj6Mci/4rurJ9GufuqGPj+EM555m8ZvTtLvEzbWIT9UMl/nyUt0r9aBzGy30uqGNjrqfz/NpuxTyvRt/2Uj80OTl5a9bjnG15vWxHua/074jDePStjHO+rnPk3JmM1XaJTb/PNhbz3NXeR3nWTIw3x9wbyphH4rxvS/xEHQsAMCshiuPyrlldy8QiypaS+Pzc/w4rYvujb21tl2/Gcr7VcdwYZW/G6wpTxK/vjd1Zxh5st2B7yc2sepQ7a7uJrY95novjb72+w1E2tbF4hvtLUvlhM257lF1RvoqypR0f8+6O2LulnlbVvq63HZrPl/cz6q2cRWxvV1Yxu9nvd0WOL/XphBUA4Bxd821VJBoP1ASi9GXyMartvtJ/NgmL+rpuni3Sdt6UY/N6bazEp5Oe2q6JTqmfs1pWYmdX1VrZl6tbbSyTqSgb2mvHuKNRXprreTPWla3WXDnL80vXgqi/3gytK3qzvlXL8TlHbivXhLYZvy3a+/Ie+3MBAEyLJGF5u33Xzawy1RWfzVF+yY/om/5var0kH7O+dZuamopQd7i2m1Wz3Obrr3R17apa3MeXeYxxWzORKbG10b6lK6te7fXyb0Si/WabAOWWaPudWdtXEqfp7d7c6sx5y5gX4zoflfrpdoszxt1bYzl3zpcJZSZ7mfTlN3Jx7ud1fPQfbd9n3uOobOEWC9p76srWZ97zqPkWritbtQDA/1wmDrWMyvdig8Hg7hL7LJrjJSk6GeVgV741a85/rJvj7z8i9kJ+ixXl15hvUcbyhwb5Fxj9sTmmjH27xuL87+rYspV6IO8r23GfT+Y5ETse5cGM5Y8Zon4i+n6K41NljvxmLp+jX9rVulN57TjviRorf8nxe5Tvo7yRsbz3qJ+IsimTtK5sg5Z7OxiJ62SZr71OltMx/rU6d9XNbIPuj3K8F/8x7yeOn471fgQBAPCXlV+NfhDJxZp+HwAAl1jZWjw8HA7f6fcBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8O/2B4IDQXdct0aEAAAAAElFTkSuQmCC>