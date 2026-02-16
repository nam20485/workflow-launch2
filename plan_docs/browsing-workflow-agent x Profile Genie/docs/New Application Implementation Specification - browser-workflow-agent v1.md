# **New Application Implementation Specification**

## **App Title**

**Agno "Mimic" Agent**

## **Description**

The Agno "Mimic" Agent represents a paradigm shift in browser automation, functioning as a sophisticated builder for "Large Action Models" (LAMs). Unlike traditional automation tools that rely on brittle selectors or rigid code, Mimic operates as a closed-loop, neuro-symbolic system. It passively observes human interaction within a web browser, translates those raw, unstructured events into semantic, generalized workflows ("Modes"), empowers users to refine these workflows through a natural language interface, and ultimately executes them autonomously using an AI-managed browser instance. This system bridges the gap between human intent and machine execution by treating browser actions as a learnable language rather than a sequence of coordinate clicks.

## **Overview**

The core philosophy of the Agno Mimic Agent is "Show, Don't Code." It democratizes automation by allowing non-technical users to demonstrate a task—such as "Apply to a job on LinkedIn" or "Scrape leads from Apollo"—which the system then internalizes as a reusable skill.

To achieve this, the architecture is composed of four distinct, loosely coupled engines, each responsible for a specific stage of the automation lifecycle:

1. **The Watcher (Ingestion Engine):** A highly efficient, local Python service that attaches to a running Chrome instance. It listens to the Chrome DevTools Protocol (CDP) to capture high-fidelity signals, specifically focusing on Accessibility Tree (AXTree) snapshots rather than just the DOM. This ensures that the "meaning" of an element (e.g., "Submit Button") is captured even if its visual styling changes.  
2. **The Compiler (Synthesis Engine):** Acting as the system's "Brain," this engine utilizes an Agno Agent powered by a Large Language Model (LLM). It ingests the chronological stream of raw events, filters out noise, and synthesizes them into structured, logical steps. It is responsible for identifying patterns, deduplicating redundant actions, and extracting variables (e.g., recognizing that "John Doe" is a {{user\_name}}).  
3. **The Refiner (Verification Engine):** A Streamlit-based user interface that keeps the human in the loop. It presents the synthesized "Mode" in a split-view format: a chat interface for natural language adjustments and a live JSON viewer for technical inspection. This engine ensures that PII is managed correctly and that the agent's logic aligns with the user's intent before deployment.  
4. **The Executor (Orchestration Engine):** The runtime component that performs the actual automation. It utilizes a NanoBrowser instance for anti-detect capabilities and employs "Semantic Targeting." Instead of looking for a button with id="btn-123", it generates vector embeddings for the page's elements and searches for the element that *semantically matches* the original recording, ensuring resilience against UI updates.

## **Document Links**

* docs/comprehensive\_architecture.md \- High-Level Topology & Data Schemas  
* docs/detailed\_dev\_plan.md \- Phased Implementation Steps  
* docs/research\_notes.md \- Technical Feasibility & Competitive Analysis

## **Requirements**

### **Functional Requirements**

* **Passive & Non-Intrusive Observation:**  
  The system must connect to an existing Chrome instance via the Chrome DevTools Protocol (CDP) on port 9222\. Crucially, this connection must be "passive," meaning it uses WebSocket listeners to observe Page, DOM, and Input domains without injecting JavaScript shims or slowing down the renderer process.  
* **Intelligent Noise Filtering & Buffering:**  
  Raw user input is noisy. The system must implement robust debouncing and aggregation logic. High-frequency events like mouse\_moved, scroll, or touch\_move must be discarded at the source to prevent database bloat. Conversely, key\_down events must be buffered and aggregated into coherent string literals (e.g., capturing "Hello" as a single event rather than five separate H-e-l-l-o keystrokes).  
