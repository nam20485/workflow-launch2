# Agent Instructions Catalog

This is a curated quick-reference for the most relevant instruction modules used by this repo. For the full set, see the agent-instructions repository main branch.

- Canonical source: https://github.com/nam20485/agent-instructions/tree/main

## Core modules

- Core AI instructions
	- Title: Core AI Instructions
	- Path: ai_instruction_modules/ai-core-instructions.md
	- URL: https://github.com/nam20485/agent-instructions/blob/main/ai_instruction_modules/ai-core-instructions.md
	- Notes: Global rules, roles, content policy links, and workflow guardrails.

- Orchestrate Dynamic Workflow (spec)
	- Title: Orchestrator Guardrails and Execution Algorithm
	- Path: ai-workflow-assignments/orchestrate-dynamic-workflow.md
	- URL: https://github.com/nam20485/agent-instructions/blob/main/ai-workflow-assignments/orchestrate-dynamic-workflow.md
	- Notes: Assignment-first execution, resolution trace, acceptance-criteria gating, and run report schema.

## Dynamic workflows (routing)

- initiate-new-repo
	- Path: ai-workflow-assignments/dynamic-workflows/initiate-new-repo.md
	- URL: https://github.com/nam20485/agent-instructions/blob/main/ai-workflow-assignments/dynamic-workflows/initiate-new-repo.md
	- Delegates: [initiate-new-repository]
	- Passes context: yes
	- Notes: Thin wrapper that forwards inputs to the terminal assignment.

## Assignments (terminal specs)

- initiate-new-repository
	- Path: ai-workflow-assignments/initiate-new-repository.md
	- URL: https://github.com/nam20485/agent-instructions/blob/main/ai-workflow-assignments/initiate-new-repository.md
	- Acceptance Criteria (Definition of Done):
		- New GitHub repo created from template (public, AGPL).
		- Provided app_plan_docs copied into docs/ of new repo.
		- GitHub Project (Basic Kanban) created, named same as repo.
		- Repo labels imported from .labels.json via scripts/import-labels.ps1.
		- Milestones created via scripts/create-milestones.ps1.
		- Rename devcontainer/workspace artifacts: .devcontainer name -> <repo>-devcontainer; *.code-workspace -> <repo>.code-workspace.
	- Detailed steps: Mirrors the criteria and includes known-good gh/pwsh command patterns.

## Known-good command examples

- Working command examples (gh/pwsh)
	- Path: ai-working-command-examples.md
	- URL: https://github.com/nam20485/agent-instructions/blob/main/ai-working-command-examples.md
	- Notes: Use these patterns when instantiating the plan into commands.

## Local mapping/index (in this repo)

- Local assignment index
	- Path: local_ai_instructions/assignment-index.json
	- Role: Minimal map of dynamic workflows → terminal assignments, with acceptance criteria and step templates for the assignments we actually run from this repo.
	- Upstream: Keep in sync with the canonical files above.
