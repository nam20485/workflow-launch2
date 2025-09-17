# Claude Code Subagents

This project defines a minimal set of Claude Code subagents to support targeted delegation and automation-first workflows on Windows (PowerShell/pwsh).

- Project agents live under `.claude/agents/`.
- Format: Markdown with YAML frontmatter (see files for examples).
- Shell defaults: Windows, prefer PowerShell (pwsh). Avoid bash-only commands.
- Research tasks should be delegated to the Researcher (uses gemini-mcp tools).

Quick start:
1) In VS Code with Claude Code enabled, open the Agents panel (`/agents`).
2) The project-level agents will appear; select and use them in chats.
3) Use the Orchestrator to plan, delegate to specialized agents, and approve work.

Primary references:
- `scripts/agent-creation-rules.md` (authoring guide)
- https://github.com/nam20485/agent-instructions (canonical instruction modules)
