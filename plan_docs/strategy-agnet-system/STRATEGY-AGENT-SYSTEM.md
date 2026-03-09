# Goal-Directed Multi-Agent Strategy System
## Development Plan & Architecture Guide

**Project Codename:** ORACLE  
**Status:** Pre-Development / Design Phase  
**Author:** [owner]  
**Created:** 2026-03-04  
**Last Updated:** 2026-03-04

---

## 1. Vision & Problem Statement

This system is a personal AI-powered strategic advisor that autonomously researches, generates, evaluates, and operationalizes strategies for achieving a defined set of personal or professional goals. Unlike a single-model chatbot, ORACLE is a **coordinated pipeline of specialized agents** with a shared state store, enabling parallel workstreams, adversarial critique loops, and long-horizon planning.

**Primary Goals (current configuration):**

- `GOAL_01` — Earn money (short and long-term income generation)
- `GOAL_02` — Get a job (employment targeting and acquisition)

The system ingests user-supplied strategy ideas via a structured front-end interface, enriches them via research, evaluates them for fitness against the user's constraints, selects an optimal portfolio, and produces an actionable execution plan.

### 1.1 ★ Core Feature: The Think Tank

> **The defining capability of ORACLE is not any single agent — it is the Think Tank: a structured multi-agent deliberation chamber that produces strategy and planning outputs of exceptional quality through collaborative expert reasoning.**

The standard approach to AI strategy generation is to prompt a single model and accept whatever it produces. That approach produces competent but generic output — the statistical median of the training distribution. ORACLE takes a fundamentally different approach.

When the Orchestrator needs to evaluate a goal, develop an implementation strategy, or determine the best path forward, it does not delegate that task to a single agent. Instead, it **convenes a Think Tank**: a panel of specialized expert agents who discuss, debate, challenge, and iteratively refine the answer among themselves across multiple deliberation rounds before any output is committed to the blackboard.

**Why this produces better results than any single agent:**

The Think Tank is specifically designed to produce outcomes that no individual agent — no matter how capable — could generate alone:

- **Breadth without shallowness** — each expert brings deep domain knowledge from a different angle, so the panel covers more intellectual surface area than any single generalist while maintaining depth in each domain
- **Built-in adversarial pressure** — agents actively challenge each other's reasoning, surfacing hidden assumptions, logical gaps, and overconfident claims before they can propagate into the plan
- **Emergent insight** — the back-and-forth deliberation forces agents to synthesize each other's ideas in ways neither would have reached independently, generating genuinely novel approaches not accessible via a single-pass prompt
- **Calibrated confidence** — after debate, the panel reaches explicit consensus or records structured dissent, so the output includes not just a recommendation but the reasoning, the objections that were considered and rejected, and the confidence level behind the conclusion
- **Outside-the-box thinking on demand** — the panel includes agents specifically tasked with challenging conventional wisdom, drawing analogies from adjacent fields, and proposing unconventional approaches that a single goal-directed agent would filter out as too speculative

The Think Tank is not a committee that produces watered-down compromise. It is a **structured intellectual combat zone** where the best argument wins — and the output is the product of that combat, not a consensus average, but a battle-tested, pressure-hardened conclusion.

**What it is NOT:**
- A single agent asked to "consider multiple perspectives" — that is theatrical role-playing, not genuine multi-agent reasoning
- A voting system — majority rule does not surface the best argument
- A sequential review chain — agents passing a document down the line is not real deliberation
- A rubber stamp on a pre-formed answer

**What it IS:**
- Multiple parallel expert agents, each with a distinct persona, domain specialty, and reasoning style
- A structured discussion protocol: opening positions → challenge round → rebuttal → synthesis
- Live exchange: agents read and directly respond to each other's actual arguments, not to the original prompt
- A Moderator (an Orchestrator sub-process) who sets the agenda, enforces structure, prevents loops, and calls convergence
- A final synthesis artifact that explicitly documents: what was proposed, what was challenged, what was rejected and why, and what the panel ultimately recommends with what confidence

---

## 2. Architecture Overview

### 2.1 Top-Level Pattern

**Hybrid: Hierarchical Orchestrator + DAG Pipeline + Think Tank Deliberation Chamber + Shared Blackboard**

