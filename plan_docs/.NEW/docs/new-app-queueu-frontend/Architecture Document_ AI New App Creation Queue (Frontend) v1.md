# **Architecture Document: AI New App Creation Queue (Orchestrator Frontend)**

## **1\. Overview and Strategic Goal (Expanded)**

This document describes the architectural blueprint for the automated **AI New App Creation Queue**. The system's primary function is to transform a high-level project idea, submitted via a Notion database entry, into executable engineering artifacts and a fully initialized GitHub repository.

The architecture is built for **reliability and throughput**, addressing the need to handle a large volume of small to medium-sized projects without manual queue management.

### **Key Objectives:**

* **Zero-Touch Execution:** Achieve true *end-to-end* automation, eliminating all manual steps between Notion submission and the final workflow handoff.  
* **Standardized Artifacts:** Ensure that all generated documents (Architecture, Dev Plan, Template) adhere to predefined structural and content standards using constrained LLM output.  
* **High Availability (HA) Readiness:** Design the core Orchestrator logic to prevent concurrency issues and resource leaks, supporting future deployment as a containerized, highly-available service.

## **2\. System Components (Expanded Detail)**

The system utilizes a modular, microservice-like structure where each specialized component is invoked as a subprocess by the central Python Orchestrator.

| Component | Technology | Primary Role | Operational Notes & Dependencies |
| :---- | :---- | :---- | :---- |
| **A. Python Orchestrator** | **Python 3.10+** | **Core Execution & State Machine:** Manages the entire execution sequence. It controls the polling loop, handles all inter-component data exchange (file paths/contents), manages temporary file creation/cleanup, and implements comprehensive error logging and retry logic. | **Crucial Libraries:** notion-client (for B), subprocess (for C, E, F), os/tempfile (for resource management), and python-dotenv (for secure credential loading). |
| **B. Data Source** | **Notion API** | **Input Queue & Status Registry:** Provides the initial content for the AI prompts and serves as the **central state management system** for the queue. | **Required Filters:** Must support complex querying (e.g., status: "New", sorted by created\_time for FIFO processing). **Concurrency Lock:** Responsible for the atomic New  Processing status update. |
| **C. Document Generator** | **Gemini CLI** | **LLM Artifact Creation:** Generates Document 1 (Architecture) and Document 2 (Development Plan). Each call must utilize a distinct, highly constrained **System Instruction** to enforce structure (Markdown tables, specific section headings) and professional persona. | **I/O:** Takes raw Notion content as a prompt input. Outputs structured Markdown files to a secure temporary directory. **Reliability:** Requires strict validation of the subprocess exit code and output content. |
| **D. Template Generator** | **Puppeteer (Node.js)** | **Web Automation Bridge:** A critical component that enables interaction with the proprietary **Gemini Web App Gem**. It is encapsulated in a Node.js module that takes file paths as input and simulates browser actions. | **Fragility Point:** This is the most brittle component. Requires resilient element selectors, explicit page.waitForSelector calls instead of timed delays, and guaranteed closure of the headless browser instance, even upon error. |
| **E. Repository Manager** | **create-repo-from-slug CLI** | **Version Control Setup:** A custom script that interfaces with the GitHub API. It handles the creation of a new repository from a predefined template (to inherit .gitignore, basic CI/CD, etc.) and performs the initial commit of the three generated documents into a /docs folder. | **Authentication:** Requires a dedicated, scoped GitHub Personal Access Token (PAT) for repo creation and commit actions. **Input:** Requires the sanitized Plan Docs Slug, the three document file paths, and the source template URI. |
| **F. Final Workflow** | **Custom CLI/Agent** | **Final Handoff/Trigger:** The last step where the complete package (Repository URI \+ 3 Documents) is passed to a powerful, subsequent system (the "Project Setup Dynamic Workflow") to begin actual codebase generation or infrastructure provisioning. | **Decoupling:** Must be invoked via a non-blocking subprocess call; the Orchestrator should not wait for this final workflow to complete. |

## **3\. Data Flow and Execution Sequence (Deep Dive)**

The workflow is a linear pipeline of six stages, with strict sequential dependencies enforced by the Python Orchestrator (A).

1. **Polling and Item Lock (A  B):**  
   * (A) queries (B) using the filter status: "New".  
   * **Concurrency Control:** Upon retrieving a new item, (A) immediately issues an updatePage request to set the status to **"Processing"**. If this update fails (e.g., due to a conflict from another running Orchestrator instance), (A) must gracefully abandon the item and return to the polling loop.  
   * **Data Extraction:** (A) performs **schema validation** on the Notion page properties (ensuring Plan Docs Slug and content fields exist) and sanitizes the slug (e.g., converting "My New Project" to "my-new-project" for the repository name).  
