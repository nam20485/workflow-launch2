Do another analysis, review, feedback, improve (ARFI) pass, this time take into acount specifically the following items:

1. THINK DEEPLY for this task
2. Use these suggestions and tips from agents from Anthropic. Incporporate as many as you can that make sense.
https://www.anthropic.com/engineering/claude-code-best-practices
3. Collaborate with Gemini (1. /prompt-gemini-cli prompt or if that doens't work brainstorm/consulr via gemini-mcp server tools)
4. Researcher example: readonly for existing code or other project files, but allowed to create scratchpads or docs, or other files related to the task she's ask to do
   1. The researcher should be able to create new files for its research output, such as `brief.md` and `sources.json`.
   2. allow more tools for web searching, and file/source code/project reading, and doc sites reading (context7, deepwiki, ms-docs, etc.)

---

# Custom Agents Authoring Guide (Claude + Gemini)

This document defines how to design and configure a suite of Claude custom agents (Claude Code subagents) that collaborate using targeted delegation and a minimal toolset to build production-ready applications from templates. It incorporates explicit research delegation to Gemini (via gemini-mcp), Windows/pwsh operational defaults, and repository-aware behavior.

Assumptions and scope
- Agents are Claude Code subagents defined as Markdown files with YAML frontmatter, stored at project level in `.claude/agents/` or at user level in `~/.claude/agents/` (project subagents take precedence). See Anthropic docs: Claude Code settings → Subagent configuration and Subagents.
- Research tasks delegate to a dedicated Researcher subagent that explicitly uses the Gemini MCP toolchain.
- Operating environment defaults to Windows with PowerShell (pwsh) shell; avoid any bash-only assumptions.
- GitHub automation should prefer MCP GitHub tools first; use VS Code integration next; gh CLI as a last resort.
- This guide defines enforceable patterns and example subagent files in the official format.

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
- SCRUM Master / Planner: Convert goals into milestones/epics/tasks; ensure cadence and definition-of-done are applied.

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
- delegate → perform → approve: A delegating agent issues a targeted sub-task, receives deliverables, evaluates, and either approves or requests iteration. Keep parallel delegations low (1–2 max) unless the task is embarrassingly parallel.

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
```
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
- Delegate-perform-approve. Keep parallel delegations ≤ 2. Require acceptance criteria for each sub-task.

Repositories of interest:
- nam20485/agent-instructions
- nam20485/workflow-launch2
- nam20485/ai-new-app-template

Windows/pwsh defaults apply. Use Invoke-WebRequest/curl when needed. Avoid Linux-only commands.
```

Example B — Researcher (`.claude/agents/researcher.md`)
```
---
name: researcher
description: Dedicated research subagent. MUST use gemini-mcp tools explicitly to gather broad context and produce a distilled brief with citations.
tools: WebFetch, Read, Grep, Glob
---

You are the Researcher. Responsibilities:
- Use gemini-mcp tools explicitly to gather context from allowed sources.
- Produce a concise brief (objective, findings, risks, next actions) with citations.
- Avoid code changes or repo writes; deliver artifacts as brief.md and sources.

Deliverables:
- brief.md with sections: Objective, Sources (with links), Findings, Risks, Recommendations.
- sources.json (optional) with structured citations.
```

Example C — Code Reviewer (`.claude/agents/code-reviewer.md`)
```
---
name: code-reviewer
description: Expert code review specialist. Reviews diffs/PRs for correctness, security, performance, and style. Approves or requests changes. Use proactively after changes.
tools: Read, Grep, Glob, Bash
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
- If research was required, verify a Researcher brief exists with sources.
- Tests exist and pass locally; QA sign-off recorded.
- Code review completed with explicit Approve.
- PR has linked issues and concise summary of changes.

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
