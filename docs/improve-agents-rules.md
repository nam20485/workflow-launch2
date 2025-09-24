# Improve Existing Agents

Review existing agents with Gemini and create plan to improve and optimize them. Then review plan and then apply changes.

Do another analysis, review, feedback, improve (ARFI) pass, this time take into acount specifically the following items in #Steps section.

# Steps

1. Use ULTRATHINK for this task.
2. Review all existing agent definitions.
3. Invoke Gemini tools to brainstorm about improvements and generate feedback.
4. Write feedback and review improvemtns to a plan doc.
5. For the brainstorm, use these suggestions and tips. Incorporate as many as you can that make sense:
        1. Incorporate best practices and advice from the following sites:
                1. https://www.anthropic.com/engineering/claude-code-best-practices
                2. https://dev.to/therealmrmumba/claude-codes-custom-agent-framework-changes-everything-4o4m
                3. https://docs.claude.com/en/docs/claude-code/sub-agents
                4. https://www.superprompt.com/blog/best-claude-code-agents-and-use-cases
                5. https://builder.aws.com/content/2wsHNfq977mGGZcdsNjlfZ2Dx67/unleashing-claude-codes-hidden-power-a-guide-to-subagents
        2. Incorporate this advice directly:
                1. Add any missing tools needed to accomplish their stated roles. 
	        2. For example, for agents with instructions to create or edit any files, make sure they have appropriate edit/writeable tools.
                        3. Add more delegation items to research agent for any agent whose instructions include thinking or need to think about code development, code improveme nts,code design and architecture, need to provide advice about best practices for a specific subject, or who can benefit from reading web sites with documentationabout their topics
                        4. allow more tools for web searching, and file/source code/project reading, and doc sites reading (context7, deepwiki, ms-docs, etc.)
                        5. EXisting agent definitions are too short. Expand to match examples given in the best practices site list.
                        6. Include Examples section to all agents.
6. Review the plan document and make necessary adjustments based on feedback.
7. Implement the changes as outlined in the plan document.
8. Test the improved agents to ensure they function as expected.
9. Document any issues encountered during testing and their resolutions.

## Research Inputs (2025-09-24)

- **Anthropic — Claude Code best practices:** Reinforce curated `CLAUDE.md` files with command cheat-sheets, style guardrails, and prompt tuning rituals; manage tool allowlists up front (pre-approve `Edit`, `Write`, safe `Bash` patterns); document custom shell helpers; ensure `gh` CLI + MCP servers are installed; and capture reusable slash-command templates for recurring flows.
- **Claude Code subagent docs:** Keep scopes narrow with action-oriented descriptions, craft rich system prompts with detailed procedures, constraints, and worked examples, gate tools by necessity, store agent files in version control, and provide explicit invocation strings plus proactive delegation guidance.
- **DEV Community custom agent framework deep dive:** Treat the suite as a modular orchestrator—ensure descriptive frontmatter metadata, enforce least-privilege permissions, plan for concurrent agent execution with graceful fallbacks, and use visual cues (e.g., agent color tags) for clarity.
- **Superprompt agent directory:** Offer curated invocation snippets, highlight specialization/coverage across the SDLC, and emphasize context isolation plus cross-agent collaboration patterns drawn from production-ready collections.
- **AWS Builder guide:** Source unreachable (`No such host is known`). Flag for follow-up once accessible so we can validate AWS-specific subagent deployment guidance.

## Gemini Brainstorm Status

- Attempted to call `gemini` CLI (`gemini -o json "Hello"`) to seed the brainstorm. The request reached authentication but failed with a Gemini API timeout after MCP discovery attempts (full report written outside the workspace). The CLI tooling is therefore unavailable in this environment.
- Proceeded with a manual synthesis informed directly by the referenced best-practice sources. The recommendations below capture the outcomes that would have been fed into Gemini.

## Upgrade Strategy Overview

- **Global guardrails:**
    - Expand `CLAUDE.md` hierarchy: add sections for repo navigation, test targets, MCP endpoints, approval policies, and quickstart command references.
    - Update tool allowlist defaults: pre-approve `Edit`, `Write`, `Bash(git commit:*)`, `RunTests`, and MCP read-only tools; document escalation flow for riskier commands.
    - Register reusable slash commands (e.g., `/analyze-diff`, `/generate-test-plan`, `/aws-arch-review`) backed by stored prompt templates.
    - Ensure MCP server inventory (Context7, DeepWiki, Microsoft Docs, Tavily) is connected so research/escalation instructions remain actionable.
    - Adopt color tags in frontmatter metadata to speed subagent recognition inside Claude Code.

- **Prompt architecture:** Every agent file should be refactored to include the following sections: Mission, Success Criteria, Operating Procedure, Tooling Rules, Collaboration & Delegation, Deliverables & Formatting, Example Invocations, and Failure Modes/Fallbacks.

- **Delegation mesh:** Strengthen explicit hand-offs—especially to `researcher`, `prompt-engineer`, and `qa-test-engineer`—when agents require external research, prompt adjustments, or validation coverage.

## Agent Cluster Plans