2. **Initial Document Generation (A  C):**  
   * (A) uses subprocess.run() to execute the Gemini CLI (C). The contents of the Notion ticket are passed via standard input or as a file path.  
   * **Architecture Document (Doc 1):** The System Instruction mandates a focus on technology stacks, component diagrams, and non-functional requirements (Security, Performance). The output is saved to a secure temporary file.  
   * **Development Plan (Doc 2):** The System Instruction mandates a focus on **Agile methodology**, requiring a table format for a 3-sprint plan with estimated effort (e.g., T-shirt sizes or story points). The output is saved to a second secure temporary file.  
3. **Template Generation via Automation (A  D):**  
   * This is the most complex step. (A) prepares input files and executes the **Node.js/Puppeteer script (D)**.  
   * (D) launches a Chrome/Chromium instance. It reads Doc 1 and Doc 2, pastes their contents into the specified input elements of the "AI New App Creation" Gem interface, triggers generation, and waits for the final output element to populate.  
   * **I/O Handlers:** (D) is designed to write the final generated text (Document 3\) into a designated output file (/tmp/template\_output.json), which (A) then reads back into memory. This file-based communication minimizes risk compared to pipe-based stdout communication.  
4. **Repository Setup and Commit (A  E):**  
   * (A) constructs a single, complex subprocess call to the create-repo-from-slug CLI (E).  
   * **Atomic Operation:** (E) uses the GitHub API to perform the following steps **atomically** (ideally within one transaction or process): Create repository, clone it, create /docs folder, add Doc 1, Doc 2, and Doc 3, commit, and push.  
   * **Result Handoff:** (E) must return the new, canonical **GitHub URI** (e.g., https://github.com/org/my-new-project) via its standard output, which (A) captures for the final status update.  
5. **Orchestration Launch (A  F):**  
   * (A) executes the final, decoupled **"Project Setup Dynamic Workflow" CLI (F)**. This call uses the captured GitHub URI as the primary input.  
   * **Decoupling:** Because this is a long-running process, (A) must **not** wait for its completion. The orchestrator's success relies only on the successful *initiation* of (F).  
6. **Status Update (A  B):**  
   * Upon successful execution of all previous steps, (A) updates the Notion item to **"Completed"** and links the captured GitHub URI to a dedicated URL property on the Notion page.

## **4\. Scalability, Reliability, and Resource Management (Critical Focus)**

### **4.1. Reliability and Error Recovery**

* **Checkpointing and Rollback:** While a full database rollback is too complex, the **Notion Status Field (B)** serves as the primary checkpoint. Any failure in Phases 2 through 5 must result in the status being set to **"ERROR"** and an appended error trace (including the subprocess command and output) being written back to Notion for human review.  
* **Retry Logic:** Transient errors (network issues, LLM API temporary downtime) must be managed using **exponential backoff**. The Orchestrator should attempt a task up to three times before declaring a final, terminal failure and setting the status to "ERROR."  
* **Input Robustness:** The data extraction logic (Phase 1\) must guard against malformed input, ensuring the LLM prompts are always clean text and the Plan Docs Slug is always safe for file naming, potentially defaulting to a UUID if the slug field is missing.

### **4.2. Resource and Process Management**

* **Temporary File Lifecycle:** The Orchestrator (A) holds complete responsibility for **garbage collection**. All temporary files created in Phases 2 and 3 must be deleted within the same processing cycle, using Python's try...finally blocks to ensure deletion even if errors occur.  
* **Puppeteer Process Control (D):** Since Puppeteer spawns a full Chromium instance, it is a significant resource sink. The Python subprocess call for (D) must utilize specific flags or a custom shell command to ensure that the headless browser process is **completely terminated** when the Python script's subprocess call exits or times out. This is vital to prevent memory and CPU exhaustion over time.

### **4.3. Document Standards**

The final Template (Document 3\) is the handoff artifact to the final workflow (F). It **MUST** be structured and validated:

* **Format:** JSON or YAML is preferred over pure Markdown.  
* **Validation:** The Orchestrator (A) must include basic Python logic to validate that the output from Puppeteer (D) is syntactically valid JSON/YAML before proceeding to the Repository Setup (E). This prevents downstream errors in the final workflow (F).

## **5\. Deployment Considerations**

The entire Python Orchestrator (A) and its subprocess dependencies (C, D, E) should be packaged into a **Docker container**. This ensures a consistent, isolated environment for all components (Node, Python, CLIs), which is essential for stable, high-volume operation. The container can then be deployed to a scalable platform like **Kubernetes (CronJob)** or **Google Cloud Run** for resilient, continuous execution.