* **Semantic Context Capture (AXTree):**  
  For every "Commit" event (Click, Submit, Keypress), the system must snapshot the Accessibility Tree (AXTree) and computed ARIA attributes. This is preferred over the raw DOM because the AXTree represents the *semantic* structure of the page (buttons, links, form fields) as perceived by assistive technologies, which provides a more stable target for AI models than messy HTML soup.  
* **Automatic Semantic Generalization:**  
  The Compiler engine must possess the intelligence to distinguish between static structure and dynamic data. It must automatically detect potential variables—such as names, dates, locations, and search terms—and convert them into template placeholders (e.g., replacing "San Francisco" with {{search\_location}}). This turns a one-off recording into a flexible template.  
* **Resilient Vector-Based Replay:**  
  The Executor must abandon legacy selectors (XPath/CSS) in favor of vector similarity. During execution, it must embed the current page's interactive elements and use cosine similarity to locate the target. If the "Save" button moves from the bottom right to the top left but retains its semantic meaning, the agent must still find it.

### **Non-Functional Requirements**

* **Latency & Performance:**  
  Event processing must be strictly non-blocking. The Watcher's event loop must process and dispatch events in under 50ms per tick to ensure no lag is perceived by the user. Heavy lifting (parsing, embedding) should be offloaded to background workers.  
* **Privacy & Compliance:**  
  Privacy is paramount. The system must include a PII (Personally Identifiable Information) detection layer. Before any "Mode" is finalized or saved to a shared library, entities like credit card numbers, passwords, and emails must be flagged and optionally redacted or hashed.  
* **Scalability & Storage:**  
  The database architecture must utilize pgvector efficiently. It needs to support the storage of thousands of DOM element embeddings. Indexes (specifically HNSW \- Hierarchical Navigable Small World graphs) must be configured to ensure that vector search queries return in sub-millisecond times even as the dataset grows.  
* **Code Quality & Maintainability:**  
  The codebase will adhere to strict modern Python standards. Type safety will be enforced via basedpyright, and code style will be maintained by ruff. The project will use uv for deterministic dependency management and virtual environment handling.

## **Features**

1. **CDP Event Listener ("The Watcher")**  
   * **Architecture:** Asyncio-based WebSocket client connecting to 127.0.0.1:9222.  
   * **Keystroke Aggregation:** Implements a "sliding window" buffer that commits text only when the user pauses typing for \>500ms or clicks a new element.  
   * **Snapshotting:** Triggers DOM.getFlattenedDocument and AXTree.snapshot commands specifically on click and submit events to associate the user's action with the visual state of the UI at that exact moment.  
2. **Mode Synthesis Engine ("The Brain")**  
   * **LLM Integration:** Utilizes an Agno Agent configured with specialized system prompts designed for intent recognition and web automation logic.  
   * **Session Segmentation:** Uses heuristics (e.g., long periods of inactivity, navigation to a "dashboard" URL) to automatically suggest start and end points for a logical task.  
   * **Variable Extraction:** Combines Regex patterns (for emails, dates) with LLM inference to identify context-specific variables (e.g., "The user typed 'Manager' in the 'Job Title' field; create variable {{job\_title}}").  
3. **Interactive Refiner UI**  
   * **Dual-View Interface:** A Streamlit application featuring a "Chat" column for natural language interaction and a "Code" column for reviewing the generated JSON structure.  
   * **Diff Visualization:** Visual indicators showing exactly what changed in the workflow after a user request (e.g., highlighting a removed step in red).  
   * **Safety Controls:** Granular toggles allowing users to mark specific steps as "Human Confirmation Required," forcing the automated runner to pause and ask for permission before proceeding (critical for "Submit Application" or "Transfer Funds" actions).  
