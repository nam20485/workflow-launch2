# Custom Agents Authoring Guide (Claude + Gemini)

## Meta: Analysis Instructions for this document

Do another analysis, review, feedback, improve (ARFI) pass, this time take into acount specifically the following items:

1. THINK DEEPLY for this task
2. Use these suggestions and tips from agents from Anthropic. Incorporate as many as you can that make sense.
<https://www.anthropic.com/engineering/claude-code-best-practices>
3. Collaborate with Gemini (1. /prompt-gemini-cli prompt or if that doesn't work brainstorm/consult via gemini-mcp server tools)
4. Researcher example: readonly for existing code or other project files, but allowed to create scratchpads or docs, or other files related to the task she's ask to do
   1. The researcher should be able to create new files for its research output, such as `brief.md` and `sources.json`.
   2. allow more tools for web searching, and file/source code/project reading, and doc sites reading (context7, deepwiki, ms-docs, etc.)
5. Add any missing tools needed to accomplish their stated roles. 
	1. For example, for agents with instructions to create or edit any files, make sure they have appropriate edit/writeable tools.
	2. Add delegation to resea


---

## The Actual Authoring Guide (Claude + Gemini)

This document defines how to design and configure a suite of Claude custom agents (Claude Code subagents) that collaborate using targeted delegation and a minimal toolset to build production-ready applications from templates. It incorporates explicit research delegation to Gemini (via gemini-mcp), Windows/pwsh operational defaults, and repository-aware behavior.

Assumptions and scope
- Agents are Claude Code subagents defined as Markdown files with YAML frontmatter, stored at project level in `.claude/agents/` or at user level in `~/.claude/agents/` (project subagents take precedence). See Anthropic docs: Claude Code settings → Subagent configuration and Subagents.
- Research tasks delegate to a dedicated Researcher subagent that explicitly uses the Gemini MCP toolchain.
- Operating environment defaults to Windows with PowerShell (pwsh) shell; avoid any bash-only assumptions.
- GitHub automation should prefer MCP GitHub tools first; use VS Code integration next; gh CLI as a last resort.
- This guide defines enforceable patterns and example subagent files in the official format.
- Create every agent in the list.

Additional constraints for this project
- Researcher is read-only on source/config/tests but may create research artifacts under `docs/research/` or `.research/` (e.g., `brief.md`, `sources.json`, and optional `raw/` snapshots).
- Gemini collaboration is mandatory for research: use gemini-mcp tools when available; otherwise fall back to pwsh `Invoke-WebRequest`/`curl` for RAW URLs.
- Research tools permitted (subject to environment availability): gemini-mcp, context7, deepwiki, ms-docs, and local file readers (Read/Grep/Glob). Avoid generic Web UIs; prefer canonical docs and RAW files.
- Automation-first policy applies to GitHub operations (target ≥90% coverage); document any manual exceptions with justification.

## 1) Guiding principles

- Single-focus, short-lived agents: Keep each agent narrowly scoped to maintain high "context fitness" and reduce drift.
- Delegate aggressively: Prefer delegate/perform/approve loops to keep contexts small and outputs crisp.
- Minimal tool permissions: Grant the smallest viable toolset to steer agent behavior and reduce cognitive surface area.
- Orchestrator does not build: The orchestrator plans, delegates, evaluates, and decides; it does not implement.
- Research goes to Gemini: Route research to a Researcher agent that uses gemini-mcp to gather broad context, then distill.
- Repository awareness: Treat the following repos as primary sources of truth for workflows, templates, and policies:
	- nam20485/agent-instructions
	- nam20485/workflow-launch2
	- nam20485/ai-new-app-template
- Automation-first: Use MCP GitHub tools where possible; document any manual steps and justify why automation was not used.
- Windows/pwsh defaults: Prefer PowerShell commands; use Invoke-WebRequest/curl; avoid Linux-only paths and tools.

## 2) Agent taxonomy and responsibilities

Core coordination
- Team Lead Orchestrator: Intake → plan → decompose → delegate → review → decide → merge → close. Zero individual implementation.
- SCRUM Master / Planner: Convert goals into milestones/epics/tasks; ensure cadence, definition-of-done, and acceptance criteria (detailed bullet list) are applied.

Build and quality
- Frontend Developer: Implements UI features from template; writes component tests; adheres to performance budget.
- Backend Developer: Implements endpoints/modules; adds unit/integration tests; ensures observability hooks exist.
- DevOps Engineer: CI/CD, build pipelines, environments; ensures reproducible builds and artifact retention.
- QA Test Engineer: Author tests (unit/integration/e2e), define acceptance checks, run test suites, report gaps.
- Code Reviewer: Enforces standards, readability, security and performance constraints; blocks/approves PRs.
- Debugger: Reproduces issues; creates minimal failing tests; proposes and validates fixes.

Specialized concerns
- Cloud Infra Expert: Cloud-native infra, cost/perf tuning, IaC patterns, security hardening.
- Performance Optimizer: Profiling, bottleneck analysis, target budgets, perf CI gates.
- Security Expert: Threat modeling, secrets hygiene, dependency risk, hardening.
- Database Admin: Schema design, migrations, performance, backup/restore.
- Data Scientist / ML Engineer: Data pipelines, models, evaluation, reproducibility.
- Prompt Engineer: System prompts, tool routing, guardrails; A/B evaluation of prompts.
- UX/UI Designer: Wireframes, flows, accessibility, design QA.
- Mobile Developer: Platform-specific build and store readiness.
- Documentation Expert: Developer and user docs; quickstarts; runbooks.
- Researcher: Source discovery and synthesis via gemini-mcp; produces distilled briefs with citations.

## 3) Standard agent contract

Inputs
- Goal or task brief; acceptance criteria; repository context (paths/branch); constraints (tools, time, tokens).

Outputs
- Actionable artifacts (code, docs, configs), a concise execution log, decisions and tradeoffs, and links to PRs/issues.

Tool permissions
- Grant only the tools required for the role. Researcher uniquely has gemini-mcp research tools. Most agents have MCP GitHub tools and local file operations when appropriate. Avoid broad web-fetch; use PowerShell/curl if download is strictly required.

Delegation patterns
- delegate → perform → approve: A delegating agent issues a targeted sub-task, receives deliverables, evaluates, and either approves or requests iteration. Keep parallel delegations low (2 max) unless the task is embarrassingly parallel.

Termination
- Stop when acceptance criteria are met with evidence (tests passing, PR ready, docs updated) or when a blocker requires escalation.

## 4) Orchestrator workflow

1) Intake: Normalize the ask, list constraints, identify acceptance criteria, and confirm repositories/branch scope.
2) Plan: Break down into small tasks; assign to specialized agents; schedule delegate/perform/approve loops.
3) Fan-out: Create sub-issues/PR stubs via MCP GitHub tools; delegate with explicit success criteria.
4) Collect: Aggregate outputs and summaries; request fixes where needed.
5) Review: Route to Code Reviewer and QA Test Engineer; ensure security/perf checks as required.
6) Decide: Approve/merge or iterate; ensure docs and release notes are updated.
7) Close: Close issues, link artifacts, and record learnings.

