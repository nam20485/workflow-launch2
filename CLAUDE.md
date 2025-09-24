# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **workflow launch repository** that orchestrates dynamic AI workflows and manages project templates. The main component is the **Advanced Memory System** - a sophisticated agentic memory system combining GraphRAG (graph-based retrieval augmented generation) with persistent memory management (Mem0), implemented as a Model Context Protocol (MCP) server.

## Shell Environment & Important Rules

- **Shell**: PowerShell (pwsh) on Windows - DO NOT assume bash
- **Web Fetch**: Disabled - use PowerShell `Invoke-WebRequest` or `curl` commands instead
- **Parallel Downloads**: Create PowerShell scripts for multiple file downloads
- Always detect shell type before running commands

## Repository Structure

```
workflow-launch2/
├── dynamic_workflows/           # Dynamic workflow implementations (created as needed)
│   └── [project-name]/         # Individual project repositories cloned here
├── scripts/                    # PowerShell automation scripts
│   ├── initiate-new-repo.ps1  # Complete repository creation orchestrator
│   ├── create-repo-with-plan-docs.ps1  # Repository with planning docs
│   ├── import-labels.ps1       # GitHub labels automation
│   ├── create-milestones.ps1   # Project milestone creation
│   ├── update-remote-indices.ps1  # Remote instruction synchronization
│   ├── common-auth.ps1         # Shared GitHub authentication
│   ├── query.ps1               # General query utilities
│   ├── validate-toolset.ps1    # AI toolset validation
│   └── init-template-repo.ps1  # Template initialization
├── docs/                       # Project documentation templates
├── local_ai_instruction_modules/ # Local AI workflow instructions
│   ├── ai-dynamic-workflows.md # Dynamic workflow orchestration
│   ├── ai-workflow-assignments.md # Workflow assignment resolution
│   ├── ai-terminal-commands.md # Terminal command guidance
│   ├── ai-tools-and-automation.md # Tools and automation protocol
│   └── toolset.selected.json  # Currently selected AI tools (126 tools)
├── .github/                    
│   ├── copilot-instructions.md # Remote instruction system config
│   └── README.md               # GitHub-specific documentation
├── .gemini/GEMINI.md          # Gemini AI configuration
├── global.json                # Global configuration
└── developer-pwsh.ps1         # Developer PowerShell utilities
```

## AI Instruction System

### Core Architecture
- **Remote Canonical Source**: `nam20485/agent-instructions` repository
- **Single Source of Truth**: Dynamic workflows MUST be fetched from remote
- **Local Instructions**: Located in [local_ai_instruction_modules](./local_ai_instruction_modules/)
- **URL Translation Required**: GitHub UI → RAW URLs

### URL Translation Rule (CRITICAL)
```
FROM: https://github.com/nam20485/agent-instructions/blob/main/<path>
TO:   https://raw.githubusercontent.com/nam20485/agent-instructions/main/<path>
```

### Required Instruction Files
1. **Core Instructions**: Always active and must be followed
2. **Dynamic Workflows**: Fetched from remote canonical repository
3. **Workflow Assignments**: Resolved by shortId from remote
4. **Terminal Commands**: Optional, read before running any terminal commands

## Development Commands

### General Repository Operations
```powershell
# Create new repository with full setup
./scripts/initiate-new-repo.ps1 -RepoName "project-name"

# Import GitHub labels from configuration
./scripts/import-labels.ps1 -RepoName "owner/repo"

# Validate current AI toolset configuration
./scripts/validate-toolset.ps1
```

### Advanced Memory System (Python/uv) - When Available
```powershell
# Navigate to project (if cloned in dynamic_workflows)
cd dynamic_workflows/advanced-memory

# Install dependencies (including dev tools)
uv sync --group dev

# Run full test suite with coverage
uv run pytest --cov=src/advanced_memory --cov-report=html

# Run single test
uv run pytest tests/test_memory_provider.py::TestMemoryProvider::test_add_memory

# Code quality tools
uv run black src/ tests/        # Format code
uv run isort src/ tests/        # Sort imports  
uv run mypy src/                # Type checking
uv run flake8 src/ tests/       # Linting

# Start MCP server locally
uv run python src/advanced_memory/main.py
```

### Docker Operations
```powershell
# Start complete stack (Neo4j + MCP server)
docker-compose up -d

# View service logs
docker-compose logs -f mcp-server
docker-compose logs -f neo4j

# Scale MCP server instances
docker-compose up --scale mcp-server=3

# Rebuild after changes
docker-compose up --build
```

### Infrastructure (Terraform)
```powershell
cd infrastructure
terraform init
terraform plan
terraform apply
```