### Leadership & Planning (orchestrator, product-manager, planner, scrum-master)
- **orchestrator:**
    - Add `Write`/`Edit` to document plans and checkpoint instructions.
    - Expand prompt with governance guardrails (capacity constraints, DoD enforcement, incident escalation) and a playbook for coordinating multiple subagents in parallel.
    - Include delegation tree (e.g., delegate research to `researcher` before scheduling, engage `devops-engineer` for deployment blockers).
    - Example invocation: “Use orchestrator to assemble a two-sprint delivery plan for the GPU monitoring feature, coordinating backend/frontend/docs agents.”
- **product-manager:**
    - Provide market/persona research workflow, acceptance-criteria templates, and requirement traceability matrix instructions.
    - Grant `Read`, `Write`, `Edit`, `Web` (context7/deepwiki) for competitive analysis.
    - Delegate technical feasibility questions to `backend-developer`/`frontend-developer`; escalate risk to `orchestrator`.
    - Example invocation: “Use product-manager to refine the problem statement for the support assistant epic and draft MoSCoW priorities.”
- **planner:**
    - Incorporate backlog grooming checklist, RICE scoring flow, and schedule risk heuristics.
    - Tools: `Read`, `Write`, `Edit`, `RunTests` (for verifying automated plan checks) not required? but safe to include? Possibly skip `RunTests`. Instead ensure they can read. Maybe keep to `Read`, `Write`, `Edit`.
    - Delegation to `scrum-master` for ceremonies, `product-manager` for priority shifts.
    - Example invocation: “Use planner to break down the authentication refactor into granular deliverables with estimates.”
- **scrum-master:**
    - Add sections for ceremony facilitation, impediment tracking, and metrics (velocity, burndown).
    - Tools: `Read`, `Write`, `Edit` for updating runbooks; `Web` for pulling agile resources? Maybe restful.
    - Provide explicit `Delegate to orchestrator` for systemic blockers, `qa-test-engineer` for quality gates.
    - Example invocation: “Use scrum-master to prepare the sprint retrospective and identify impediments requiring follow-up tickets.”

### Build & Implementation (developer, backend-developer, frontend-developer, mobile-developer, devops-engineer, cloud-infra-expert, database-admin, ml-engineer, performance-optimizer)
- **developer (generalist):**
    - Upgrade tools to `Read, Write, Edit, Bash, Grep, Glob, RunTests`.
    - Prompt sections covering coding standards, small-batch diffs, and post-change validation.
    - Delegation triggers: escalate architecture to `backend-developer`, UI to `frontend-developer`, doc updates to `documentation-expert`.
    - Example invocation: “Use developer to implement minor utility helpers and update unit tests.”
- **backend-developer:**
    - Add API design guidelines, error-handling patterns, persistence considerations, cross-service contract checks.
    - Tools: `Read, Write, Edit, Bash, RunTests, Grep, Glob` plus optional `Web` for API docs.
    - Delegation: call `database-admin` for schema migrations, `security-expert` for auth changes.
    - Example: “Use backend-developer to implement the `/billing/invoices` endpoint with pagination and validation.”
- **frontend-developer:**
    - Include responsive design checklist, accessibility heuristics (WCAG), state-management patterns.
    - Tools: `Read, Write, Edit, Bash`, `RunTests` (component tests), `ReadMedia`? maybe not necessary.
    - Delegation to `ux-ui-designer` for design alignment, `qa-test-engineer` for visual regression coverage.
    - Example: “Use frontend-developer to build the invoice table React component with sorting and accessibility.”
- **mobile-developer:**
    - Document platform specifics (iOS vs Android), build/test commands, performance budgets.
    - Tools: `Read, Write, Edit, Bash`, `RunTests` for `gradlew`/`xcodebuild` invocations.
    - Delegation to `performance-optimizer` for profiling, `qa-test-engineer` for device matrix.
    - Example: “Use mobile-developer to add offline caching for the notifications screen.”
- **devops-engineer:**
    - Add IaC conventions, deployment pipelines, rollback playbooks.
    - Tools: `Read, Write, Edit, Bash`, `RunTests` (for pipeline dry runs), optional `Web` for docs.
    - Delegation to `cloud-infra-expert` for large-scale architecture, `security-expert` for secrets handling.
    - Example: “Use devops-engineer to convert the CI workflow to reusable composite actions.”
- **cloud-infra-expert:**
    - Provide multi-cloud reference architectures, networking/security baselines, cost analysis procedure.
    - Tools: `Read, Write, Edit, Bash`, plus `Web` for provider docs, `Context7` for infrastructure references.
    - Delegation to `devops-engineer` for pipeline integration, `security-expert` for CIS compliance.
    - Example: “Use cloud-infra-expert to design a resilient GPU workload cluster on AWS/GCP.”
- **database-admin:**
    - Add migration workflow, backup/restore runbooks, query performance tactics.
    - Tools: `Read, Write, Edit, Bash`, `RunTests` for DB integration tests.
    - Delegation to `backend-developer` for ORM integration, `security-expert` for data governance.
    - Example: “Use database-admin to design a partitioning strategy for the events table.”
