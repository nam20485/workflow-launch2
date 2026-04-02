#file:workflow-orchestration-service is being moveed into a separate, self-contained app plan_doc set (from #file:workflow-orchestration-queue plan docs)

To complete this two things must be completed:

1. #file:pre-task-execution-plan.md and references to it in #file:OS-APOW-standalone-service-migration-plan.md and #file:OS-APOW Implementation Specification v1.2.md must be removed (this will be a new app created from scratch by having the #file:create-repo-from-slug.ps1  and `project-setup` dynamic workflow run on it, and was not birthed from `workflow-orchestration-queue-tango48`) 
  a. that being said, thoroughly inspect #file:pre-task-execution-plan.md and compare to the contents of these plan docs to see if anything might possibly still be releavant and need to performed)
 2. needs to be determined if the references to the historical documents contain anything useful, or ideally, can ahev their references excised also, leaving the current set of docs (minus #file:pre-task-execution-plan.md  after its removed, above) completetely self-contianed.