## 5) Delegation protocols

Research delegation
- Always use the Researcher agent for research. Instruct it to explicitly use gemini-mcp to gather broad context from allowed sources, then produce a distilled, citation-rich brief with risks and next actions.

Implementation delegation
- Developer agents receive precise specs, file paths, coding standards, and test expectations. They must create/update tests and produce a small summary of changes.

Review delegation
- Code Reviewer checks style, correctness, security, and performance. Provide structured findings and clear approve/block decision.

QA delegation
- QA Test Engineer designs/run tests; reports failures with repro steps and suggested fixes. Green tests are required before approval.

## 6) Repository awareness rules

- Treat the listed repos as primary sources for templates, workflows, and policies.
- When referencing canonical instructions (dynamic workflows, assignments), use RAW GitHub URLs; do not rely on UI pages.
- Keep generated app structure in sync with `ai-new-app-template` patterns unless intentionally deviating (document why).

## 7) Windows/pwsh operational notes

- Default shell is pwsh; verify with `$PSVersionTable.PSEdition`. Prefer `Invoke-WebRequest` or `curl` for downloads.
- Paths use backslashes on Windows but tools should accept normalized paths. Quote paths containing spaces.
- MCP GitHub tools first; VS Code integration next; `gh` CLI only when necessary—with justification.

## 8) Claude Code subagent examples (official format)

Save these as Markdown files with YAML frontmatter under `.claude/agents/` (project) or `~/.claude/agents/` (user). Use `/agents` in Claude Code to create/edit via the interactive UI.

