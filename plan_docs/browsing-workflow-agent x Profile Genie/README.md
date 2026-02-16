# Agno "Mimic" Workflow Agent

## Overview
This project implements an agentic workflow that learns browser automation tasks by watching the user. It utilizes **Agno (Phidata)** for orchestration, **PostgreSQL (pgvector)** for semantic memory, and is designed to work with **NanoBrowser** for robust execution.

## Phases
1.  **Learning Mode:** User browses manually. System records semantic events.
2.  **Compilation:** System converts logs into a `WorkflowMode` object.
3.  **Refinement:** Agent interviews the user to clarify logic.
4.  **Execution:** Agent executes the task, asking for help if stuck.

## Setup

1.  **Environment Variables**
    Create a `.env` file:
    ```bash
    OPENAI_API_KEY=sk-...
    DATABASE_URL=postgresql://user:pass@localhost:5432/agno_db
    NANOBROWSER_API_KEY=...
    ```

2.  **Install Dependencies**
    ```bash
    pip install agno openai playwright pydantic fastapi uvicorn psycopg2-binary pgvector
    ```

3.  **Run Database**
    ```bash
    docker run -d -e POSTGRES_USER=ai -e POSTGRES_PASSWORD=ai -e POSTGRES_DB=agno_db -p 5432:5432 pgvector/pgvector:pg16
    ```

4.  **Start the Recorder (Learning Mode)**
    * Launch Chrome with remote debugging:
        `google-chrome --remote-debugging-port=9222`
    * Run the watcher script:
        `python src/cdp_watcher.py`

## Key Concepts
* **The Mode:** A JSON representation of a job (e.g., "Apply to LinkedIn").
* **The Shadow:** The mechanism of attaching to the user's browser via CDP.
* **Refinement Loop:** The chat interface where the user edits the Mode.
