scripts/setup-environment.sh (Linux / WSL / devcontainer)
------------------------------------------------------

What it does
- Installs minimal system packages used by development and CI (git, python3, build tools, curl, jq, tree, htop, etc.).
- Installs NVM and pins Node.js from `.nvmrc` or `NODE_VERSION_PIN`.
- Enables Corepack and prepares pnpm/yarn when possible (reads `package.json` packageManager field or PNPM/YARN version pins).
- Installs optional developer tooling: Playwright (and browsers), Google Cloud CLI, GitHub CLI, Terraform, Ansible, global npm CLIs and .NET SDK workloads.

Run it
```bash
bash scripts/setup-environment.sh
```

Quick minimal run (skip large optional installs such as Playwright browsers):

```bash
SETUP_MINIMAL=1 bash scripts/setup-environment.sh
```

Verification
```bash
/tmp/show-env.sh
# or check individually
node --version
npm --version
python --version
pwsh --version
gcloud --version
gh --version
terraform --version
ansible --version
dotnet --version
npx -y playwright@latest --version
```

Notes & troubleshooting
- Node pinning: the script prefers `NODE_VERSION_PIN` then `.nvmrc` in repository root. This repo includes `.nvmrc` pinned to `22.18.0`.
- Corepack/pnpm: The script will try to enable Corepack and prepare pnpm/yarn. If pnpm is not available, set `PNPM_VERSION_PIN` or add `"packageManager": "pnpm@<version>"` to `package.json`.
- If `nvm` isn't found after install, re-open your shell or source it:

```bash
. $HOME/.nvm/nvm.sh
nvm use
```

- For permission errors on Linux run the script with sudo (the script auto-uses `sudo` when available for system package installs).
- On Windows use `scripts/setup-environment.ps1` with an elevated PowerShell session when necessary.

Using `.env.tools` (repo-level pins)
-----------------------------------

The repository supports a canonical `.env.tools` file at the repo root that contains exact, patch-level pins for tools used by the setup scripts. The setup scripts will load this file early and export the variables so installs are deterministic.

Examples of keys the scripts look for:
- `NODE_VERSION_PIN` — exact Node.js version (e.g., `22.18.0`)
- `NPM_VERSION_PIN` — optional exact npm version
- `PNPM_VERSION_PIN`, `YARN_VERSION_PIN` — versions Corepack will prepare
- `DOTNET_VERSION_PIN`, `DOTNET_CHANNEL`, `DOTNET_QUALITY` — for `dotnet-install` behavior

You can either commit a canonical `.env.tools` file (recommended for reproducibility) or commit `.env.tools.example` and have developers copy it to `.env.tools` locally. See the repo root `.env.tools` for the current pinned values.

