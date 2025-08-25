# Execution Plan: initiate-new-repo (case: case1)

- Assignment: initiate-new-repository
  1) gh: gh repo create sample-repo --public --template nam20485/ai-new-app-template --disable-wiki --enable-issues --license agpl-3.0
  2) local: Copy-Item -Path docs\advanced_memory\Advanced Memory .NET - Dev Plan.md -Destination .\docs -Force
  3) gh: gh project create --title sample-repo --format json --template basic_kanban
  4) gh: pwsh -NoProfile -File scripts/import-labels.ps1 -Owner nam20485 -Repo sample-repo -LabelsFile .labels.json
  5) gh: pwsh -NoProfile -File scripts/create-milestones.ps1 -Owner nam20485 -Repo sample-repo
  6) local: # rename .devcontainer name and *.code-workspace to sample-repo