4. **Semantic Executor ("The Hand")**  
   * **NanoBrowser Core:** Wraps the NanoBrowser implementation to ensure the automated browser fingerprint looks identical to a standard user, bypassing bot detection systems (WAFs).  
   * **Dynamic Vector Search:** At runtime, the executor embeds the visible interactable elements on the page and queries the local vector store to find the "Nearest Neighbor" to the recorded element.  
   * **Self-Healing Logic:** If a primary interaction fails (e.g., element intercepted), the system enters a retry loop, attempting to scroll, wait, or find the next best semantic match before throwing an error.

## **Known Limitations & Constraints**

To manage expectations and scope, the following scenarios are explicitly **out of scope** for the initial release:

* **CAPTCHA Solving:** The agent will pause and request human intervention if a CAPTCHA is detected; it will not attempt to solve it automatically.  
* **2FA/MFA Handling:** Multi-factor authentication steps must be performed manually by the user or disabled in the target environment.  
* **Canvas-Based UIs:** Applications that do not expose a standard DOM or Accessibility Tree (e.g., Figma, Google Sheets cells, heavily obfuscated games) are not supported.  
* **Browser Extensions:** The Watcher cannot record interactions inside other browser extensions' popups (due to CDP limitations).

## **Development Plan**

### **Phase 1: The Eye (Ingestion Infrastructure)**

**Objective:** Establish the foundation for reliable, passive data capture from Chrome. This phase focuses on the "plumbing"—getting data out of the browser and into the database without data loss or corruption.

* **Detailed Tasks:**  
  1. **Project Initialization:** Set up the repository using uv init. Configure ruff.toml for strict linting rules and pyrightconfig.json for type checking. Establish the directory structure.  
  2. **Containerized Data Layer:** Author a docker-compose.yml that provisions Postgres 16\. Install and enable the vector extension (CREATE EXTENSION vector;). Configure persistent volumes to ensure data survives container restarts.  
  3. **Schema Definition:** Use SQLAlchemy to define the core models:  
     * Session: Tracks the metadata of a recording session (start time, user ID).  
     * RawEvent: A time-series log of every raw CDP event.  
     * DOMSnapshot: Stores the massive JSON dumps of the AXTree, linked to specific events.  
  4. **CDP Client Implementation:** Develop the Watcher class. This must handle WebSocket framing, connection keep-alives, and graceful reconnections if the browser is closed.  
  5. **Event Loop & Dispatcher:** Implement a high-performance asyncio loop that ingests messages from Page.on('console'), DOM.documentUpdated, and input domains. Dispatch these to a background write buffer to avoid blocking the socket.  
  6. **Heuristic Filtering:** Implement the logic to strictly ignore mouse\_move, touch\_move, and hover events. Implement the state machine for debouncing key\_down into coherent input\_entry events.  
* **Phase 1 Acceptance Criteria:**  
  * **![][image1]**Executing python start\_watcher.py instantly detects and connects to the debuggable Chrome instance.  
  * ![][image1]Clicking a button on a complex SPA (Single Page App) results in a new row in raw\_events within 100ms.  
  * ![][image1]Rapidly typing "Hello World" generates a single, aggregated event row, not 11 separate keystroke rows.  
  * ![][image1]Aggressively scrolling a news feed generates **zero** database noise.  
  * ![][image1]The DOMSnapshot table successfully stores valid, queryable JSONB data representing the accessibility tree for every click.

### **Phase 2: The Brain (Compiler Logic)**

**Objective:** Transform raw, noisy logs into clean, parameterized JSON workflows. This phase is about turning "data" into "information" using the Agno Agent.

