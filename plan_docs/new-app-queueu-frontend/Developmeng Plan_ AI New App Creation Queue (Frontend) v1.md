# **Development Plan: AI New App Creation Queue (Orchestrator Frontend)**

## **Project: AI New App Creation Queue**

**Goal:** Implement a highly reliable, end-to-end automated workflow that transforms a Notion database entry into a fully configured GitHub repository and initiates the final project setup process.

**Target Environment:** Python 3.10+, Notion API, Gemini CLI, Node.js/Puppeteer, GitHub.

## **Phase 1: Project Foundation and Data Source (Notion)**

This phase establishes the secure Python environment and the robust monitoring system for the Notion database, ensuring reliable data ingress.

| Task ID | Task Description | Estimated Effort | Status | Notes |
| :---- | :---- | :---- | :---- | :---- |
| **1.1** | Project Setup & Dependencies: Create Python project structure (src/, config/, tests/) and install core libraries: notion-client, requests, subprocess, and python-dotenv. Set up initial virtual environment and package requirements file (requirements.txt). | 1.5 Days | To Do | **Security & Structure:** The project must enforce secure management of credentials using environment variables loaded via python-dotenv. Implement clear module separation, especially between the core orchestrator loop and the Notion interaction utility functions. |
| **1.2** | Notion Integration & Authentication: Configure the Notion Integration key and authorize it to access only the target database. Implement an initialization function that validates API connectivity upon startup. | 1 Day | To Do | **Credential Management:** Store the API Key (NOTION\_API\_KEY) and the Database ID (NOTION\_DATABASE\_ID) as encrypted secrets/environment variables. The initialization check should verify that the integration has the correct **read/write permissions** (specifically read access to page content and write access to the Status property). |
| **1.3** | **Notion Polling Loop (MVP):** Implement a persistent Python script (main\_orchestrator.py) using an infinite loop with a time.sleep(60) delay. The script must query the database for items where Status is exactly "New." | 2 Days | To Do | **Reliability & Queue Logic:** The loop must handle **Notion API rate limits** gracefully, implementing exponential backoff on HTTP 429 responses. The query should use timestamp filtering to ensure that only truly new or un-processed items are considered, and results should be sorted by creation time to process tickets in order. |
| **1.4** | Data Extraction Logic: Implement a function to reliably parse the Notion page object, extracting the main rich text content (as a clean, contiguous string for the LLM prompt) and the crucial Plan Docs Slug property value. | 1 Day | To Do | **Data Normalization:** The extraction must handle Notion's complex JSON structure for rich text blocks (including paragraphs, lists, and code blocks) and convert it into a simple, coherent Markdown string. The Plan Docs Slug must be sanitized (e.g., lowercased, hyphens instead of spaces) to ensure it's a valid GitHub repository and directory name. |
| **1.5** | Pre-Processing Update: Before passing an item to subsequent phases, immediately update the Notion page's status from "New" to "Processing" to lock the item in the queue and prevent multiple orchestrator instances from processing it simultaneously. | 0.5 Day | To Do | This is a critical queue locking mechanism. The update must be wrapped in its own dedicated error handler to ensure the Orchestrator doesn't crash if the update fails. |

## **Phase 2: Document Generation (Gemini CLI)**

This phase leverages the Gemini CLI to generate the first two complex, analytical documents directly from the Notion ticket data.

| Task ID | Task Description | Estimated Effort | Status | Notes |
| :---- | :---- | :---- | :---- | :---- |
| **2.1** | Gemini CLI Setup and Validation: Confirm the Gemini CLI is installed and globally available on the execution host. Create a validation script to ensure the CLI is authenticated and functional before the main polling loop begins. | 0.5 Day | To Do | The Python Orchestrator should dynamically check the PATH for the Gemini executable and fail gracefully if it's not found, providing a clear error message. |
| **2.2** | Architecture Document Generation: Write a Python module (doc\_generator.py) using subprocess.run() to execute the Gemini CLI. The command must embed a detailed **System Instruction** (e.g., "Act as a Senior Cloud Architect...") and pass the Notion content as the user prompt. | 1.5 Days | To Do | **Prompt Engineering:** Define a robust System Instruction that forces the output into a specific **Markdown structure** (e.g., H1 for title, mandatory sections like "Components," "Data Flow," "Security"). Use the Python tempfile library to securely manage and cleanup the generated architecture Markdown file. |
| **2.3** | Development Plan Generation: Replicate the module from 2.2 for the Development Plan. The System Instruction must shift persona (e.g., "Act as an Agile Project Manager...") and explicitly request a **tabular output** (Markdown tables) detailing tasks, effort estimates, and dependencies. | 1.5 Days | To Do | The output must be consistently formatted to simplify later consumption by the "AI New App Creation Template" Gem or the final CLI. Save the output to a second temporary file, ensuring file names are unique per item being processed. |
| **2.4** | Error Handling & Logging (Phase 2): Implement specific error handling within the document generation module. The code must check the returncode of the subprocess, capture any output from stderr, and raise a custom GenerationFailedError on failure. | 1 Day | To Do | **Failure Management:** Incorporate **retry logic** (e.g., 3 attempts with increasing delay) before permanently failing the Notion item. Log the full command used and the output that caused the failure to assist with debugging LLM prompting or API errors. |

## **Phase 3: Template Creation (Puppeteer Web Automation)**

This phase addresses the complex requirement of interfacing with the dedicated Gemini Web App Gem via headless browser automation, using Node.js/Puppeteer orchestrated by Python.

