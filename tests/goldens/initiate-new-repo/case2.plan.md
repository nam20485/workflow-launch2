# Execution Plan: initiate-new-repo (case: case2)

- Assignment: initiate-new-repository
  1) gh: gh repo create sample-repo-2 --public --template nam20485/ai-new-app-template --disable-wiki --enable-issues --license agpl-3.0
  2) local: Copy-Item -Path docs\advanced_memory\Advanced Memory .NET - Dev Plan.md -Destination .\docs -Force
  3) local: Copy-Item -Path docs\advanced_memory\index.html -Destination .\docs -Force
  4) gh: gh project create --title sample-repo-2 --format json --template basic_kanban
  5) gh: pwsh -NoProfile -File scripts/import-labels.ps1 -Owner nam20485 -Repo sample-repo-2 -LabelsFile .labels.json
  6) gh: pwsh -NoProfile -File scripts/create-milestones.ps1 -Owner nam20485 -Repo sample-repo-2
  7) local: # rename .devcontainer name and *.code-workspace to sample-repo-2
