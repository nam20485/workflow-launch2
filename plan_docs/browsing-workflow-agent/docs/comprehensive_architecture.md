# Agno "Mimic" Agent: Comprehensive Architecture Guide

## 1. High-Level System Topology

The system operates as a closed feedback loop consisting of four distinct "Engines."

```mermaid
graph TD
    User[User (Chrome)] -->|CDP Stream (WebSocket)| Watcher[1. The Watcher (Local Listener)]
    Watcher -->|Raw Events| Ingestion[Event Pipeline]
    Ingestion -->|Semantic Facts| DB[(Postgres + pgvector)]
    DB -->|Session Logs| Compiler[2. The Compiler (Agno Agent)]
    Compiler -->|Draft Mode| Refiner[3. The Refiner (Chat UI)]
    User -->|Feedback| Refiner
    Refiner -->|Approved Mode| DB
    DB -->|Production Mode| Executor[4. The Executor (Agno + NanoBrowser)]
    Executor -->|Actions| Target[Websites (LinkedIn/UserInterviews)]
```

---

## 2. Component Deep Dive

### Engine 1: The Watcher (Data Ingestion)
**Responsibility:** Passively observe the user without interfering.
* **Connection Method:** Connects to the user's running Chrome instance via **Chrome DevTools Protocol (CDP)** on port `9222`.
* **The "Snapshot" Strategy:**
    * We do *not* record video (too heavy/slow).
    * We do *not* record raw DOM (too noisy).
    * **We record the Accessibility Tree (AXTree):** This simplifies the DOM into "Button: Submit", "Link: Jobs". It removes `<div>` soup and styling noise.
* **Event Filter Logic:**
    * *Ignored:* `mousemove`, `scroll` (unless large delta), `hover`.
    * *Captured:* `click`, `keypress` (aggregated into strings), `navigation`, `submit`.

### Engine 2: The Compiler (Mode Synthesis)
**Responsibility:** Translate chronological events into a logical workflow.
* **Core Logic (Agno Agent):**
    1.  **Segmentation:** Identifies boundaries. "User went to linkedin.com" = Start. "User clicked 'Submit'" = End.
    2.  **Variable Identification:** Scans inputs for PII (Personally Identifiable Information).
        * *Pattern:* Input value "John Doe" matches `User.Profile.Name`.
        * *Action:* Replace literal "John Doe" with variable `{{user.name}}`.
    3.  **Deduplication:** Merges rapid-fire clicks or corrections into single Intent blocks.

### Engine 3: The Refiner (Human-in-the-Loop)
**Responsibility:** Alignment and Error Correction.
* **Interface:** A Chat UI (Streamlit or Chainlit).
* **The "Interrogation" Protocol:**
    * The Agent presents the *Draft Mode* as a natural language summary.
    * *Agent:* "I noticed you uploaded 'resume_v2.pdf'. Should I always use this file, or should I ask you for a file every time?"
    * *User:* "Always use the file in `/docs/current_resume.pdf`."
    * *System Update:* The Mode JSON is updated with a hardcoded file path constraint.

### Engine 4: The Executor (NanoBrowser Orchestrator)
**Responsibility:** Reliable execution of the Mode.
* **Tool:** **NanoBrowser** (AI-managed browser instance).
* **Execution Strategy:** "Semantic Targeting" vs "Selector Targeting".
    * *Traditional RPA:* Click `#ember123`. (Brittle)
    * *Agno Executor:* "Find the 'Easy Apply' button."
        1.  Agent takes AXTree snapshot of NanoBrowser.
        2.  Agent queries Vector DB: "What did the 'Easy Apply' button look like in the recording?"
        3.  Agent finds the closest semantic match on the *current* page.
        4.  Agent executes click.

---

## 3. Data Schemas

### A. The "Fact" (Atomic Recording)
Stored in Postgres `events_log`.
```json
{
  "timestamp": 170800123.45,
  "session_id": "session_001",
  "url": "[https://linkedin.com/jobs/view/](https://linkedin.com/jobs/view/)...",
  "event_type": "click",
  "target_element": {
    "tag": "button",
    "text": "Easy Apply",
    "aria_label": "Apply to Google",
    "xpath": "/html/.../button[2]"
  },
  "context_snapshot": "...summary of surrounding 5 elements..."
}
```

### B. The "Mode" (Compiled Workflow)
Stored in Postgres `modes` table. This is the "Code" the agent runs.
```json
{
  "mode_id": "linkedin_apply_v1",
  "variables": [
    {"name": "job_title", "source": "user_prompt"},
    {"name": "resume_path", "source": "config"}
  ],
  "steps": [
    {
      "id": 1,
      "description": "Navigate to Job",
      "action": "goto",
      "params": {"url": "{{job_url}}"}
    },
    {
      "id": 2,
      "description": "Click Apply Button",
      "action": "click",
      "semantic_target": "Easy Apply Button",
      "verification": "Check for modal popup 'Contact Info'"
    }
  ]
}
```