| Task ID | Task Description | Estimated Effort | Status | Notes |
| :---- | :---- | :---- | :---- | :---- |
| **3.1** | Puppeteer/Node.js Setup: Create a separate, lightweight Node.js module (web\_automator.js) that will encapsulate all web interaction logic. Define the communication interface (CLI arguments) it expects from the Python Orchestrator. | 1 Day | To Do | This Node module will be invoked as a **sub-process** by the Python script. Ensure Puppeteer dependencies (chrome/chromium) are correctly installed and configured for the host environment. |
| **3.2** | Web Automation Script (Login & Navigation): Implement the Node.js script to launch the headless browser. The script must securely handle the login session (e.g., via pre-loaded cookies or a dedicated token) and navigate directly to the "AI New App Creation" Gem interface. | 2 Days | To Do | **Stability:** Invest significant effort into making element selectors robust (avoiding volatile auto-generated IDs). The login process is the most fragile part and must be built to be reliable across sessions. |
| **3.3** | Template Generation Logic: Implement the core logic to read the content of Document 1 and Document 2 from disk, paste them into the Gem's input fields, initiate the generation process, and then wait for the final **Document 3 (Template)** output to appear. | 3 Days | To Do | **Asynchronous Management:** Use advanced Puppeteer features like page.waitForSelector() and page.waitForFunction() to wait for the AI response completion indicator, rather than using fixed time delays. Capture the final generated text and handle the subsequent text cleanup/extraction. |
| **3.4** | Python/Node.js Communication & Cleanup: Update the Python Orchestrator to call the Node.js script using subprocess.run(), passing paths to the two input files and a path for the output file (Document 3). | 1.5 Days | To Do | **Data Exchange:** The Node script should write the final Template content to the specified output file path. The Python script is then responsible for verifying the file creation, reading the content, and ensuring all temporary files created in this and previous phases are securely deleted immediately after use. |

## **Phase 4: Repository Setup and Final Orchestration**

This phase integrates the generated documents into version control and executes the final, critical project setup workflow.

| Task ID | Task Description | Estimated Effort | Status | Notes |
| :---- | :---- | :---- | :---- | :---- |
| **4.1** | **create-repo-from-slug Integration:** Integrate the custom CLI tool. The Python Orchestrator must construct the command to pass the slug, the **GitHub Template Repository ID**, and the local file paths of all three generated documents. | 1.5 Days | To Do | **Script Functionality:** This CLI must create a new repository (named using the sanitized slug) from the template, create a dedicated /docs folder, commit the Architecture Document, Development Plan, and AI Template, and return the new repository's URL. |
| **4.2** | **Project Setup Workflow Launch:** Write a final Python function that calls the "Project Setup Dynamic Workflow" CLI. This call signifies the handoff of the automated process to the execution environment. | 1.5 Days | To Do | **Argument Consistency:** Ensure that the final CLI call arguments are correctly formatted, potentially including the new **Repository URL**, the Plan Docs Slug, and any environment-specific variables needed for the final workflow execution. This call is the final, non-blocking step of the Python Orchestrator. |
| **4.3** | Notion Status Update: Implement the final status update logic. The Orchestrator must change the Notion ticket status to "Completed" (or a URL link to the new repo) upon the successful completion of all tasks up to Task 4.2. | 1 Day | To Do | **Failure/Success Mapping:** Define a clear error path: if any task from Phase 2, 3, or 4 fails, the status must be set to "ERROR" and a timestamped message containing the relevant error logs must be appended to a dedicated Notion property like "Error Notes" for immediate human intervention. |

## **Phase 5: Testing and Deployment**

This phase focuses on ensuring the reliability, performance, and operational sustainability of the automated system.

| Task ID | Task Description | Estimated Effort | Status | Notes |
| :---- | :---- | :---- | :---- | :---- |
| **5.1** | Unit Testing: Write comprehensive tests for every utility function, focusing heavily on **mocking**. This includes mocking Notion API responses, all subprocess calls (ensuring the Python script constructs the correct CLI commands), and the data parsing/normalization logic (Task 1.4). | 4 Days | To Do | **Test Coverage Goal:** Achieve a minimum of 90% test coverage for the Python orchestration logic to guarantee command formation integrity and error handling robustness. Use fixtures to represent realistic Notion API payloads. |
| **5.2** | End-to-End Testing (Staging): Run the full workflow in a dedicated, isolated staging environment. | 3 Days | To Do | **Critical Scenarios:** (1) **Success Path Validation:** Verify that all three documents are generated correctly, committed to the new repo, and the final CLI launches. (2) **Failure Resilience:** Introduce staged failures (e.g., force the Gemini CLI to return an error, simulate a Puppeteer timeout) and verify that the Notion item is marked "ERROR" and the Orchestrator recovers successfully for the next item. |
| **5.3** | Documentation Finalization: Update the Architecture Document and this Development Plan with any necessary lessons learned, revised estimates, and specific instructions for operational staff (the Runbook). | 1 Day | To Do | Create a separate *Runbook* detailing installation steps, environment variable configuration, common troubleshooting scenarios, and manual recovery procedures for "ERROR" state Notion tickets. |
| **5.4** | Deployment: Implement the production deployment strategy for the Python Orchestrator. | 2 Days | To Do | **Deployment Strategy:** Due to the large project size and scalability needs, containerize the Python Orchestrator using Docker. Deploy it as a **scheduled, highly-available job** (e.g., via Kubernetes CronJob, Cloud Run Scheduled Job, or a dedicated EC2 instance) to ensure continuous monitoring and processing without manual intervention. |

