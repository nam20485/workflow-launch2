# Agent Improvement Plan

_Last updated: 2025-09-24_

## Context & Method
- Source requirements: `docs/improve-agents-rules.md`, Anthropic Claude Code best practices, Claude sub-agent docs, DEV.to custom agent framework notes, Superprompt agent directory, AWS Builder guidance.
- ULTRATHINK analysis performed; Gemini brainstorm tool unavailable in this environment (`spawn gemini ENOENT`), so recommendations synthesize referenced sources manually.
- Scope: refresh all definitions under `.claude/agents/` to meet ARFI cycle expectations (analyze, review, feedback, improve).

## Global Enhancements
- Expand every agent prompt to include structured sections: Mission, Success Criteria, Operating Procedure, Collaboration & Delegation, Tooling Rules, Deliverables & Reporting, Example Invocations, Failure Modes & Fallbacks.
- Introduce frontmatter metadata additions: `colorTag`, `maturityLevel`, `defaultParallelism`, and `toolingProfile` for quick visual cues inside Claude Code.
- Pre-register slash commands (stored in `CLAUDE.md`): `/plan-sprint`, `/analyze-diff`, `/generate-test-plan`, `/prompt-tune`, `/research-brief`, `/aws-arch-review`.
- Update global guardrails in `CLAUDE.md`: navigation map, repo heatmap, validation checklist, MCP inventory (Context7, DeepWiki, Microsoft Docs, Tavily), shell helpers, command cheat-sheets.
- Ensure `.claude/settings.json` tool allowlists pre-authorize `Edit`, `Write`, `Bash(git commit:*)`, `RunTests`, and vetted MCP research tools; document escalation flow for risky commands.
## Example Invocation Template
```
/agent <agent-name>
Mission: <specific objective>
Inputs: <linked files/issues>
Constraints: <timelines, quality gates>
Expected Deliverables: <artifacts>
Validation: <tests/builds>
```
- Store sample invocations alongside each agent definition to encourage consistent queries.

## Cluster Playbooks
### Leadership & Planning (orchestrator, product-manager, planner, scrum-master)
- **Mission upgrades:** Emphasize portfolio governance, dependency orchestration, backlog hygiene, stakeholder mediation.
- **Tooling:** `Read`, `Write`, `Edit`, `Task`, `Context7`, `DeepWiki`, `MicrosoftDocs`; orchestrator also keeps `WebFetch` fallback. Allow `RunTests` only when validating automation scripts.
- **Procedures:** Include sprint cadence checklists, decision logs, risk registers, and caps on concurrent delegations. Add explicit callouts to consult `qa-test-engineer` before declaring deliverables done.
- **Delegation:** Planner ↔ orchestrator for schedule alignment; product-manager ↔ researcher for market data; scrum-master escalates systemic blockers to orchestrator.
- **Examples:** sprint roadmap creation, scope clarification sessions, impediment resolution retrospectives.
### Implementation (developer, backend-developer, frontend-developer, mobile-developer, devops-engineer, cloud-infra-expert, performance-optimizer)
- **Mission upgrades:** Deliver production-ready increments with observability, security, and testing baked in.
- **Tooling:** `Read`, `Write`, `Edit`, `Bash`, `RunTests`, `Grep`, `Glob`, `Task`; add `Context7` for infra and platform docs; allow devops/cloud agents to use `MicrosoftDocs`, `DeepWiki`, `Tavily` for cloud patterns.
- **Procedures:** Mandate pre-change design sketch, TDD loop, logging/metrics checklist, and rollout/rollback notes.
- **Delegation:** Backend ↔ database-admin for schema work; frontend ↔ ux-ui-designer for accessibility; devops ↔ security-expert for secrets; cloud-infra ↔ orchestrator for cost/scope impacts; performance-optimizer loops in relevant implementer for fixes.
- **Examples:** API endpoint implementation, CI pipeline refactor, profiling session with regression tests.

### Data & ML (data-scientist, ml-engineer, database-admin)
- **Tooling:** `Read`, `Write`, `Edit`, `Bash`, `RunTests`, `Context7`, `DeepWiki`, `MicrosoftDocs`; add `Tavily` for dataset and compliance research.
- **Procedures:** Data validation gates, reproducible experiment tracking, governance/PII safeguards, migration playbooks.
- **Delegation:** Data-scientist consults product-manager for insights alignment; ml-engineer coordinates with devops for deployment; database-admin partners with backend-developer for ORM updates and security-expert for audit trails.
- **Examples:** churn analysis brief, model deployment checklist, partitioning strategy ADR.
### Quality & Safety (qa-test-engineer, code-reviewer, security-expert, debugger)
- **Tooling:** `Read`, `Write`, `Edit`, `Bash`, `RunTests`, `Task`, `Context7`, `DeepWiki`, `MicrosoftDocs`; security-expert additionally gets `Tavily` for CVE lookups.
- **Procedures:** Define regression planning templates, review rubrics, threat modeling checklists, incident response escalation paths.
- **Delegation:** QA signals coverage gaps to relevant implementer; code-reviewer escalates systemic design issues to orchestrator; security-expert coordinates with devops for remediation rollout; debugger hands off fixes once root cause isolated.
- **Examples:** regression suite expansion, security posture assessment, outage triage walkthrough.

### Enablement & Research (documentation-expert, prompt-engineer, researcher)
- **Tooling:** `Read`, `Write`, `Edit`, `Task`, `Context7`, `DeepWiki`, `MicrosoftDocs`, `Tavily`; prompt-engineer gains `ask-gemini` (when available) for prompt experiments.
- **Procedures:** Maintain documentation hierarchy, prompt iteration logs, research briefs with citations, and delegation triggers to implementation agents for changes.
- **Delegation:** Researcher feeds findings to product-manager/orchestrator; prompt-engineer collaborates with security-expert for red-teaming; documentation-expert syncs with developers for accuracy.
- **Examples:** migration guide draft, guardrail prompt tuning session, multi-source research digest.
### Experience & Design (ux-ui-designer)
- **Tooling:** `Read`, `Write`, `Edit`, `Task`, `Context7`, `DeepWiki`, `MicrosoftDocs`, `ReadMedia` for mockups; optionally `Tavily` for design system research.
- **Procedures:** Persona alignment, heuristic evaluation, accessibility audits, asset handoff workflows.
- **Delegation:** Coordinate with frontend-developer for implementation, product-manager for persona validation, qa-test-engineer for visual regression coverage.
- **Examples:** onboarding flow audit, component library alignment review, accessibility remediation plan.

## Delegation Mesh Highlights
- Embed delegation matrices inside each agent file summarizing who to consult, when to escalate, and fallback agents when primary is unavailable.
- Encourage cross-cluster loops: leadership ↔ implementation for capacity, implementation ↔ QA for validation, research ↔ prompt-engineer for prompt adjustments, design ↔ frontend for execution.

## Implementation & Validation Path
1. Apply updates to each agent Markdown file following the cluster guidance, ensuring consistent formatting and metadata.
2. Update `CLAUDE.md`, `.claude/settings.json`, and slash-command inventory.
3. Dry-run: invoke each agent with its sample command to confirm clarity; adjust tools if permission errors arise.
4. Log any issues (tool gaps, conflicting guidance) in the testing notes section; iterate until agents satisfy missions and guardrails.
