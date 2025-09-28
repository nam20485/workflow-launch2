# **Gap-Miner: Software Architecture Document**

Document Version: 1.1  
Date: September 12, 2025  
Author: Gemini

### **1\. Introduction**

#### **1.1. Purpose**

This document outlines the software architecture for the Gap-Miner application. It describes the high-level structure of the system, its main components, their responsibilities, and the interactions between them. This document serves as a technical blueprint for the engineering team to guide implementation, ensuring consistency and adherence to best practices. It is also intended for technical stakeholders, such as product managers and project leads, to understand the system's design, capabilities, and constraints. This is a living document, expected to evolve as the project progresses through development phases and new requirements emerge.

#### **1.2. Scope**

The scope of this architecture is primarily focused on delivering the Minimum Viable Product (MVP) as defined in the Development Plan. This includes end-to-end functionality for a single user to configure data sources (initially Reddit only), have the system automatically mine those sources for "gaps," and view the results in a web-based dashboard with basic email alerts.

**Explicitly Out of Scope for MVP:**

* Multi-user accounts or team-based collaboration features.  
* Billing, subscription management, and payment processing.  
* Advanced AI/ML features such as trend analysis, gap summarization, or predictive opportunity scoring.  
* Direct integration with project management tools (e.g., Jira, Trello).  
* Real-time, push-based notifications (e.g., WebSockets).

### **2\. Architectural Goals & Constraints**

The architecture is designed to meet the following key non-functional requirements, which guide the technical decisions throughout this document.

* **Scalability:** The system must be designed for growth. This means it must handle an increasing volume of data sources, a higher frequency of data ingestion, and a growing user base without significant performance degradation. The architecture prioritizes horizontal scalability for its data processing components, allowing us to add more computing resources as needed.  
* **Modularity:** The system is broken down into logical, loosely coupled components with well-defined responsibilities. This approach allows for independent development, testing, and deployment cycles. For example, a new data source connector for Twitter can be developed and deployed without affecting the existing Reddit connector or the core API service.  
* **Reliability & Resilience:** The data pipeline must be robust. It should gracefully handle transient failures, such as temporary unavailability of an external API or network issues. This will be achieved through mechanisms like automated retries with exponential backoff for API calls and a dead-letter queue for jobs that fail repeatedly, allowing for manual inspection and reprocessing.  
* **Maintainability:** The long-term health of the project depends on a clean, well-documented, and easily understood codebase. We will enforce strict coding standards (e.g., PEP 8 for Python), a comprehensive test suite (unit, integration, and end-to-end tests), and leverage our CI/CD pipeline to maintain high code quality.  
* **Security:** Security is a primary concern. The architecture will incorporate security best practices at every layer. This includes encrypting all data in transit (TLS) and at rest, secure user authentication and session management (using JWTs), password hashing, and protection against common web vulnerabilities as outlined by the OWASP Top 10\.

### **3\. System Architecture Overview**

We will adopt a **service-oriented architecture**. This model provides a pragmatic balance for the MVP, avoiding the high initial complexity of a full microservices architecture while providing much greater flexibility and scalability than a traditional monolith. It allows us to build the system as a set of distinct logical services that can be physically separated into independent microservices as the system grows in complexity and scale.

#### **3.1. Architecture Diagram**

                 \+----------------------+  
                 |     Web Browser      |  
                 |      (React UI)      |  
                 \+----------+-----------+  
                            | (HTTPS / REST API)  