Why is `uv` marked optional?
--------------------------------
The `uv` tool (https://astral.sh/uv/) is a small Python-based helper/dependency manager the scripts may install into the user's local bin. It's marked optional for a few reasons:

- `uv` is not required for the core language runtimes (Node, .NET, Python) or essential cloud CLIs; it's a convenience tool that some workflows use to manage small package installs.
- `uv` installation can be skipped for minimal or CI-focused setups to save time and avoid adding extra user-local binaries when they are unnecessary. Set `SETUP_MINIMAL=1` to skip it.
- The installer is a single-file script that may fail on very locked-down environments; leaving it optional prevents the whole setup from failing in those cases.

If you want `uv` always installed, remove the `SETUP_MINIMAL` guard or ensure `SETUP_MINIMAL` is not set in your environment. The script installs `uv` into `$HOME/.local/bin` when enabled.

If you'd like I can make `uv` a required install by default (i.e., remove the `SETUP_MINIMAL` guard), but I left it optional to keep quick bootstraps small and predictable.

Windows entrypoint
- Run the PowerShell script for Windows (winget/choco paths are used when available):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/setup-environment.ps1
```

Watching GitHub Actions (avoid Simple Browser)
----------------------------------------------

Some sites (including GitHub) block embedding in webviews/iframes using security headers (X-Frame-Options/CSP). In VS Code’s Simple Browser this often appears as a blank white page. Instead, use one of these approaches to monitor runs:

1) External browser (most reliable)
	 - Open: https://github.com/nam20485/agent-instructions/actions

2) GitHub Actions extension (inside VS Code)
	 - Install the “GitHub Actions” extension by GitHub.
	 - View workflows, runs, and live logs in the sidebar without using Simple Browser.

3) GitHub CLI (terminal; live tail when in progress)
	 - List recent runs:
		 ```powershell
		 gh run list --repo nam20485/agent-instructions --limit 10
		 ```
	 - Watch the latest in-progress run (exits if none running):
		 ```powershell
		 gh run watch --repo nam20485/agent-instructions --exit-status
		 ```
	 - Watch a specific run and stream a particular job’s logs:
		 ```powershell
		 gh run view <run-id> --repo nam20485/agent-instructions
		 gh run watch <run-id> --repo nam20485/agent-instructions --job "<job-name-or-id>" --exit-status
		 ```
	 - Open a run in your default browser:
		 ```powershell
		 gh run view <run-id> --repo nam20485/agent-instructions --web
		 ```

Notes
- Simple Browser showing a blank page is expected for GitHub due to anti-embedding headers.
- `gh run watch` tails only when a run is currently in progress; otherwise it exits with: “found no in progress runs to watch.”
- If you prefer, disable Simple Browser in VS Code: Extensions → search “@builtin simple browser” → gear → “Disable (Workspace)”.


agent-context clone seeding
---------------------------

`agent-context` is the upstream GitHub template repo (`intel-agency/agent-context`).
Cloning it with the legacy `create-repo-from-slug.ps1` flow left two problems:

1. **Class-2 state survived.** The clone inherited the template's own
   `.agents/memory.md`, completed/deferred plans, and leaked run-reviews verbatim
   (see `docs/plans/.deferred/template-content-strategy.md` in `agent-context`).
2. **Hierarchy trigger was broken.** The `-TriggerProjectSetup $True` path
   dispatched `/orchestrate-dynamic-workflow $workflow_name = project-setup`,
   which is a legacy orchestrator that doesn't fit `agent-context`-seeded
   instances. The workaround was always passing `-TriggerProjectSetup $False`
   and running `/gh-issue-tracking-init` manually.

Three new scripts fix both problems in parallel with the legacy flow. They
never modify `create-repo-with-plan-docs.ps1`'s existing logic (other than one
additive `-SkipProjectSetup` switch) and `trigger-project-setup.ps1` remains
unchanged — other templates that depend on the legacy trigger keep working.

Quick start (migrating from the old flow)

**Old flow** (what you used before):

```pwsh
./scripts/create-repo-from-slug.ps1 `
  -Slug "gap-miner-v2" `
  -TemplateRepoName "agent-context" `
  -TriggerProjectSetup $False -Yes

# one line
./scripts/create-repo-from-slug.ps1 -Slug "gap-miner-v2" -TemplateRepoName "agent-context" -TriggerProjectSetup $False -Yes

# then manually invoke /gh-issue-tracking-init on the clone + run cleanup
```

**New flow** (do this now):

```pwsh
./scripts/create-repo-agent-context.ps1 -Slug "gap-miner-v2" -Yes
```

That one command now does everything end-to-end:

- Creates the repo from the `intel-agency/agent-context` template.
- Clones it locally into `../dynamic_workflows/<slug>-<random-suffix>/`.
- Copies `plan_docs/<slug>/*` into `plan_docs/` on the clone.
- Runs the legacy placeholder/owner substitutions + the AGENTS.md identity rewrite.
- **NEW:** runs `cleanup-template-state.ps1` (clears template memory, plans,
  run-reviews) and amends the seed commit.
- **NEW:** creates a dispatch issue on the clone with body
  `/gh-issue-tracking-init`, labeled `gh-issue-tracking:direct-body` (the
  orchestrator's direct-body clause runs the body verbatim as a prompt).

Script reference

**`scripts/create-repo-agent-context.ps1`**
Thin orchestrator wrapper. Accepts:

- `-Slug` (mandatory) — base app-plan slug, same as before.
- `-Owner` (default `intel-agency`), `-Visibility` (default `public`).
- `-Count` — how many repos to create from the slug.
- `-Yes`, `-LaunchEditor`, `-DryRun` — same semantics as `create-repo-from-slug`.
- `-TriggerHierarchyInit` (default `$true`) — whether to create the
  `/gh-issue-tracking-init` dispatch issue. Set `$false` to skip.

Hard-codes `TemplateRepoName = 'agent-context'` and `TemplateOwner = 'intel-agency'`
(this wrapper is agent-context-specific on purpose).

**`scripts/cleanup-template-state.ps1`**
Class-2 cleanup. Usually invoked by the orchestrator wrapper; run standalone to
re-cleanup a clone later:

```pwsh
./scripts/cleanup-template-state.ps1 -RepoRoot "/path/to/clone"
./scripts/cleanup-template-state.ps1 -RepoRoot "/path/to/clone" -DryRun
```

Behavior (idempotent):

- `.agents/memory.md` is overwritten with a blank skeleton (section headers
  only, italic placeholder line per section).
- `docs/plans/.completed/*.md` and `docs/plans/.deferred/*.md` are deleted;
  the lifecycle directories are preserved.
- `docs/plans/.completed/run-issues-review/` subtree is removed entirely.
- Clone-seeded content (`plan_docs/`, `.agents/rules/`, `.agents/skills/`) is
  untouched — only template-self-referential state is removed.

**`scripts/trigger-gh-issue-tracking-init.ps1`**
Creates a dispatch issue on the target repo with body `/gh-issue-tracking-init`
(the skill's no-arg defaults resolve to the clone + seeded `plan_docs/`):

```pwsh
./scripts/trigger-gh-issue-tracking-init.ps1 -Repo "intel-agency/my-app" `
  -BootstrapLabelsFile "/path/to/clone/.github/.labels.json"
./scripts/trigger-gh-issue-tracking-init.ps1 -Repo "intel-agency/my-app" -DryRun
```

By default the dispatch issue is labeled `gh-issue-tracking:direct-body`, which
the orchestrator's direct-body match clause matches to run the issue body
verbatim as a prompt. Reuses `Ensure-DispatchBootstrapLabel` from the shared
`dispatch-labels.ps1` library to bootstrap each label (from
`-BootstrapLabelsFile`) before attaching it. Pass `-Labels 'orchestration:dispatch'`
for the legacy method, or `-Labels @()` for a bare, unlabeled issue.

Opting into cleanup on the legacy flow

If you want to keep using `create-repo-from-slug.ps1` for `agent-context`
clones but add Class-2 cleanup and the correct trigger, pass `-SkipProjectSetup`
and run the two new scripts yourself after:

```pwsh
./scripts/create-repo-from-slug.ps1 `
  -Slug "gap-miner-v2" `
  -TemplateRepoName "agent-context" `
  -TriggerProjectSetup $False -Yes

$clonePath = "../dynamic_workflows/gap-miner-v2-<suffix>"
./scripts/cleanup-template-state.ps1 -RepoRoot $clonePath
./scripts/trigger-gh-issue-tracking-init.ps1 -Repo "intel-agency/gap-miner-v2-<suffix>" `
  -BootstrapLabelsFile "$clonePath/.github/.labels.json"
```

(You'll also need to amend the seed commit and push — the orchestrator wrapper
handles that automatically, so prefer the one-liner above.)

Backward compatibility

- `trigger-project-setup.ps1` is unchanged; other templates still fire the
  legacy `project-setup` dispatch through it.
- `create-repo-with-plan-docs.ps1`'s only change is the optional
  `-SkipProjectSetup` switch. Default behavior is identical to before.
- `create-repo-from-slug.ps1` is unchanged; the legacy flow still works for
  non-`agent-context` templates.

Tests

```pwsh
# cleanup script: 8 cases
Invoke-Pester -Path tests/cleanup-template-state.Tests.ps1 -Output Detailed

# set-project-fields (Phase/Priority/Status/Level guard) regression: 4 cases
Invoke-Pester -Path <agent-context-repo>/.agents/skills/gh-issue-tracking-init/scripts/tests/SetProjectFields.Tests.ps1 -Output Detailed
```