* **Detailed Tasks:**  
  1. **Agno Agent Configuration:** Initialize the AnalystAgent. Craft the system prompt to include few-shot examples of mapping raw CDP events to semantic JSON steps.  
  2. **Pydantic Modeling:** Define strict Pydantic models for the output schema: Mode, Step, Action (Click, Type, Wait, Navigate), and Variable. This ensures the LLM outputs structured data we can validate.  
  3. **Log Processing Pipeline:** Create a data pipeline that fetches RawEvents for a given session\_id, formats them into a compact text representation (to save context window tokens), and feeds them to the LLM.  
  4. **Smart Variable Detection:** Implement a hybrid approach: strict Regex for obvious patterns (emails, phone numbers, zip codes) and LLM inference for contextual variables (e.g., distinguishing a "Search Query" from a "Username").  
  5. **PII Guardrails:** Integrate a pre-processing scrubber. Before the prompt reaches the LLM, scan for and mask high-entropy strings that look like passwords or API keys.  
* **Phase 2 Acceptance Criteria:**  
  * **![][image1]**The Compiler accepts a raw log of 50 events and successfully synthesizes a single, valid Mode JSON object.  
  * ![][image1]A raw sequence of "Click Field" \-\> "Type 'New York'" \-\> "Click Submit" is correctly condensed into one Step with a {{search\_query}} parameter.  
  * ![][image1]The system automatically suggests the variable name user\_email if the user interacts with an input having aria-label="Email Address".  
  * ![][image1]Any detected passwords are strictly replaced with {{SECRET\_PASSWORD}} and never stored in plain text in the Mode.

### **Phase 3: The Refiner (User Interface)**

**Objective:** Provide a seamless experience for users to review, edit, and operationalize the recorded workflows. This is the "Human-in-the-Loop" control center.

* **Detailed Tasks:**  
  1. **Streamlit Foundation:** Initialize the Streamlit app with a sidebar for session history and a main area for the workspace.  
  2. **Interactive Mode Viewer:** Develop a custom component to render the Mode JSON in a readable, collapsible tree format.  
  3. **Chat-to-JSON Pipeline:** Build the logic where user chat input ("Remove the second step") is sent to the Agno Agent along with the current JSON, and the Agent returns the *modified* JSON.  
  4. **State Management:** Implement session state handling to track "Unsaved Changes," allowing users to undo/redo edits before committing.  
  5. **Parameter Form Generator:** Create a dynamic UI builder that reads the Variable list from the Mode and automatically generates the corresponding HTML input fields for testing.  
* **Phase 3 Acceptance Criteria:**  
  * **![][image1]**Users can browse a list of recorded sessions and load them into the editor.  
  * ![][image1]Typing "Change the delay on step 3 to 5 seconds" results in the JSON updating instantly to reflect delay: 5000\.  
  * ![][image1]The UI visualizes validation errors (e.g., missing required fields) with a warning badge.  
  * ![][image1]Clicking "Save" validates the schema one last time and persists the Mode to the production\_modes table.

### **Phase 4: The Hand (Execution Engine)**

**Objective:** Enable the autonomous replay of workflows using semantic understanding. This is where the "Large Action Model" comes to life.

* **Detailed Tasks:**  
  1. **NanoBrowser Wrapper:** Create a robust Python wrapper around the NanoBrowser/Playwright API to manage browser context, proxy settings, and anti-detect headers.  
  2. **Runtime Embedding Pipeline:** Implement FastEmbed within the execution loop. On every page load, the agent must serialize the DOM and generate embeddings for interactable elements in real-time.  
  3. **Vector Search Logic:** Write the algorithm to query pgvector. It needs to compare the *recorded* element's vector against the *current* page's vectors and return the match with the highest cosine similarity.  
  4. **State Machine Executor:** Build the main execution loop that iterates through Mode.steps. It must handle preconditions (Wait For Selector), Actions (Click/Type), and Postconditions (Verify URL changed).  
  5. **Error Recovery & Retries:** Implement standard resiliency patterns: exponential backoff for network timeouts, and "fuzzy matching" fallbacks if the primary vector match score is too low.  