\+---------------------------|----------------------------------------------------+  
|                           |                                                    |  
|         \+-----------------v------------------+                                |  
|         |        API & Web Service           |                                |  
|         |        (Python \- Flask/Django)     |                                |  
|         | \- User Authentication (JWT)      |                                |  
|         | \- API Endpoints (/gaps, /sources)  |                                |  
|         | \- Serves React Frontend          |                                |  
|         \+-----------------+------------------+                                |  
|                           |                                                    |  
|      (Read/Write) \+-------+---------+ (Read/Write)                            |  
|                 |                   |                                        |  
|   \+-------------v-------------+   \+-v--------------------------------------+ |  
|   |      PostgreSQL DB        |   |              Task Queue (Redis)          | |  
|   | \- Users, Sources, Gaps    |   | \- Ingest Jobs (e.g., "scan r/gravl")   | |  
|   | \- Full-Text Search Index  |   | \- Alert Jobs (e.g., "send daily digest") | |  
|   \+---------------------------+   \+--------------------+---------------------+ |  
|                                                        ^                       |  
|                                                        | (Jobs)                |  
|               \+----------------------------------------+----------------+      |  
|               |                                                         |      |  
| \+-------------v-----------------+        \+------------------------------v----+ |  
| |      Scheduler (Celery Beat)  |        |         Worker Service(s)           | |  
| | \- Triggers periodic jobs      |        |         (Python \- Celery)           | |  
| | (e.g., hourly scans)        |        | \- Fetches jobs from Redis           | |  
| \+-----------------------------+        | 1\. Data Collection (Reddit API)     | |  
|                                        | 2\. NLP Processing (Hugging Face)    | |  
|                                        | 3\. Email Dispatch (SMTP)            | |  
|                                        \+-------------------------------------+ |  
\+--------------------------------------------------------------------------------+  
                                       Cloud Environment (e.g., AWS, GCP)

#### **3.2. Component Descriptions**

* **API & Web Service (Monolith for MVP):** The central nervous system of the application, built with Python (likely Flask for its simplicity, or Django for its batteries-included approach). It has three primary responsibilities: serving the static assets for the React frontend, providing a secure RESTful API for all frontend-backend communication (e.g., CRUD operations for sources and fetching gaps), and handling user authentication via JSON Web Tokens (JWTs). It acts as the primary interface to the database for simple operations but offloads all heavy or long-running tasks to the Worker Service via the Task Queue.  
* **PostgreSQL Database:** The authoritative data store. We chose PostgreSQL for its robustness, reliability, and powerful features. Its relational model is perfect for storing structured data like users and sources. Furthermore, its excellent support for JSONB data types allows us to flexibly store semi-structured data like detected\_keywords without compromising query performance. We will also leverage its built-in full-text search capabilities for the dashboard's search functionality.  
* **Task Queue (Redis):** An in-memory message broker that decouples the API service from the resource-intensive worker processes. Using Redis as a queue ensures that the user-facing API remains fast and responsive. When a long-running task like "scan a subreddit with 10,000 comments" is requested, the API service immediately places a job message onto the queue and returns a confirmation to the user. This asynchronous pattern is fundamental to the system's performance and scalability.  
* **Worker Service(s):** One or more Python processes, managed by a framework like Celery. These are the workhorses of the system, running in the background and constantly polling the Task Queue for new jobs. A worker's lifecycle involves fetching a job, executing it (e.g., making numerous calls to the Reddit API, running a computationally intensive NLP model), and then reporting the result. This component is designed to be stateless and can be scaled horizontally with ease. If data processing slows down, we can simply provision more worker containers to increase throughput.  
* **Scheduler (Celery Beat):** A time-based job scheduler responsible for initiating recurring tasks. It operates by periodically adding jobs to the Task Queue. For instance, the scheduler will queue a job every hour to scan all active sources for new content. It will also queue a daily job to generate and send email digests to users. This component ensures the Gap-Miner is continuously and automatically gathering fresh intelligence.

### **4\. Data Architecture**

#### **4.1. Data Flow**