### Repository Creation Workflow
```powershell
# Complete end-to-end repository creation
./scripts/initiate-new-repo.ps1 -RepoName "my-new-repo"

# Dry run mode for testing
./scripts/initiate-new-repo.ps1 -RepoName "my-new-repo" -DryRun -Verbose

# Skip specific steps
./scripts/initiate-new-repo.ps1 -RepoName "my-new-repo" -SkipLabels -SkipMilestones

# Other repository automation scripts
./scripts/import-labels.ps1         # Import GitHub labels
./scripts/create-milestones.ps1     # Create project milestones
./scripts/create-repo-with-plan-docs.ps1  # Create repo with planning docs
./scripts/update-remote-indices.ps1 # Update remote instruction indices
```

## Advanced Memory System Architecture

### Core Components
- **MCP Server**: FastAPI-based HTTP server with Server-Sent Events (SSE)
- **GraphRAG Knowledge**: Neo4j graph database with community detection
- **Mem0 Memory**: Multi-type persistent memory (working, episodic, factual, semantic)
- **Provider Pattern**: Abstracted knowledge and memory providers

### MCP Protocol Tools
1. **query_knowledge_base**: Global/local GraphRAG search with confidence scoring
2. **add_interaction_memory**: Store conversation turns with metadata
3. **search_user_memory**: Query user-specific memories with relevance scoring
4. **get_user_profile**: Synthesize user profiles from memory patterns

### Server Endpoints
- Health Check: `GET /health`
- Available Tools: `GET /tools`
- Tool Execution: `POST /mcp/call`
- Real-time Events: `GET /sse`

### Environment Requirements
```
OPENAI_API_KEY=required
NEO4J_URI=bolt://localhost:7687
NEO4J_PASSWORD=required
MEM0_API_KEY=optional
MCP_SERVER_PORT=8080
LOG_LEVEL=INFO
```

### Neo4j Configuration
Requires APOC and Graph Data Science plugins with specific memory allocation:
```yaml
NEO4J_PLUGINS=["apoc", "graph-data-science"]
NEO4J_dbms_memory_heap_max__size=2G
NEO4J_dbms_memory_pagecache_size=1G
```

## Testing Strategy

### Test Structure
- **Unit Tests**: Provider and model validation
- **Integration Tests**: MCP server endpoint testing with async support
- **Coverage Requirements**: HTML reports with line-by-line coverage
- **Async Testing**: Full pytest-asyncio integration

### Test Commands
```powershell
# All tests with coverage
uv run pytest --cov=src/advanced_memory --cov-report=html

# Specific test file
uv run pytest tests/test_mcp_server.py -v

# Test with output
uv run pytest -s tests/test_knowledge_provider.py
```

## Code Quality Standards

### Formatting & Linting
- **Black**: Line length 88, Python 3.11+ target
- **isort**: Black profile for import organization
- **mypy**: Strict type checking with untyped function disallowing
- **flake8**: Comprehensive linting
- **pytest**: Async mode auto-detection

### Pre-commit Integration
All quality tools integrated with pre-commit hooks for automated checking.

## PowerShell Automation Scripts

### Repository Orchestration
- **initiate-new-repo.ps1**: Complete repository creation workflow
  - Creates GitHub project and repository from template
  - Clones to workspace-local `dynamic_workflows/` directory
  - Imports labels and creates milestones
  - Commits and pushes seeded content
  - Runs post-clone initialization

### Safety Features
- **Workspace-anchored cloning**: Prevents wrong-root placement
- **Idempotent operations**: Safe to re-run without duplication
- **DryRun mode**: Test operations without making changes
- **Path validation**: Refuses unsafe clone destinations

### Common Gotchas
- **Clone destination**: Always uses workspace-relative `dynamic_workflows/`
- **Branch handling**: Template repos may default to `development` branch  
- **JSON handling**: Use PowerShell `ConvertFrom-Json` instead of jq
- **File paths with spaces**: Use `-LiteralPath` parameter

## Available PowerShell Scripts

### Core Repository Management
- **initiate-new-repo.ps1**: Complete repository creation orchestrator with GitHub integration
- **create-repo-with-plan-docs.ps1**: Repository creation with planning documentation
- **import-labels.ps1**: Automated GitHub labels import from JSON configuration
- **create-milestones.ps1**: Project milestone creation and management
- **update-remote-indices.ps1**: Synchronize remote instruction indices

### Utilities & Authentication
- **common-auth.ps1**: Shared authentication functions for GitHub operations
- **query.ps1**: General-purpose query and search utilities
- **validate-toolset.ps1**: Validation for AI toolset configurations
- **init-template-repo.ps1**: Template repository initialization

### Script Usage Pattern
```powershell
# Most scripts support common parameters
-DryRun          # Test mode without making changes
-Verbose         # Detailed operation logging
-WhatIf         # Preview actions without execution
```