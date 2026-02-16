# Job Command Center: Development Plan

## 1. Guiding Principles
* **Stealth First**: Prioritize account safety over raw scraping speed.
* **Native Integration**: Use .NET Aspire for a seamless "F5 to develop" experience.
* **Data Ownership**: The user owns the database and their search history.

## 2. Implementation Phases

### Phase 1: Foundation
* Scaffold Aspire solution.
* Implement PostgreSQL schema via EF Core.
* Build the shared Scoring logic library.

### Phase 2: The Harvester
* Implement `ConnectOverCDPAsync` logic.
* Develop "Human Mimicry" algorithms.
* Implement LinkedIn DOM extraction with robust ARIA locators.

### Phase 3: Command Center UI
* Build MudBlazor Kanban board.
* Implement real-time "Live Feed" from Harvester.
* Create the Scoring Weight editor.

## 3. Risks and Mitigations
| Risk | Mitigation |
| :--- | :--- |
| **Port 9222 Closed** | Implement "Pre-flight Check" with instructions for user. |
| **LinkedIn DOM Update** | Use text-based locators and centralize selectors in `Shared`. |
| **Docker Isolation** | Force Harvester to run as a native process in AppHost. |