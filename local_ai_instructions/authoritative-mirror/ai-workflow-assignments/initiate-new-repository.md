# Assignment: initiate-new-repository (Authoritative Mirror)

This local mirror exists to ensure the resolver can run offline. The JSON payload below matches the spec used by the planner and mirrors the acceptance criteria and steps present in the repo's local index/goldens.

```json
{
  "shortId": "initiate-new-repository",
  "title": "Initiate New Repository",
  "inputs": ["repo_name", "app_plan_docs[]"],
  "acceptanceCriteria": [
    "New GitHub repo created from template (public, AGPL).",
    "Provided app_plan_docs copied into docs/ of new repo.",
    "GitHub Project (Basic Kanban) created, named same as repo.",
    "Repo labels imported from .labels.json via scripts/import-labels.ps1.",
    "Milestones created via scripts/create-milestones.ps1.",
    "Rename devcontainer/workspace artifacts: .devcontainer name -> <repo>-devcontainer; *.code-workspace -> <repo>.code-workspace."
  ],
  "detailedSteps": [
    {
      "id": "create-repo",
      "description": "Create new repo from nam20485/ai-new-app-template (public, AGPL).",
      "kind": "gh",
      "commandTemplate": "gh repo create {repo_name} --public --template nam20485/ai-new-app-template --disable-wiki --enable-issues --license agpl-3.0"
    },
    {
      "id": "copy-docs",
      "description": "Copy app_plan_docs into docs/ in the new repo.",
      "kind": "local",
      "commandTemplate": "Copy-Item -Path {doc} -Destination .\\docs -Force"
    },
    {
      "id": "create-project",
      "description": "Create GitHub Project (Basic Kanban) named {repo_name}.",
      "kind": "gh",
      "commandTemplate": "gh project create --title {repo_name} --format json --template basic_kanban"
    },
    {
      "id": "import-labels",
      "description": "Import labels from .labels.json",
      "kind": "gh",
      "commandTemplate": "pwsh -NoProfile -File scripts/import-labels.ps1 -Owner {owner} -Repo {repo_name} -LabelsFile .labels.json"
    },
    {
      "id": "create-milestones",
      "description": "Create milestones",
      "kind": "gh",
      "commandTemplate": "pwsh -NoProfile -File scripts/create-milestones.ps1 -Owner {owner} -Repo {repo_name}"
    },
    {
      "id": "rename-artifacts",
      "description": "Rename devcontainer folder and code-workspace filename to include repo name.",
      "kind": "local",
      "commandTemplate": "# rename .devcontainer name and *.code-workspace to {repo_name}"
    }
  ]
}
```
