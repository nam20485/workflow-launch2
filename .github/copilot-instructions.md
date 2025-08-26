# Instructions (Copilot)

## Where to Find Your Instructions
- Your custom instructions are located in the files inside of the [nam20485/agent-instructions](https://github.com/nam20485/agent-instructions/tree/main) repository
- Look at the files in the `main` branch
- Start with your core instructions (linked below)
- Then follow the links to the other instruction files in that repo as required or needed.
- You will need to follow the links and read the files to understand your instructions

## How to Read Your Instructions
- Read the core instructions first
- Then follow the links from the core instructions to the other instruction files
- Some files are **REQUIRED** and some are **OPTIONAL**
- Files marked **REQUIRED** are ALWAYS active and so must be followed and read
- Otherwise files are optionally active based on user needs and your assigned roles and workflow assignments

## Core Instructions (**REQUIRED**)
[ai-core-instructions.md](https://github.com/nam20485/agent-instructions/blob/main/ai_instruction_modules/ai-core-instructions.md)

## Dynamic Workflow Orchestration (**REQUIRED**)
Agents MUST resolve dynamic workflows from the remote canonical repository. Do not use local mirrors.

Single Source of Truth Policy:

- Dynamic workflow files (under `ai_instruction_modules/ai-workflow-assignments/dynamic-workflows/`) and workflow assignment files (under `ai_instruction_modules/ai-workflow-assignments/`) in the `nam20485/agent-instructions` repository are the ONLY authoritative sources for steps and acceptance criteria.
- Local golden files, cached plans, or mirrors must not be used to derive steps or acceptance criteria. Delete any such artifacts if present.
- Changes to dynamic workflow or assignment files in the remote canonical repository take effect immediately on subsequent runs.
- The orchestrator must always fetch and execute directly from the remote canonical URLs listed below.

- Repository: nam20485/agent-instructions
- Full repo URL: https://github.com/nam20485/agent-instructions
- Branch: main
- Dynamic workflows directory: ai_instruction_modules/ai-workflow-assignments/dynamic-workflows/
- Active workflows index in this workspace: see `remote_ai_instruction_modules/ai-dynamic-workflows.md`

Active dynamic workflows (alias → canonical file):

- initiate-new-repo → ai_instruction_modules/ai-workflow-assignments/dynamic-workflows/initiate-new-repo.md
	- GitHub UI: https://github.com/nam20485/agent-instructions/blob/main/ai_instruction_modules/ai-workflow-assignments/dynamic-workflows/initiate-new-repo.md
	- Raw URL:   https://raw.githubusercontent.com/nam20485/agent-instructions/main/ai_instruction_modules/ai-workflow-assignments/dynamic-workflows/initiate-new-repo.md

Reference: `remote_ai_instruction_modules/ai-dynamic-workflows.md`

## Assignments & Orchestration (**REQUIRED**)
Agents MUST resolve workflow assignments (by shortId) from the remote canonical repository. Do not use local mirrors.

Single Source of Truth Policy:

- Workflow assignment definition files in `nam20485/agent-instructions` are authoritative. Execute steps strictly from these files; do not synthesize steps from dynamic workflow files or local artifacts.
- Acceptance Criteria in the assignment files are mandatory gates for completion.
- Any local mirrors, cached plans, or goldens must be ignored and may be removed to avoid drift.

- Repository: nam20485/agent-instructions
- Full repo URL: https://github.com/nam20485/agent-instructions
- Branch: main
- Assignments directory: ai_instruction_modules/ai-workflow-assignments/
- Active assignments index in this workspace: see `remote_ai_instruction_modules/ai-workflow-assignments.md`

Active assignment shortIds (shortId → canonical file):

- initiate-new-repository → ai_instruction_modules/ai-workflow-assignments/initiate-new-repository.md
	- GitHub UI: https://github.com/nam20485/agent-instructions/blob/main/ai_instruction_modules/ai-workflow-assignments/initiate-new-repository.md
	- Raw URL:   https://raw.githubusercontent.com/nam20485/agent-instructions/main/ai_instruction_modules/ai-workflow-assignments/initiate-new-repository.md

Reference: `remote_ai_instruction_modules/ai-workflow-assignments.md`