* **Phase 4 Acceptance Criteria:**  
  * **![][image1]**The Agent can successfully execute a full "Login" workflow on a local test environment.  
  * ![][image1]**Crucial:** The Agent successfully clicks a targeted button even if its id and class attributes have been completely randomized, relying solely on semantic similarity (\>0.85).  
  * ![][image1]The system throws a clear, descriptive error exception if a required element is inextricably missing from the DOM.  
  * ![][image1]Comprehensive execution logs, including screenshots of every step and success/failure states, are saved to the database.

## **Testing Strategy**

### **Unit Testing**

* **Framework:** pytest  
* **Scope:**  
  * **Filtering Logic:** Verify that high-frequency noise is mathematically eliminated.  
  * **Schema Validation:** Test Pydantic models against malformed data to ensure robustness.  
  * **Regex Patterns:** Ensure variable substitution logic correctly identifies varied formats of emails and dates.  
  * **Redaction:** Verify that PII redaction functions return masked strings for known patterns.

### **Integration Testing**

* **Frameworks:** pytest-asyncio, testcontainers (for ephemeral Postgres instances).  
* **Scope:**  
  * **Database Integrity:** Verify CRUD operations for complex nested JSONB and Vector data types.  
  * **CDP Handshake:** Use a mock WebSocket server to simulate Chrome's CDP responses and verify the Watcher's connection handling.  
  * **Vector Search:** Insert known vectors and verify that the nearest neighbor query returns the mathematically correct result.

### **End-to-End (E2E) Testing**

* **Framework:** Playwright (Headless Mode)  
* **Scope:**  
  * **The Full Loop:** Record a dummy action \-\> Compile it \-\> Refine it \-\> Execute it.  
  * **Side Effects:** Verify that the execution actually changed the state of the target application (e.g., a form was submitted, a record was created).

## **CI/CD Plan**

### **Workflow Triggers**

* **Push:** Triggered on any commit to main.  
* **Pull Request:** Triggered on opening or updating any PR targeting main.

### **Pipeline Steps (GitHub Actions)**

1. **Environment Setup:** Checkout the repository and install uv.  
2. **Dependency Resolution:** Run uv sync \--frozen to install the exact dependencies defined in the lockfile, ensuring a reproducible build.  
3. **Linting & Formatting:**  
   * Run uv run ruff check . to enforce coding standards (fails on violations).  
   * Run uv run ruff format \--check . to verify formatting compliance.  
4. **Static Type Analysis:**  
   * Run uv run basedpyright . to perform strict type checking, catching potential runtime errors early.  
5. **Test Execution:**  
   * Run uv run pytest tests/unit for fast feedback.  
   * Run uv run pytest tests/integration to verify system cohesion.  
6. **Artifact Construction (Release Only):**  
   * On tagged commits, build the Docker image.  
   * Push the image to the container registry (GHCR or Docker Hub).

## **Containerization: Docker**

* **Services Strategy:**  
  * **Database (db):** Uses the official Postgres 16 image.  
  * **Application (app):** Python 3.11 environment optimized for async I/O.  
* **Persistence:** Uses a named Docker volume pgdata to ensure database persistence across container recreations.

## **Containerization: Docker Compose**

version: '3.8'  
services:  
  db:  
    image: ankane/pgvector:v0.5.1 \# Pin version for production stability  
    environment:  
      POSTGRES\_USER: agno  
      POSTGRES\_PASSWORD: securepassword  
      POSTGRES\_DB: mimic\_db  
    ports:  
      \- "5432:5432"  
    volumes:  
      \- pgdata:/var/lib/postgresql/data  
    healthcheck:  
      test: \["CMD-SHELL", "pg\_isready \-U agno \-d mimic\_db"\]  
      interval: 5s  
      timeout: 5s  
      retries: 5

  watcher:  
    build:   
      context: .  
      dockerfile: Dockerfile  
    network\_mode: "host"   
    depends\_on:  
      db:  
        condition: service\_healthy  
    environment:  
      DB\_URL: postgresql://agno:securepassword@localhost:5432/mimic\_db  
    \# 'host' network mode is critical for connecting to the local Chrome instance on port 9222