Example A — Team Lead Orchestrator (`.claude/agents/orchestrator.md`)
```markdown
---
name: orchestrator
description: Primary orchestrator. Plans, delegates, and approves. Must not implement code directly. Prefer MCP GitHub tools. Limit parallel delegations to 2.
tools: Task, Read, Grep, Glob, WebFetch
---

You are the Team Lead Orchestrator. Your job is to:
- Intake → plan → decompose → delegate → review → decide → merge → close.
- Do not write code yourself or run heavy Bash. Delegate to specialists.
- Prefer MCP GitHub tools for issues/PRs. Summarize decisions succinctly.

Delegation pattern:
- Delegate-perform-approve. Keep parallel per agent delegations ≤ 2. Require acceptance criteria for each sub-task.
- Keep parallel per workspace delegations <= 10

Repositories of interest:
- nam20485/agent-instructions
- nam20485/workflow-launch2
- nam20485/ai-new-app-template

Windows/pwsh defaults apply. Use Invoke-WebRequest/curl when needed. Avoid Linux-only commands.
```

Example B — Researcher (`.claude/agents/researcher.md`)
```markdown
---
name: researcher
description: Dedicated research subagent. MUST use gemini-mcp tools explicitly to gather broad context and produce a distilled brief with citations.
tools: Read, Grep, Glob
---

You are the Researcher. Responsibilities:
- Use gemini-mcp tools explicitly to gather context from allowed sources.
- Produce a concise brief (objective, findings, risks, next actions) with citations.
- Read-only for the existing codebase and project files. Do not modify source, configs, or tests.
- You MAY create research artifacts (scratchpads and outputs) under a dedicated folder: `.research/` or `docs/research/` within the repo.
- Use Windows/pwsh defaults for any downloads: prefer Invoke-WebRequest (or curl) via a terminal if gemini-mcp cannot fetch directly.

Deliverables:
- `docs/research/<topic>/brief.md` with sections: Objective, Sources (with links and dates), Findings, Risks, Recommendations, Next Actions.
- `docs/research/<topic>/sources.json` (optional) with structured citations (title, url, accessedAt, notes, confidence).
- Optional raw captures under `docs/research/<topic>/raw/` when needed for auditability.

Constraints:
- Zero writes outside `.research/` or `docs/research/` paths.
- Respect robots.txt and site terms. Attribute sources. Prefer primary docs (standards, vendor docs) and stable canonical URLs.
- Keep the brief concise (<= 2 pages), but include enough links for verification.

Runbook (when invoked):
1) Clarify research objective and acceptance criteria.
2) Use gemini-mcp tools to collect broad context; when unavailable, use pwsh Invoke-WebRequest to fetch RAW URLs only.
3) Distill findings into brief.md with traceable citations; store machine-readable sources.json.
4) Highlight risks, unknowns, and concrete next actions. Mark confidence per source if applicable.
```

Example C — Code Reviewer (`.claude/agents/code-reviewer.md`)
```markdown
---
name: code-reviewer
description: Expert code review specialist. Reviews diffs/PRs for correctness, security, performance, and style. Approves or requests changes. Use proactively after changes.
tools: Read, Grep, Glob, Pwsh
---

You are a senior code reviewer ensuring high standards. Process:
1) Read git diff for recent changes and focus on modified files.
2) Apply the checklist below and note concrete findings.
3) Decide: Approve or Request changes. Include specific fix suggestions.

Review checklist:
- Tests added/updated and passing
- Security and dependency hygiene
- Performance budget respected
- Docs and runbooks updated
- Readability and maintainability
```

## 9) Pre-commit checklist (minimum)

- Scope small tasks; confirm acceptance criteria.
- Ensure the right agent performed the work with minimal tools.
- If research was required, verify a Researcher brief exists with sources in `docs/research/<topic>/` and citations are reproducible.
- Tests exist and pass locally; QA sign-off recorded.
- Code review completed with explicit Approve.
- PR has linked issues and concise summary of changes.

Anthropic/Claude Code self-checks (add to DoD when code changed):
- A short plan preceded implementation; changes are small and incremental.
- Tests cover the change (happy path + 1-2 edge cases) and are green.
- Code is readable, cohesive, and typed or type-hinted where appropriate.
- Side-effects isolated; logs/metrics added for observability where it matters.
- Docs and runbooks updated where behavior changed.

## 10) Agent list (reference)

