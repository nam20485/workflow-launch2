# App Implementation Spec: Job Command Center

## 1. Description
### Overview
Job Command Center is a local-first platform for aggressive job searching. It utilizes a "God Mode" worker to attach to an existing Chrome session, bypassing advanced bot detection by acting as a co-pilot rather than a standalone agent.

## 2. Requirements
### Features
* **God Mode Harvester**: Worker connecting to `localhost:9222` to assumptions control of the LinkedIn tab.
* **Human-Mimicry Engine**: Uses Gaussian-distributed delays and micro-interactions (mouse jitter) to mask automated patterns.
* **Relational Pipeline**: PostgreSQL tracking job stages: `Found`, `Scored`, `Pending`, `Applied`, `Interviewing`.
* **Dynamic Scoring**: Local C# library calculating relevance based on user weights.
* **Kanban Dashboard**: High-density MudBlazor UI for pipeline management.

### Containerization
* **PostgreSQL**: Containerized via .NET Aspire (`AddPostgres`).
* **Harvester**: **NATIVE PROCESS ONLY.** Running in Docker prevents connection to host CDP ports.

## 3. Technology Stack
* **Language**: C# 12 / .NET 9.0
* **Orchestration**: .NET Aspire
* **Automation**: Playwright for .NET
* **Database**: PostgreSQL with EF Core
* **UI**: Blazor Server with MudBlazor

## 4. Project Structure
```text
/JobCommandCenter
├── JobCommandCenter.AppHost          # Orchestrator
├── JobCommandCenter.Data             # EF Core Models & Context
├── JobCommandCenter.Harvester        # Playwright CDP Worker
├── JobCommandCenter.Shared           # Scoring & DTOs
└── JobCommandCenter.Web              # Blazor Management UI
```