```
┌────────────────────────────────────────────────────────────────────┐
│                          ORCHESTRATOR                              │
│            (goal decomp · task dispatch · convergence)             │
└───────┬───────────────────────────────────────────┬───────────────┘
        │                                           │
 ┌──────▼──────┐                          ┌─────────▼──────────────────────────────────┐
 │  RESEARCHER  │                          │           ★ THINK TANK ★                   │
 │   CLUSTER   │◄────────────────────────►│  (convened by Orchestrator per goal/task)  │
 │             │    research findings      │                                            │
 │ · WebSearch │    feed into Tank         │  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
 │ · Synthesis │                          │  │ EXPERT A │  │ EXPERT B │  │EXPERT C │ │
 │ · Domain    │                          │  │ Strategst│  │ Critic   │  │Analogst │ │
 └──────┬──────┘                          │  └────┬─────┘  └────┬─────┘  └────┬────┘ │
        │                                 │       │  ◄──debate──►  ◄──debate──►│      │
        │                                 │  ┌────▼─────┐  ┌────▼─────┐       │      │
        │                                 │  │ EXPERT D │  │ EXPERT E │◄──────┘      │
        │                                 │  │ Domain   │  │ Devil's  │              │
        │                                 │  │ Specialist│  │ Advocate │              │
        │                                 │  └──────────┘  └──────────┘              │
        │                                 │                                            │
        │                                 │  ┌────────────────────────────────────┐   │
        │                                 │  │         MODERATOR (sub-agent)      │   │
        │                                 │  │  agenda · rounds · convergence     │   │
        │                                 │  └─────────────────┬──────────────────┘   │
        │                                 └────────────────────┼────────────────────── ┘
        │                                                      │
        │                                       Think Tank synthesis output
        │                                                      │
        └──────────────────────┬───────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │      EVALUATOR       │
                    │  fitness scoring     │
                    │  feasibility         │
                    │  forecast / sim      │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │      SELECTOR        │
                    │  multi-objective     │
                    │  Pareto frontier     │
                    │  portfolio opt.      │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   PLANNER/EXECUTOR   │
                    │  roadmap gen         │
                    │  resource assign     │
                    │  task scheduling     │
                    └──────────┬──────────┘
                               │
              ┌────────────────▼─────────────────┐
              │            BLACKBOARD             │
              │  (structured JSON + vector store  │
              │   · single source of truth)       │
              └────────────────┬─────────────────┘
                               ▲
                               │ write/read
              ┌────────────────┴─────────────────┐
              │           IDEABASE UI             │
              │  (user input · Notion sync ·      │
              │   strategy seed data)             │
              └──────────────────────────────────┘
```

### 2.2 Communication Model

The system uses **two distinct communication patterns** depending on context:

**Pipeline communication (Orchestrator ↔ all pipeline agents):** Asynchronous and blackboard-mediated. No agent calls another directly. The Orchestrator drives the DAG by reading blackboard state and dispatching tasks. This provides loose coupling, full auditability, and replay capability.

**Think Tank communication (intra-panel):** Synchronous and conversational within a managed session. When the Orchestrator convenes a Think Tank, the panel agents communicate directly with each other in a structured multi-turn exchange, mediated by the Moderator sub-agent. The full deliberation transcript is written to the blackboard as a unit once the session concludes. This is the **exception** to the blackboard-only rule — the deliberation itself is live and stateful by design, because genuine debate requires agents to read and respond to each other's actual arguments in real time.

**Why the exception is justified:** Routing every Think Tank message through the blackboard would introduce artificial latency and break the conversational coherence that makes deliberation effective. The panel session is treated as an atomic unit: it begins when the Orchestrator dispatches a deliberation task, and it ends when the Moderator writes the synthesis + full transcript to the blackboard. From the pipeline's perspective, the Think Tank is a black box that takes a goal/strategy as input and returns a richly documented recommendation as output.

---

## 3. Component Specifications

### ★ 3.0 The Think Tank (Core Feature)

**Status:** Design phase — highest priority component  
**Convened by:** Orchestrator  
**Triggered when:** A goal or strategy requires deep analysis, novel ideation, or a high-stakes planning decision

The Think Tank is a **managed multi-agent deliberation session**. It is not a permanent running service — it is instantiated on demand by the Orchestrator whenever a question is too important to be answered by a single agent. Each session is a self-contained exchange with a defined goal, a structured protocol, and a formal output.

#### 3.0.1 When the Orchestrator Convenes a Think Tank

The Orchestrator decides to convene a Think Tank instead of dispatching to a single agent when any of the following are true:

- The task is a primary goal or strategy — not a sub-task or lookup
- The output will directly drive planning or resource allocation decisions
- The question is genuinely open-ended with multiple valid high-quality approaches
- Previous single-agent outputs on similar questions scored below confidence threshold
- The user has flagged a strategy as high-priority ("pinned" in Ideabase)

