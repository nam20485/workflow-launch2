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

## Local AI Instructions (**REQUIRED**)
Local AI instruction moduule files are located in the [local_ai_instruction_modules](../local_ai_instruction_modules) directory.

## Dynamic Workflow Orchestration (**REQUIRED**)
Agents MUST resolve dynamic workflows from the remote canonical repository. Do not use local mirrors.
[ai-dynamic-workflows.md](../local_ai_instruction_modules/ai-dynamic-workflows.md)

## Workflow Assignments (**REQUIRED**)
Agents MUST resolve workflow assignments (by shortId) from the remote canonical repository. Do not use local mirrors.
[ai-workflow-assignments.md](../local_ai_instruction_modules/ai-workflow-assignments.md)

## Terminal Commands (Optional)
Read before running any terminal commands, of if you need Github CL.I
- [ai-terminal-commands.md](../ocal_ai_instruction_modules/ai-initiate-new-repository-ops-notes.md)

## **Remote Repository with Main/Canonical AI Instruction Modules**

[nam20485/agent-instructions Repository](https://github.com/nam20485/agent-instructions/main)

The main set of AI instruction modules is located in this remote repository. It contains the following:
- Dynamic workflows
- Workflow assignments
- Main AI instruction modules

### Remote Repo Details

 Repository: nam20485/agent-instructions
- Full repo URL: https://github.com/nam20485/agent-instructions
- Branch: main
- Assignments directory: ai_instruction_modules/ai-workflow-assignments/
 - Active assignments index in this workspace: see `local_ai_instruction_modules/ai-workflow-assignments.md`

Single Source of Truth Policy:

- Dynamic workflow files (under `ai_instruction_modules/ai-workflow-assignments/dynamic-workflows/`) and workflow assignment files (under `ai_instruction_modules/ai-workflow-assignments/`) in the `nam20485/agent-instructions` repository are the ONLY authoritative sources for steps and acceptance criteria.
- Local golden files, cached plans, or mirrors must not be used to derive steps or acceptance criteria. Delete any such artifacts if present.
- Changes to dynamic workflow or assignment files in the remote canonical repository take effect immediately on subsequent runs.
- The orchestrator must always fetch and execute directly from the remote canonical URLs listed below.