- **ml-engineer:**
    - Expand prompt with model lifecycle (data prep, training, evaluation, deployment), MLOps integration, bias monitoring.
    - Tools: `Read, Write, Edit, Bash`, `RunTests`, `Web` for research references, `Context7` for ML docs.
    - Delegation to `data-scientist` for exploratory analysis, `devops-engineer` for deployment pipeline.
    - Example: “Use ml-engineer to productionize the anomaly detection model with batch scoring.”
- **performance-optimizer:**
    - Provide profiling checklist (CPU/memory/I/O), benchmarking harness instructions, concurrency audits.
    - Tools: `Read, Write, Edit, Bash`, `RunTests` for perf tests.
    - Delegation to relevant implementers (backend/front) for fixes.
    - Example: “Use performance-optimizer to profile the event ingestion service under 10k TPS load.”

### Data & Analysis (data-scientist)
- **data-scientist:**
    - Expand to include data validation steps, dashboard creation guidelines, compliance (PII handling).
    - Tools: `Read, Write, Edit, Bash`, `RunTests`, plus `Web` for dataset docs.
    - Delegation to `ml-engineer` for model packaging, `product-manager` for insight alignment.
    - Example: “Use data-scientist to analyze churn drivers and propose instrumentation.”

### Quality & Safety (qa-test-engineer, code-reviewer, security-expert, debugger)
- **qa-test-engineer:**
    - Add test strategy templates (unit/integration/e2e), coverage reporting, flake triage.
    - Tools: `Read, Write, Edit, Bash`, `RunTests`, `Web` for testing frameworks.
    - Delegation to `developer` for fixes, `performance-optimizer` for load testing.
    - Example: “Use qa-test-engineer to author regression tests for the billing workflow.”
- **code-reviewer:**
    - Enrich checklist with domain-specific items (compliance, observability) and instructions for summarizing review outcome.
    - Tools: add `Edit` for applying small safe fixes; optionally `Write` for review notes.
    - Delegation to `security-expert`, `qa-test-engineer`, `documentation-expert` as needed.
    - Example: “Use code-reviewer to audit the new OAuth callback flow for security regressions.”
- **security-expert:**
    - Add threat modeling steps, compliance mapping (SOC2, HIPAA), secrets management playbook.
    - Tools: `Read, Write, Edit, Bash`, `Web` for CVE research, `Context7` for security docs.
    - Delegation to `devops-engineer` for remediation deployment, `product-manager` for policy updates.
    - Example: “Use security-expert to analyze new S3 bucket policies for least privilege.”
- **debugger:**
    - Expand with structured debugging tree, log instrumentation guidance, reproduction matrix.
    - Tools: `Read, Write, Edit, Bash`, `RunTests`.
    - Delegation to owning implementer once fix path known, escalate to `performance-optimizer` for perf issues.
    - Example: “Use debugger to triage the intermittent timeout in the payments service.”

### Enablement & Knowledge (documentation-expert, prompt-engineer, researcher)
- **documentation-expert:**
    - Add doc templates (README, ADR, runbook), info-architecture checklist, voice/tone guidelines.
    - Tools: `Read, Write, Edit`, `Web` for style guides.
    - Delegation to `product-manager` for audience alignment, `qa-test-engineer` for release notes validation.
    - Example: “Use documentation-expert to draft the quickstart guide for the workflow launch app.”
- **prompt-engineer:**
    - Include prompt experimentation framework, evaluation rubric, safety guardrails tuning.
    - Tools: `Read, Write, Edit`, `Web`, `Context7` for prompt research.
    - Delegation to `researcher` for source gathering, `security-expert` for red-teaming prompts.
    - Example: “Use prompt-engineer to refactor the orchestrator’s system prompt with stronger guardrails.”
- **researcher:**
    - Replace deprecated `WebFetch` tool with MCP equivalents (Context7, DeepWiki, Microsoft Docs, Tavily) plus `Read`, `Write` for briefs.
    - Expand brief template with timeline of findings, stakeholder impact, and recommended follow-on agents.
    - Delegation to `product-manager`/`orchestrator` for alignment, `prompt-engineer` for guardrail updates.
    - Example: “Use researcher to summarize AWS Bedrock subagent capabilities and cite official docs.”

### Experience & Design (ux-ui-designer)
- **ux-ui-designer:**
    - Add discovery checklist (personas, journey maps), accessibility/heuristic evaluation steps, design asset handoff instructions.
    - Tools: `Read, Write, Edit`, `Web` for design systems, optionally `ReadMedia` for mockups.
    - Delegation to `frontend-developer` for implementation alignment, `product-manager` for persona validation.
    - Example: “Use ux-ui-designer to audit the onboarding flow against WCAG AA and propose improvements.”

## Execution Next Steps

1. Refactor agent files following the above cluster guidance, updating frontmatter, tool lists, and prompt bodies.
2. Extend `CLAUDE.md` and slash-command inventory to match the global guardrails.
3. Update tool allowlists (`.claude/settings.json`) and confirm MCP server connectivity.
4. Run dry-run tests: invoke each agent with the suggested example prompts to validate behavior.
5. Revisit AWS Builder article when available to incorporate any region-specific deployment practices.