#### 3.0.2 Panel Composition

The Orchestrator selects 4–6 experts from the available roster based on the goal domain. Panels are not fixed — composition is dynamic and goal-specific.

**Standing expert roster:**

| Expert | Persona | Core contribution |
|---|---|---|
| **The Strategist** | Senior management consultant with 20yr track record | Frameworks, structured approaches, known best practices, execution patterns |
| **The Critic** | Adversarial red-teamer and assumption hunter | Challenges every claim, finds gaps, stress-tests confidence, prevents groupthink |
| **The Analogist** | Cross-domain knowledge synthesizer | Finds and maps successful patterns from unrelated fields onto the current problem |
| **The Domain Specialist** | Deep expert in the goal's specific domain (e.g., tech hiring, SaaS, systems engineering) | Ground-truth domain knowledge, practical constraints, market reality |
| **The Devil's Advocate** | Contrarian assigned to argue against the emerging consensus | Prevents premature convergence, forces the panel to address the strongest counterarguments |
| **The Synthesizer** | Integrative thinker focused on finding the unified best answer | Reads the full debate and constructs the optimal combined solution |
| **The Futurist** | Long-horizon trend analyst | Identifies second-order effects, asymmetric bets, and strategies that compound over time |
| **The Pragmatist** | Execution-focused realist | Cuts through elegant theory to identify what will actually work given real constraints |

For a typical strategy session, the Orchestrator would select: Strategist + Critic + Domain Specialist + Devil's Advocate + Synthesizer.

#### 3.0.3 Deliberation Protocol

The session follows a structured multi-round protocol enforced by the Moderator sub-agent:

```
PHASE 0 — BRIEFING (Moderator → all experts)
  Moderator provides: goal statement, constraints, research findings from Researcher cluster,
  seed ideas from Ideabase, any prior evaluations. Each expert reads the brief.

PHASE 1 — OPENING POSITIONS (parallel, 1 round)
  Each expert independently produces their initial position:
    - Their recommended strategy or approach
    - Top 3 reasons it is the best path
    - The single biggest risk or weakness they see in their own recommendation

PHASE 2 — CHALLENGE ROUND (conversational, 2–3 rounds)
  Experts read each other's positions and respond directly:
    - Challenge claims they disagree with (with reasoning)
    - Identify contradictions between other experts' positions
    - Ask pointed questions that must be answered
    - Build on points they agree with and extend them
  The Moderator routes challenges to the appropriate expert and ensures everyone responds.

PHASE 3 — REBUTTAL & REFINEMENT (conversational, 1–2 rounds)
  Each expert responds to the challenges directed at them:
    - Defend positions that survive scrutiny (with stronger evidence)
    - Concede points that were validly challenged (explicitly)
    - Update and refine their recommendation based on the debate
  Experts may revise their original position at this stage.

PHASE 4 — SYNTHESIS (Synthesizer agent, 1 round)
  The Synthesizer reads the full transcript and produces:
    - The recommended strategy (incorporating the best elements from the debate)
    - A clear statement of what was argued and why this approach won
    - The top 3 objections that were raised and how they were resolved
    - Remaining open risks (objections that were not fully resolved)
    - Confidence level (High / Medium / Low) with justification

PHASE 5 — DEVIL'S ADVOCATE FINAL CHALLENGE (1 round)
  The Devil's Advocate reviews the Synthesizer's output and makes one final attempt
  to defeat it. If they cannot produce a compelling counterargument, the synthesis stands.
  If they do produce a compelling counterargument, the Moderator triggers one additional
  Synthesizer revision before closing.

PHASE 6 — CLOSE (Moderator)
  Moderator writes the full session to the blackboard:
    - Final synthesis recommendation
    - Full deliberation transcript
    - Confidence score
    - Dissenting opinions (if any expert refused to concede)
    - Session metadata (participants, rounds, duration)
```

#### 3.0.4 Output Schema

