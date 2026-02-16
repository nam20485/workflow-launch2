# **New Application Implementation Specification**

## **App Title**

**Agno "Mimic" Agent**

## **Description**

The Agno "Mimic" Agent represents a paradigm shift in browser automation, functioning as a sophisticated builder for "Large Action Models" (LAMs). Unlike traditional automation tools that rely on brittle selectors or rigid code, Mimic operates as a closed-loop, neuro-symbolic system. It passively observes human interaction within a web browser, translates those raw, unstructured events into semantic, generalized workflows ("Modes"), empowers users to refine these workflows through a natural language interface, and ultimately executes them autonomously using an AI-managed browser instance. This system bridges the gap between human intent and machine execution by treating browser actions as a learnable language rather than a sequence of coordinate clicks.

## **Overview**

The core philosophy of the Agno Mimic Agent is "Show, Don't Code." It democratizes automation by allowing non-technical users to demonstrate a task—such as "Apply to a job on LinkedIn" or "Scrape leads from Apollo"—which the system then internalizes as a reusable skill.

To achieve this, the architecture is composed of five distinct, loosely coupled engines:

1. **The Watcher (Ingestion Engine):** A highly efficient, local Python service that attaches to a running Chrome instance. It listens to the Chrome DevTools Protocol (CDP) to capture high-fidelity signals, specifically focusing on Accessibility Tree (AXTree) snapshots rather than just the DOM. This ensures that the "meaning" of an element (e.g., "Submit Button") is captured even if its visual styling changes.  
2. **The Compiler (Synthesis Engine):** Acting as the system's "Brain," this engine utilizes an Agno Agent powered by a Large Language Model (LLM). It ingests the chronological stream of raw events, filters out noise, and synthesizes them into structured, logical steps. It is responsible for identifying patterns, deduplicating redundant actions, and extracting variables (e.g., recognizing that "John Doe" is a {{user\_name}}).  
3. **The Refiner (Verification Engine):** A Streamlit-based user interface that keeps the human in the loop. It presents the synthesized "Mode" in a split-view format: a chat interface for natural language adjustments and a live JSON viewer for technical inspection. This engine ensures that PII is managed correctly and that the agent's logic aligns with the user's intent before deployment.  
4. **The Personal Data Vault (Context Engine):** A dedicated, persistent database store for user secrets and profile information (e.g., Phone Number, Address, API Keys). Instead of hardcoding values into scripts or typing them every time, the system stores them securely in the DB and retrieves them dynamically during execution.  
5. **The Executor (Orchestration Engine):** The runtime component that performs the actual automation. It utilizes a NanoBrowser instance for anti-detect capabilities and employs "Semantic Targeting." Instead of looking for a button with id="btn-123", it generates vector embeddings for the page's elements and searches for the element that *semantically matches* the original recording, ensuring resilience against UI updates.

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
* **Persistent User Context (Data Vault):**  
  The system must provide a mechanism to store personal user data (key-value pairs) in a persistent database table. The Compiler and Executor must be able to reference these keys (e.g., {{phone\_number}}) to automatically fill form fields during playback without user intervention.  
* **Resilient Vector-Based Replay:**  
  The Executor must abandon legacy selectors (XPath/CSS) in favor of vector similarity. During execution, it must embed the current page's interactive elements and use cosine similarity to locate the target. If the "Save" button moves from the bottom right to the top left but retains its semantic meaning, the agent must still find it.

### **Non-Functional Requirements**

* **Latency & Performance:**  
  Event processing must be strictly non-blocking. The Watcher's event loop must process and dispatch events in under 50ms per tick to ensure no lag is perceived by the user. Heavy lifting (parsing, embedding) should be offloaded to background workers.  
* **Privacy & Security:**  
  User data stored in the Personal Data Vault is persisted in the local Postgres database. While the initial implementation assumes a single-user environment (relying on database access controls), the schema must support future multi-user isolation via Row-Level Security (RLS) without major refactoring.  
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
   * **Variable Extraction:** Combines Regex patterns (for emails, dates) with LLM inference to identify context-specific variables (e.g., "The user typed 'Manager' in the 'Job Title' field; create variable {{job\_title}}").  
3. **Personal Data Vault**  
   * **Persistent Storage:** A simple, robust storage mechanism for user attributes (key-value pairs) within Postgres.  
   * **Context Injection:** Automatically injects stored values into the Executor runtime, matching variable names to keys in the vault (e.g., variable user\_email \-\> vault key email).  
   * **Management UI:** A dedicated section in the Refiner App to add, edit, or delete personal data fields.  
4. **Interactive Refiner UI**  
   * **Dual-View Interface:** A Streamlit application featuring a "Chat" column for natural language interaction and a "Code" column for reviewing the generated JSON structure.  
   * **Identity Manager:** A form-based UI to manage the Personal Data Vault.  
5. **Semantic Executor ("The Hand")**  
   * **NanoBrowser Core:** Wraps the NanoBrowser implementation to ensure the automated browser fingerprint looks identical to a standard user, bypassing bot detection systems (WAFs).  
   * **Dynamic Vector Search:** At runtime, the executor embeds the visible interactable elements on the page and queries the local vector store to find the "Nearest Neighbor" to the recorded element.

## **Known Limitations & Constraints**

To manage expectations and scope, the following scenarios are explicitly **out of scope** for the initial release:

* **CAPTCHA Solving:** The agent will pause and request human intervention if a CAPTCHA is detected.  
* **Complex Multi-User Auth:** The initial release assumes a single-user environment. Database security relies on standard Postgres access controls. Future iterations can implement Row-Level Security (RLS) for multi-tenant isolation.  
* **Canvas-Based UIs:** Applications that do not expose a standard DOM or Accessibility Tree are not supported.

## **Development Plan**

### **Phase 1: The Eye (Ingestion Infrastructure)**

**Objective:** Establish the foundation for reliable, passive data capture from Chrome.

* **Detailed Tasks:**  
  1. **Project Initialization:** Set up the repository using uv init. Configure ruff.toml and pyrightconfig.json.  
  2. **Containerized Data Layer:** Author a docker-compose.yml for Postgres 16 \+ pgvector.  
  3. **Schema Definition:** Use SQLAlchemy to define core models:  
     * Session: Tracks recording metadata.  
     * RawEvent: Time-series log of CDP events.  
     * DOMSnapshot: Stores AXTree dumps.  
     * **NEW:** UserContext: Table for personal data (key \[String\], value \[Text\], description \[String\]).  
  4. **CDP Client Implementation:** Develop the Watcher class.  
  5. **Event Loop:** Implement high-performance asyncio loop for event ingestion.  
* **Phase 1 Acceptance Criteria:**  
  * **![][image1]**python start\_watcher.py connects to Chrome.  
  * ![][image1]UserContext table exists in the database and can accept inserts via SQL.  
  * ![][image1]Clicking a button results in raw\_events rows within 100ms.

### **Phase 2: The Brain (Compiler Logic)**

**Objective:** Transform raw, noisy logs into clean, parameterized JSON workflows.

* **Detailed Tasks:**  
  1. **Agno Agent Configuration:** Initialize AnalystAgent.  
  2. **Pydantic Modeling:** Define models for Mode, Step, Action, and Variable.  
  3. **Log Processing:** Pipeline to fetch and format RawEvents.  
  4. **Smart Variable Detection:** Logic to map detected inputs (e.g., "555-0199") to standard keys (e.g., phone\_number) if they likely match data types suitable for the Vault.  
* **Phase 2 Acceptance Criteria:**  
  * **![][image1]**Compiler synthesizes a Mode JSON object from raw events.  
  * ![][image1]Inputs like email addresses are replaced with variables {{user\_email}}.  
  * ![][image1]The system identifies common personal data fields automatically.

### **Phase 3: The Refiner (User Interface)**

**Objective:** Provide a seamless experience for users to review workflows and manage their personal data.

* **Detailed Tasks:**  
  1. **Streamlit Foundation:** Initialize the UI app.  
  2. **Identity Manager Page:** Create a UI page where users can View, Add, Edit, and Delete rows in the UserContext table.  
  3. **Interactive Mode Viewer:** Component to render/edit Mode JSON.  
  4. **Chat-to-JSON Pipeline:** Logic for natural language edits.  
* **Phase 3 Acceptance Criteria:**  
  * **![][image1]**Users can add their "Phone Number" and "Home Address" via the Identity Manager UI.  
  * ![][image1]Data saved in the UI persists to the UserContext table in Postgres.  
  * ![][image1]Users can load and edit recorded sessions.

### **Phase 4: The Hand (Execution Engine)**

**Objective:** Enable the autonomous replay of workflows using semantic understanding and personal data injection.

* **Detailed Tasks:**  
  1. **NanoBrowser Wrapper:** Python wrapper for browser control.  
  2. **Context Resolution:** **NEW:** Implement logic to fetch values from the UserContext table at runtime to populate {{variables}} defined in the Mode.  
  3. **Runtime Embedding & Vector Search:** Logic to find elements via pgvector.  
  4. **State Machine Executor:** Main execution loop.  
* **Phase 4 Acceptance Criteria:**  
  * **![][image1]**Agent successfully executes a "Login" workflow.  
  * ![][image1]**Crucial:** When the Agent encounters {{user\_email}}, it correctly fetches the actual email from the DB and types it into the browser.  
  * ![][image1]Agent relies on vector similarity to find elements even if IDs change.

## **Testing Strategy**

### **Unit Testing**

* **Scope:**  
  * **Context Resolution:** Verify that the Executor correctly substitutes {{variables}} with values from the mock Data Vault.  
  * **Filtering Logic:** Verify noise elimination.

### **Integration Testing**

* **Scope:**  
  * **Database Integrity:** Verify CRUD operations for UserContext and Vector data.  
  * **Vector Search:** Verify nearest neighbor logic.

## **CI/CD Plan**

* **Pipeline Steps:**  
  1. Setup uv.  
  2. Lint (ruff), Type Check (basedpyright).  
  3. Test (pytest).  
  4. Build Docker Image.

## **Containerization: Docker Compose**

version: '3.8'  
services:  
  db:  
    image: ankane/pgvector:v0.5.1  
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

## **Deliverables**

1. **Source Code:** Python package managed by uv.  
2. **Docker Environment:** docker-compose setup with persistent storage.  
3. **Identity Manager:** A functional UI for managing user secrets/data.  
4. **Demo Mode:** A pre-recorded "LinkedIn Job Search" mode.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAmwAAAAUCAYAAAAwe2GgAAAAR0lEQVR4Xu3BMQEAAADCoPVPbQlPoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP4GwdQAAZuLbQIAAAAASUVORK5CYII=>