1. **Configuration:** A user logs into the React UI and submits a form to monitor a new subreddit. The UI sends a POST request to /api/v1/sources with an Authorization header containing their JWT and a payload like { "platform": "Reddit", "identifier": "r/androidapps" }.  
2. **Job Queuing:** The API service validates the request, saves the new source configuration to the sources table in PostgreSQL, and then places an "ingest" job onto the Redis Task Queue. The job payload contains the necessary information, like the source\_id. The API then immediately returns a 201 Accepted response to the UI.  
3. **Data Collection:** A Worker service, which has been idle, instantly picks up the ingest job from the queue. It reads the source\_id, queries the database for source details, and begins making calls to the external Reddit API to fetch recent posts and comments.  
4. **Processing:** For each piece of text retrieved, the Worker performs the analysis pipeline: it first checks for the presence of designated keywords. If a match is found, it then runs the text through the pre-trained Hugging Face NLP model to determine its sentiment score.  
5. **Storage:** If the content is deemed a potential "gap" (i.e., it contains keywords and has a negative sentiment score below a certain threshold), the Worker creates a new record in the gaps table in the PostgreSQL database, linking it to the original source.  
6. **Presentation:** Later, the user navigates to their dashboard. The React UI sends a GET request to the /api/v1/gaps endpoint. The API service queries the database for all gaps associated with that user's user\_id, paginates the results, and sends them back to the UI to be rendered in a table or list.

#### **4.2. Database Schema (High-Level)**

* **users**  
  * user\_id (PK, UUID)  
  * email (VARCHAR, UNIQUE)  
  * password\_hash (VARCHAR)  
  * email\_verified\_at (TIMESTAMP)  
  * created\_at (TIMESTAMP)  
* **sources**  
  * source\_id (PK, UUID)  
  * user\_id (FK to users)  
  * platform (VARCHAR, e.g., 'Reddit')  
  * identifier (VARCHAR, e.g., 'r/gravl')  
  * is\_active (BOOLEAN, default: true)  
  * last\_scanned (TIMESTAMP)  
  * created\_at (TIMESTAMP)  
* **gaps**  
  * gap\_id (PK, UUID)  
  * source\_id (FK to sources)  
  * title (TEXT, title of post/comment)  
  * source\_url (VARCHAR, UNIQUE)  
  * original\_content (TEXT)  
  * detected\_keywords (JSONB)  
  * sentiment\_score (FLOAT)  
  * status (VARCHAR, e.g., 'new', 'reviewed', 'archived')  
  * notes (TEXT, user-added annotations)  
  * timestamp (TIMESTAMP, when the content was created)  
  * created\_at (TIMESTAMP, when the record was created)

### **5\. Deployment & Operations**

* **Containerization:** All services (API/Web, Workers, Scheduler) will be containerized using **Docker**. This is non-negotiable as it provides a consistent, isolated, and reproducible runtime environment. It solves the "it works on my machine" problem and greatly simplifies dependency management, forming the foundation of our deployment strategy.  
* **Orchestration:** For local development, **Docker Compose** will be used to allow developers to spin up the entire application stack with a single command. For production, a more robust container orchestration platform like **AWS Elastic Container Service (ECS)** or **Google Kubernetes Engine (GKE)** is required. These platforms provide critical production features like automated scaling (e.g., adding more worker containers when the task queue is long), self-healing (restarting failed containers), and managed service discovery.  
* **CI/CD:** A CI/CD pipeline will be set up using a tool like GitHub Actions. The pipeline will automate our entire release process. On every push to the main branch, the pipeline will automatically: 1\) run linters and static analysis, 2\) execute the full suite of unit and integration tests, 3\) build the production Docker images, 4\) push the images to a container registry (e.g., AWS ECR), and 5\) deploy the new version to a staging environment for final verification before a manual promotion to production.  
* **Monitoring & Logging:** Proactive monitoring is essential for operational stability. All services will be configured to output structured logs (in JSON format). These logs will be aggregated in a centralized logging platform (e.g., AWS CloudWatch, Datadog, or an ELK stack). We will establish dashboards and alerts for key system metrics, including API endpoint latency, HTTP error rates (4xx/5xx), task queue depth, and worker service CPU/memory utilization.  
* **Backup & Recovery:** The PostgreSQL database will be configured with a robust backup strategy, leveraging the cloud provider's managed database service. This will include daily automated snapshots and point-in-time recovery (PITR) capabilities, allowing us to restore the database to any given minute within a retention period (e.g., 14 days).