## **Swagger/OpenAPI**

* **API Strategy:**  
  While Mimic is primarily a local desktop tool, the Executor engine will expose a lightweight local REST API. This allows the Streamlit UI (and potentially external schedulers) to trigger job runs programmatically.  
* **Core Endpoints:**  
  * GET /modes: Retrieve a list of all compiled, production-ready workflows.  
  * POST /modes/{id}/execute: Trigger an immediate execution of a specific Mode. Accepts a JSON body with override variables.  
  * GET /session/{id}/logs: Retrieve the raw event logs for a specific session for debugging or re-compilation.  
  * GET /status: Health check endpoint returning the status of the browser connection.

## **Documentation**

* **Readme.md:** Comprehensive setup instructions, covering uv sync, docker-compose up, and browser configuration.  
* **Architecture Decision Record (ADR):** A detailed log explaining critical technical choices, specifically focusing on "Why AXTree was chosen over DOM" (context window optimization and semantic stability).  
* **User Guide:** "How to Record a Robust Workflow" – A guide for end-users on best practices (e.g., "Click slowly," "Wait for page loads") to ensure high-quality recordings.

## **Language**

**Python**

## **Language Version**

**3.11+** (Strictly required to support advanced type hinting, asyncio TaskGroups, and performance improvements).

## **Frameworks, Tools, Packages**

* **Package Management:** uv (Selected for its superior speed in resolution and installation compared to Poetry/Pip).  
* **Linting/Formatting:** ruff (Chosen for its unified, high-performance toolchain).  
* **Type Checking:** basedpyright (or pyright) for strict static analysis.  
* **Core Logic:** Agno (Agent Framework) and Pydantic (Data Validation and Schema definition).  
* **Browser Control:** Playwright (Async API for robust automation) and Chrome DevTools Protocol (CDP) (For low-level event listening).  
* **Web/UI:** Streamlit (Rapid development of the Refiner Interface).  
* **Database:** SQLAlchemy (ORM), pgvector (Vector Search Extension), and AsyncPG (High-performance async driver).  
* **AI/Embeddings:** OpenAI API (LLM Inference) and FastEmbed (Efficient local embedding generation for vector search).

## **Project Structure / Package System**

* **System:** uv handles the virtual environment and pyproject.toml.  
* **Repository Structure:**  
  /src  
    /mimic  
      /watcher    \# CDP Listener & Event filtering logic  
      /compiler   \# Agno Agent & Prompt definitions  
      /executor   \# NanoBrowser Control & Vector Search  
      /ui         \# Streamlit Interface components  
      /db         \# SQLAlchemy Models, Migrations & Connection logic  
  /tests  
    /unit         \# Isolated logic tests  
    /integration  \# DB & Component interaction tests  
    /e2e          \# Full automation loop tests  
  /scripts        \# Startup, cleanup, and utility scripts  
  pyproject.toml  \# Project metadata, dependencies, and tool config  
  ruff.toml       \# Linter configuration  
  docker-compose.yml \# Infrastructure definition

## **GitHub**

* **Repo:** https://www.google.com/search?q=https://github.com/intel-agency/mimic-agent  
* **Branch:** main

## **Deliverables**

1. **Source Code:** A fully functional, strictly typed Python package managed by uv.  
2. **Docker Environment:** A "One-click" docker-compose setup that provisions the vector database and verified connectivity.  
3. **CI/CD Pipeline:** A complete .github/workflows/ci.yml ensuring code quality and test coverage on every push.  
4. **Demo Mode:** A pre-recorded, verified "LinkedIn Job Search" mode injected into the database seed, allowing users to test execution immediately after installation.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAmwAAAAUCAYAAAAwe2GgAAAAR0lEQVR4Xu3BMQEAAADCoPVPbQlPoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP4GwdQAAZuLbQIAAAAASUVORK5CYII=>