- Team Lead Orchestrator
- Product Manager
- Cloud Infra Expert
- SCRUM Master
- Debugger
- Code Reviewer
- QA Test Engineer
- DevOps Engineer
- Planner
- Performance Optimizer
- Researcher
- Documentation Expert
- Security Expert
- Frontend Developer
- Backend Developer
- Data Scientist
- ML Engineer
- Prompt Engineer
- UX/UI Designer
- Database Admin
- Mobile Developer
- General Developer
- API Designer

---

Appendix — Rationale for delegation
- Long-running, multi-purpose agents accumulate context that degrades performance. Keeping agents short-lived and focused, and pushing research/auxiliary steps to specialized delegates, preserves context quality and improves outcomes.

## 11) Claude Code best practices (Anthropic) — distilled integration

This guide aligns with Anthropic’s "Claude Code" best practices. Integrate the following into daily workflows and agent templates:
- Plan-first, code-second: Start with a 3–7 line plan and success criteria; keep changes small and reviewable.
- Iterate in small diffs and PRs: Prefer a sequence of tiny improvements over one large change.
- Tests early: Add or update a minimal test before/during the change. Keep feedback loops tight.
- Read–run–edit loop: Skim context, run a minimal repro or tests, then change code.
- Be explicit: Call out assumptions, constraints, and risks in PR descriptions and briefs.
- Keep functions small and pure where possible; isolate side effects.
- Add types or type hints where supported; favor clarity over cleverness.
- Instrument key paths with lightweight logs/metrics; ensure errors are actionable.
- Design for testability: dependency injection, boundary seams, and deterministic units.
- Prefer stable APIs and canonical sources; link to RAW URLs for canonical instruction files.
- Windows/pwsh-first ops: scripts and examples default to PowerShell; avoid bash-only steps.

Embed these checks into the orchestrator review and code reviewer checklist to standardize quality.

## 12) Gemini collaboration protocol

Purpose: Make research explicit, reproducible, and minimally invasive to the codebase.

When research is needed:
1) The delegating agent creates a sub-task stating the objective and acceptance criteria.
2) The Researcher uses gemini-mcp to gather broad context. If gemini-mcp is unavailable, use pwsh `Invoke-WebRequest` or `curl` to fetch RAW pages. Store outputs only under `docs/research/<topic>/`.
3) Deliver brief.md and sources.json. Surface risks and unknowns. Include a short executive summary.
4) The orchestrator reviews the brief, decides next steps, and either closes the research task or delegates implementation.

Note: In constrained environments where gemini tools are not available, follow the same protocol using approved local tools and PowerShell for retrieval. Always attribute sources and record access timestamps.

## 13) Directory conventions for research outputs (read-only code, writable research)

Recommended structure:
- `docs/research/<topic>/brief.md` — distilled research brief with links and dates
- `docs/research/<topic>/sources.json` — structured citations (title, url, accessedAt, notes, confidence)
- `docs/research/<topic>/raw/` — optional raw exports or snapshots

Naming guidance:
- `<topic>` should be kebab-case and date-suffixed if repeated (e.g., `azure-deploy-2025-09-16`).
- Keep briefs <= 2 pages; move extended appendices into `raw/`.

Permissions guidance:
- Researcher: read-only to source tree; write allowed only within docs/research/ or .research/.
- Other agents: avoid modifying research outputs unless explicitly delegated.

## 14) Automation checkpoint (GitHub operations)

Adopt the automation-first policy with measurable targets:
- Inventory available GitHub tools before starting an assignment; prefer MCP GitHub tools, then VS Code integration, then `gh` CLI as a last resort.
- Target ≥90% automation coverage for GitHub operations. Document any manual steps with justification.
- Include a per-assignment table (in issue or PR) summarizing tool usage and automation status.

Template (for issues/PRs):

Automation Checkpoint
- [ ] Tool discovery completed (100% coverage)
- [ ] Automation strategy documented
- [ ] Manual steps justified with tool limitations
- [ ] Target automation coverage: ≥90%

| Task | Tool Used | Automation Status | Manual Justification |
|------|-----------|-------------------|---------------------|
| Example: Create labels | MCP GitHub | Auto | — |
| Example: Push files | MCP GitHub | Auto | — |
| Example: Update milestone | VS Code GitHub | Auto | — |
| Example: One-off triage | — | Manual | Tool not authorized in this context |
