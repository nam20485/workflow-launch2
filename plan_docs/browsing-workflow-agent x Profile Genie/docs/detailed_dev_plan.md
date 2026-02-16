# Detailed Development Plan: Agno Mimic Agent

## Phase 1: The Eye (CDP Listener & Data Ingestion)
**Objective:** Create a Python service that connects to a running Chrome instance and logs "meaningful" user actions to a database.

### 1.1. Local Browser Configuration
* **Task:** Create a `start_chrome.sh` script.
* **Details:** Must launch Chrome with `--remote-debugging-port=9222`.
* **Why:** This opens the WebSocket gate for our Python script to listen in.

### 1.2. The "Watcher" Service (Python)
* **Task:** Implement `Watcher` class using `playwright` (connecting over CDP).
* **Key Components:**
    * `CDPClient`: Connects to `ws://127.0.0.1:9222`.
    * `DOMSnapshotter`: A function that runs `page.accessibility.snapshot()` every time a click is detected.
    * `InputAggregator`: Buffers keystrokes. Only flushes the string to DB when the user presses `Enter` or clicks away (blur event).
* **Output:** A `.jsonl` file or direct DB insert of raw events.

### 1.3. Database Setup (PgVector)
* **Task:** Docker Compose file for Postgres 16 + pgvector.
* **Schema:**
    * `sessions`: (id, user_id, start_time, end_time)
    * `raw_events`: (id, session_id, event_type, payload (JSONB), embedding (VECTOR))
* **Milestone:** You browse LinkedIn for 5 minutes, and the DB has ~50 clean, readable rows of actions (not 5000 rows of noise).

---

## Phase 2: The Brain (Agno Compiler Agent)
**Objective:** Use an LLM to read the DB logs and generate a structured JSON "Mode".

### 2.1. The "Analyst" Agent
* **Task:** Create an Agno Agent (`AnalystAgent`).
* **Prompt Engineering:**
    * *Input:* A list of 50 raw events.
    * *Instructions:* "Identify the goal of this session. Group steps into logical blocks. Replace 'Software Engineer' with variable `{{SEARCH_TERM}}`."
* **Tooling:** Give the agent a tool to `read_session_logs(session_id)`.

### 2.2. The Mode Validator
* **Task:** Implement Pydantic models for the `Mode` (see `agno_brain.py`).
* **Details:** The Agent **must** output data that adheres to this schema. If it fails validation, Agno should auto-retry.

---

## Phase 3: The Refiner (Chat Interface)
**Objective:** A UI for the user to review and edit the robot's plan.

### 3.1. Chat App (Streamlit)
* **Task:** Simple split-screen UI.
    * *Left:* Chat bot.
    * *Right:* JSON/YAML viewer of the current "Mode".
* **Interaction Flow:**
    1.  User: "Analyze my last session."
    2.  Agent: (Reads DB, compiles Mode) "Here is what I saw. I detected you logged into LinkedIn. Should I save these credentials?"
    3.  User: "No, assume I am already logged in."
    4.  Agent: (Removes Login Step from Mode object).

### 3.2. Semantic Search Tooling
* **Task:** Enable the agent to search the Vector DB.
* **Why:** User might say "How did I handle the 'Upload Cover Letter' part?" The agent needs to query the `raw_events` embeddings to find that specific moment and explain it.

---

## Phase 4: The Hand (NanoBrowser Execution)
**Objective:** Execute the Mode autonomously.

### 4.1. NanoBrowser Client
* **Task:** Initialize `NanoBrowser` instance via API.
* **Integration:** Write a wrapper `NanoClient` that accepts our semantic commands.

### 4.2. The "Executor" Agent
* **Task:** A State Machine loop.
    ```python
    mode = load_mode("linkedin_apply")
    for step in mode.steps:
        current_state = nanobrowser.get_state()
        action = match_action(step, current_state)
        execute(action)
        verify_result()
    ```
* **Error Handling:** If the "Apply" button isn't found (e.g., LinkedIn changed layout), the Agent pauses and alerts the user via the Chat UI.