```json
{
  "session_id": "tt-uuid",
  "goal_id": "string",
  "strategy_id": "string (if refining a specific strategy)",
  "convened_at": "ISO8601",
  "panel": ["Strategist", "Critic", "Domain Specialist", "Devil's Advocate", "Synthesizer"],
  "synthesis": {
    "recommendation": "string (the final recommended strategy/approach)",
    "rationale": "string (why this was chosen over alternatives)",
    "key_arguments_won": ["string"],
    "objections_resolved": [{ "objection": "string", "resolution": "string" }],
    "open_risks": ["string"],
    "confidence": "High | Medium | Low",
    "confidence_rationale": "string"
  },
  "dissent": [
    { "expert": "string", "position": "string", "unresolved_objection": "string" }
  ],
  "transcript": [
    {
      "phase": "opening | challenge | rebuttal | synthesis | devils_advocate | close",
      "round": 1,
      "expert": "string",
      "addressed_to": "string | all",
      "content": "string"
    }
  ]
}
```

#### 3.0.5 Implementation Approach

**Single-model multi-agent via system prompt differentiation:**  
Each expert is a separate API call with a distinct system prompt defining their persona, domain, and reasoning mandate. They are not different models — they are the same model with radically different instruction sets, which is sufficient to produce genuine perspective diversity.

**Conversation threading:**  
The Moderator maintains the conversation thread. Each agent receives: their own system prompt + the full conversation history so far (all other agents' messages). This gives each agent genuine awareness of what others have said, enabling real response and rebuttal rather than parallel independent generation.

**Cost management:**  
A full 5-agent, 6-phase session with 2–3 rounds per phase is approximately 30–50 API calls. At Sonnet pricing this is $0.50–$2.00 per session. The Orchestrator should use Think Tank sessions selectively — for high-value decisions, not routine sub-tasks.

**Parallelization:**  
Phase 1 (opening positions) and any parallel phases run as concurrent API calls. Sequential phases (challenge, rebuttal) are inherently ordered but individual responses within a round can be parallelized.



**Technology:** React (single-file JSX artifact)  
**Status:** ✅ MVP Complete — Notion integration active

A structured idea-capture interface for seeding the pipeline with user-supplied strategy candidates. **Primary idea source is the user's Notion database**, fetched live via the Notion MCP integration. Manual entry is supported as a secondary input.

#### 3.1.1 Notion Integration

**Architecture:** Claude API (`claude-sonnet-4`) + Notion MCP server (`https://mcp.notion.com/mcp`) called from within the React artifact.

**Flow:**
```
User provides DB ID (or auto-discover)
  → Artifact calls Anthropic /v1/messages
    → Claude uses Notion MCP tool (notion_query_database)
      → Raw Notion pages returned in mcp_tool_result blocks
        → Fuzzy property mapper normalizes to idea schema
          → Ideas rendered in UI
```

**Notion MCP call pattern:**
```javascript
fetch("https://api.anthropic.com/v1/messages", {
  body: JSON.stringify({
    model: "claude-sonnet-4-20250514",
    mcp_servers: [{ type: "url", url: "https://mcp.notion.com/mcp", name: "notion" }],
    messages: [{ role: "user", content: `Query Notion database: ${dbId}` }]
  })
})
```

**Property mapping (fuzzy, schema-agnostic):**

The mapper performs case-insensitive substring matching on Notion property names, so it works across any DB schema without hardcoding field names:

| Our field | Notion property names matched (priority order) |
|---|---|
| `text` | name, title, idea, strategy, description |
| `goal` | goal, objective, target |
| `specificity` | specific, type, kind, scope |
| `domain` | domain, category, area, tag |
| `notes` | notes, note, detail, comment, rationale, body |

**Notion property types supported:** `title`, `rich_text`, `select`, `multi_select`, `checkbox`, `url`, `number`

**DB ID sources (in priority order):**
1. Auto-discover: Claude queries Notion search API to list all accessible databases
2. Manual paste: user copies DB ID from Notion URL

**Data model per idea (canonical):**
```json
{
  "id": "string",
  "notionId": "string (Notion page UUID)",
  "notionUrl": "string (direct page link)",
  "text": "string",
  "goal": "💰 Earn Money | 💼 Get Job | 🎯 Both",
  "specificity": "Specific | General",
  "domain": "Consulting | Freelance | Employment | Products | Content | Investing | Other",
  "notes": "string",
  "pinned": "boolean",
  "source": "notion | user | generated | researched"
}
```

**Capabilities:**
- Live pull from Notion DB via MCP (no token management in UI — handled by Claude.ai connector)
- Fuzzy property mapping works across any Notion DB schema
- Auto-discover lists all databases the integration has access to
- Inline editing, tagging, goal re-assignment, pinning
- Filter by goal / specificity, full-text search across text + notes
- Direct ↗ link back to source Notion page per idea
- JSON export for pipeline ingestion

**Planned enhancements:**
- [ ] Write-back to Notion (update page properties after evaluation)
- [ ] Drag-to-reorder + confidence slider
- [ ] Bulk import from plaintext paste
- [ ] Incremental sync (delta fetch, not full reload)
- [ ] Multi-DB merge (combine ideas from multiple Notion databases)

---

### 3.2 Orchestrator Agent

**Role:** Meta-controller of the entire pipeline. Does not itself generate content — it routes, schedules, monitors, and decides when to converge.

**Responsibilities:**
- Parse goal definitions and constraints from blackboard
- Decompose goals into sub-goal trees (BFS, configurable depth)
- Dispatch tasks to agent queues
- Monitor progress, retry failed tasks, handle timeouts
- Detect convergence criteria (e.g., `n_evaluated >= threshold`)
- Trigger re-evaluation cycles on schedule or user request

**System prompt focus:** Meta-reasoning, structured output (JSON task objects), routing logic, priority weighting.

**Key outputs:**
```json
{
  "task_queue": [...],
  "active_agents": {...},
  "pipeline_state": "researching | evaluating | selecting | planning | done",
  "convergence_score": 0.0
}
```

---

### 3.3 Researcher Cluster

Three specialized sub-agents running in parallel:

#### 3.3.1 Web Search Agent
- Queries search APIs (Brave, Serper, Tavily) with auto-generated queries derived from strategy ideas
- Deduplicates and filters results by relevance score
- Writes raw findings to `blackboard.research_raw[]`

#### 3.3.2 Knowledge Synthesis Agent
- Consumes `research_raw`, produces structured summaries
- Tags each finding: `domain`, `strategy_id[]`, `confidence`, `recency`
- Writes to `blackboard.research_findings[]`

#### 3.3.3 Domain Expert Agent(s)
- Persona-prompted specialists (e.g., "senior tech recruiter", "indie SaaS founder", "freelance C++ consultant")
- Generate domain-specific insight and context that web search won't surface
- Configurable: spin up per-domain as needed

---

### 3.4 Strategist Cluster → Superseded by Think Tank

> **Note:** The original design included a standalone Strategist Cluster (Generator, Analogist, Critic agents operating independently). This has been **superseded and absorbed into the Think Tank** (Section 3.0). The Think Tank's panel roster includes all of these roles — Strategist, Analogist, Critic, and more — but executes them as a coordinated deliberative session rather than as independent parallel agents.

The standalone Strategist Cluster may be retained as a **lightweight fallback** for low-stakes ideation tasks where a full Think Tank session would be disproportionate. In that mode it operates as before: parallel independent generation followed by a merge pass. But for any primary goal or strategy work, the Think Tank is the correct dispatch target.



---

### 3.5 Evaluator Agent

**Role:** Scores every strategy on a multi-dimensional fitness matrix.

**Fitness Schema:**
```json
{
  "strategy_id": "string",
  "scores": {
    "time_to_first_dollar_days": 30,
    "probability_of_success_pct": 65,
    "skill_match_pct": 90,
    "weekly_hours_required": 15,
    "upfront_cost_usd": 0,
    "income_ceiling_monthly_usd": 25000,
    "risk_level": "low | medium | high | extreme",
    "reversibility": "easy | moderate | hard",
    "compounding": "none | linear | exponential"
  },
  "rationale": "string",
  "assumptions": ["string"],
  "confidence": 0.0
}
```

**Methods:**
- LLM scoring with chain-of-thought rationale
- Optionally: Monte Carlo simulation via code execution tool (for income variance modeling)
- Cross-reference against user constraint profile

---

### 3.6 Selector Agent

**Role:** Chooses the optimal portfolio of strategies from evaluated candidates.

**Approach:** Multi-objective optimization — does **not** return a single winner but a **Pareto frontier** of non-dominated strategies.

**Constraint inputs (from user profile):**
```json
{
  "time_horizon_weeks": 12,
  "weekly_hours_available": 20,
  "upfront_budget_usd": 500,
  "risk_tolerance": "medium",
  "cash_flow_urgency": "high"
}
```

**Output:** Ranked portfolio with:
- Primary strategy (highest weighted score)
- 2–3 parallel strategies (diversification)
- 1–2 long-horizon bets (asymmetric upside)

---

### 3.7 Planner / Executor Agent

**Role:** Converts selected strategies into a concrete, dependency-aware execution roadmap.

**Output schema:**
```json
{
  "roadmap": {
    "weeks": [
      {
        "week": 1,
        "theme": "string",
        "tasks": [
          {
            "id": "t001",
            "title": "string",
            "strategy_id": "string",
            "hours_est": 3,
            "depends_on": ["t000"],
            "deliverable": "string",
            "status": "todo | in_progress | done | blocked"
          }
        ]
      }
    ]
  }
}
```

**Features:**
- SMART task generation (Specific, Measurable, Achievable, Relevant, Time-bound)
- Dependency graph with critical path identification
- Weekly re-evaluation triggers (feedback loop back to Evaluator)

---

### 3.8 Blackboard (Shared State Store)

**The single source of truth for all agents.**

**Technology options (ranked):**

| Option | Pros | Cons | Recommended Phase |
|---|---|---|---|
| JSON file + Git | Zero infra, full history | No concurrent writes | Phase 1 |
| SQLite + vector ext | Local, fast, queryable | Slightly more setup | Phase 2 |
| Qdrant + Postgres | Production-grade, semantic search | Infra overhead | Phase 3 |
| Redis + pgvector | Real-time capable | Overkill early | Phase 4+ |

**Top-level blackboard schema:**
```json
{
  "meta": { "run_id", "created_at", "pipeline_state", "version" },
  "goals": [...],
  "constraints": {...},
  "ideas": [...],
  "research_raw": [...],
  "research_findings": [...],
  "strategies": [...],
  "evaluations": [...],
  "selected_portfolio": [...],
  "roadmap": {...},
  "log": [...]
}
```

---

## 4. Validation Ideas (Seed Set)

The following ideas are the initial seed set for system validation — a mix of specific and general, across both goals. Some are synthetic placeholders; others are grounded in the user's actual background (20+ years principal-level C#/C++).

### 4.1 Earn Money — Specific

| # | Idea | Domain | Rationale |
|---|---|---|---|
| V01 | Contract C++ systems work via Toptal or Gun.io | Freelance | Deep systems expertise is scarce and commands $150–250/hr |
| V02 | Fractional CTO / interim engineering lead for Series A–B startups | Consulting | Principal-level credibility; startups need leadership without full-time cost |
| V03 | Sell a developer tooling CLI on Gumroad (one-time purchase, $20–80) | Products | Low overhead, leverage existing tooling knowledge |
| V04 | Technical consulting retainer for hedge fund / quant shop (C++ performance) | Consulting | Niche, high-value, recurring; quant shops pay a premium for low-latency expertise |
| V05 | Write and sell a Udemy/Teachable course: "Modern C++ for Systems Engineers" | Content | Course on specific niche → recurring passive income |

### 4.2 Earn Money — General

| # | Idea | Domain | Rationale |
|---|---|---|---|
| V06 | Build a SaaS micro-tool solving a developer workflow pain point | Products | Indie hacker path; compounding revenue |
| V07 | Technical ghostwriting / thought leadership articles for VC-backed startups | Content | Leverage communication skills; $500–2k per piece |
| V08 | Royalty-based licensing of a reusable C++ component library | Products | One-time effort, ongoing returns |
| V09 | Open source a well-scoped tool → sponsored by companies using it | Content | GitHub Sponsors + OpenCollective; builds reputation simultaneously |

### 4.3 Get a Job — Specific

| # | Idea | Domain | Rationale |
|---|---|---|---|
| V10 | Target Staff/Principal IC roles at FAANG (Google, Meta, Amazon) | Employment | Clear bar, structured process; leverage 20yr experience |
| V11 | Apply to high-growth Series B/C companies as first/early Staff engineer | Employment | More impact, faster equity upside than big tech |
| V12 | Direct outreach to VPs/CTOs at companies whose engineering blog you admire | Employment | Bypasses ATS; warm relationship before role exists |
| V13 | Engage specialized recruiter firms (e.g., Riviera Partners, Hirewell) focused on C-level/staff IC | Employment | High-touch, pre-screened opportunities |

### 4.4 Get a Job — General

| # | Idea | Domain | Rationale |
|---|---|---|---|
| V14 | Rebuild and publish GitHub portfolio of representative systems-level work | Employment | Concrete proof-of-skill; link in every application |
| V15 | Speak at a local or virtual C++ / systems programming meetup or conference | Employment | Visibility with hiring managers who attend |
| V16 | Write a targeted series of technical blog posts → indexed on Google → inbound leads | Content | Dual-purpose: earns money (ads/affiliate) + drives job inquiries |

---

## 5. Development Phases

### Phase 1 — Minimal Viable Pipeline (Target: 1–2 weeks)
**Goal:** Get 10+ ranked strategies out of an end-to-end run.

- [x] Ideabase UI (MVP complete)
- [ ] Blackboard as structured JSON file
- [ ] Orchestrator: linear dispatch (no parallelism yet)
- [ ] Researcher: single web search agent
- [ ] Evaluator: LLM scoring against fitness matrix
- [ ] Selector: simple weighted ranking
- [ ] Output: markdown-formatted ranked strategy list

**Success criterion:** Feed ideabase JSON → get ranked strategy list with rationale in under 5 minutes.

---

### Phase 2 — Think Tank MVP + Parallel Research (Target: 3–5 weeks)
**Goal:** First end-to-end Think Tank session producing a strategy recommendation visibly better than single-agent output.

- [ ] Think Tank session manager (Moderator sub-agent)
- [ ] Expert roster: 5 agents with distinct system prompts (Strategist, Critic, Domain Specialist, Devil's Advocate, Synthesizer)
- [ ] Deliberation protocol: all 6 phases implemented
- [ ] Full transcript written to blackboard + rendered in UI
- [ ] Parallelize Researcher cluster (3 sub-agents)
- [ ] Blackboard → SQLite with FTS
- [ ] Constraint profile UI (time horizon, hours/week, budget, risk tolerance)
- [ ] Pareto selector with portfolio output

**Success criterion:** Run a Think Tank on `GOAL_01` and `GOAL_02`. The synthesis output should contain at least one strategy or insight that no single-agent pass on the same goal produced. A human reviewer (the user) should be able to read the transcript and see genuine debate and position updates — not parallel independent essays.

---

### Phase 3 — Think Tank Iteration + Planner Feedback Loop (Target: 6–10 weeks)
**Goal:** Think Tank outputs feed directly into Planner; system tracks what was tried and re-convenes to adapt.

- [ ] Think Tank outputs → Planner agent (roadmap from synthesis recommendation)
- [ ] Dependency graph + critical path display
- [ ] Task tracking UI → feeds back into Evaluator and Think Tank re-convene trigger
- [ ] Dynamic panel composition (Orchestrator selects experts per goal domain)
- [ ] Weekly re-run trigger with delta: "what changed since last session?"
- [ ] Blackboard → Qdrant (vector search over prior Think Tank transcripts)

**Success criterion:** System produces a 12-week roadmap from a Think Tank synthesis, and successfully re-convenes the Tank after user marks a strategy as failed — producing an updated recommendation that explicitly references what was tried and why it didn't work.

---

### Phase 4 — Autonomous Operation (Target: 10+ weeks)
**Goal:** Near-autonomous background operation with user as reviewer.

- [ ] Scheduled background research runs (new findings surface automatically)
- [ ] Proactive alerts ("a new Stack Overflow Jobs category opened matching your profile")
- [ ] Memory layer: what was tried, outcomes, learnings
- [ ] Multi-user / multi-goal configuration
- [ ] Optional: LangGraph + LangSmith for observability

---

## 6. Technology Stack

### Recommended Stack (Python-primary, C# optional host)

| Layer | Technology | Notes |
|---|---|---|
| Agent orchestration | LangGraph | Best-in-class DAG control flow |
| LLM provider | Anthropic Claude Sonnet | Balance of capability and cost |
| Web search | Tavily API | Purpose-built for LLM agents |
| Blackboard (P1) | JSON + Git | Zero infra, full audit trail |
| Blackboard (P2+) | SQLite + sqlite-vec | Local, fast, no server |
| Blackboard (P3+) | Qdrant + Postgres | Production, semantic search |
| Frontend | React (JSX artifact) | Already started |
| API layer | FastAPI | Thin wrapper, easy to extend |
| Deployment | Local first → Railway/Fly.io | Cost-free to start |

### Alternative: C# Host
Given the user's background, a C# host (ASP.NET Core) calling a Python LangGraph microservice over HTTP is a viable pattern — best of both worlds.

---

## 7. Key Design Decisions & Rationale

**Why a Think Tank instead of a single capable agent for strategy work?**  
A single agent, no matter how well prompted, produces output from one perspective in one pass. It has no mechanism to challenge its own assumptions, discover the strongest counterargument to its own recommendation, or synthesize competing ideas in real time. Multi-agent deliberation with genuine back-and-forth produces measurably different — and better — outputs on open-ended strategic questions because the adversarial structure forces the reasoning to be explicit, defensible, and tested.

**Why structured deliberation phases instead of free-form agent chat?**  
Unstructured agent conversations tend to devolve into agreement or circular repetition. The phase structure (opening → challenge → rebuttal → synthesis → devil's advocate → close) ensures every position is challenged, every challenge is answered, and the output is a synthesis rather than the last agent's opinion. The Moderator enforces this structure and prevents any expert from dominating.

**Why does the Think Tank use direct intra-panel communication instead of the blackboard?**  
Genuine deliberation requires each agent to read and respond to what others actually said — not to a summary or a structured record. The latency and abstraction of blackboard-mediated messaging would break the conversational coherence that makes debate effective. The panel session is treated as an atomic unit: the full transcript is written to the blackboard as a single artifact when the session closes.

**Why blackboard over direct agent-to-agent messaging for the pipeline?**  
Direct messaging creates tight coupling and makes replay/debugging hard. Blackboard gives full auditability, enables asynchronous operation, and allows any agent to be replaced without cascading changes. The Think Tank is the deliberate exception to this rule, justified above.

**Why Pareto frontier over single winner in Selector?**  
Real-world strategies have irreducible tradeoffs (time-to-income vs. ceiling vs. effort). Forcing a single winner discards information. A portfolio of 3–5 non-dominated strategies is more robust and more honest.

**Why seed with user ideas rather than generating from scratch?**  
The user has domain knowledge the model lacks. User ideas are strong priors. The system's job is to enrich, pressure-test, and supplement them — not replace them with hallucinated alternatives.

**Why structured fitness scoring over freeform LLM opinion?**  
Structured scoring enables sorting, filtering, comparison, and re-scoring when constraints change. Freeform text is useful as rationale but not as a decision input.

---

## 8. Open Questions / Design TODOs

- [ ] **Think Tank panel sizing:** what is the right number of experts? 4 is cheaper; 6 gives more coverage. Does the marginal 5th or 6th expert produce enough additional insight to justify the cost?
- [ ] **Think Tank convergence:** when should the Moderator force-close a session that isn't converging? (time limit? round limit? diminishing-returns detection?)
- [ ] **Expert persona stability:** do we need persistent expert identities across sessions (so "the Critic" always reasons the same way), or is per-session instantiation sufficient?
- [ ] **How to surface the transcript to the user:** should the full deliberation be readable in the UI, or just the synthesis? (Full transcript has high value for building trust in the output)
- [ ] How to handle conflicting scores between Evaluator and Think Tank synthesis? (weighted merge? escalate to Orchestrator?)
- [ ] Should the Planner generate tasks at day-level or week-level granularity for Phase 1?
- [ ] How to model "parallel strategies" in the roadmap without overcommitting user hours?
- [ ] Memory format: flat log vs. entity-relationship graph (consider Zep or custom)?
- [ ] Should the system support multiple constraint profiles (e.g., "aggressive" vs. "conservative" scenarios)?

---

## 9. Glossary

| Term | Definition |
|---|---|
| **Think Tank** | ★ Core feature. A managed multi-agent deliberation session convened by the Orchestrator to produce strategy and planning outputs via structured expert debate. Not a single agent — a panel. |
| **Moderator** | Sub-agent within the Think Tank responsible for enforcing the deliberation protocol, routing challenges, and calling convergence |
| **Deliberation protocol** | The structured 6-phase session format (briefing → opening → challenge → rebuttal → synthesis → devil's advocate → close) that governs every Think Tank session |
| **Panel** | The set of 4–6 expert agents selected by the Orchestrator for a specific Think Tank session |
| **Synthesis** | The final output of a Think Tank session: a recommended strategy with documented rationale, resolved objections, open risks, and confidence level |
| **Blackboard** | Shared, append-oriented state store that all pipeline agents read from and write to |
| **Fitness matrix** | Structured multi-dimensional scoring schema applied to each strategy candidate by the Evaluator |
| **Orchestrator** | Meta-agent responsible for task dispatch, routing, Think Tank convening, and convergence detection |
| **Pareto frontier** | Set of strategies where no strategy is strictly dominated by another across all dimensions |
| **Convergence** | Pipeline state where additional research/generation/deliberation yields diminishing marginal value |
| **Strategy candidate** | Any idea (user-supplied or generated) that has been formally entered into the pipeline for evaluation |
| **Seed ideas** | User-supplied ideas from the Ideabase (Notion DB); serve as strong priors for the pipeline |

---

*End of document. Next: implement Phase 1 pipeline skeleton.*
