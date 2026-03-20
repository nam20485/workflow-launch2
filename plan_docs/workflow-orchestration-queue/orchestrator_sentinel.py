"""
OS-APOW Sentinel Orchestrator
Implementation of Phase 1: Story 2 & 3.

This script acts as the 'Brain' of the OS-APOW system. It:
1. Polls GitHub for issues labeled 'agent:queued' across the organization.
2. Claims the task using assign-then-verify distributed locking.
3. Manages the worker lifecycle via './scripts/devcontainer-opencode.sh'.
4. Posts heartbeat comments during long-running tasks.
5. Reports progress and results back to GitHub.
"""

import asyncio
import os
import signal
import subprocess
import random
import uuid
import json
import logging
import sys
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any

import httpx

# Canonical shared model — see I-1 / R-3 in Plan Review
from src.models.work_item import (
    TaskType,
    WorkItemStatus,
    WorkItem,
    scrub_secrets,
)

# --- 1. Configuration ---

POLL_INTERVAL = int(os.getenv("SENTINEL_POLL_INTERVAL", "60"))
MAX_BACKOFF = int(os.getenv("SENTINEL_MAX_BACKOFF", "960"))  # 16 minutes
SENTINEL_ID = os.getenv("SENTINEL_ID", f"sentinel-{uuid.uuid4().hex[:8]}")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GITHUB_ORG = os.getenv("GITHUB_ORG")
# GITHUB_REPO is no longer required — the Sentinel discovers work across the org.
# It can still be set to restrict polling to a single repo.
GITHUB_REPO = os.getenv("GITHUB_REPO", "")
SHELL_BRIDGE_PATH = "./scripts/devcontainer-opencode.sh"

# Heartbeat interval: post a status comment every N seconds during long tasks (R-1)
HEARTBEAT_INTERVAL = int(os.getenv("SENTINEL_HEARTBEAT_INTERVAL", "300"))  # 5 min

# Subprocess hard timeout: safety net in case inner watchdog fails (R-8)
# Set higher than run_opencode_prompt.sh HARD_CEILING_SECS (5400) to avoid racing.
SUBPROCESS_TIMEOUT = int(os.getenv("SENTINEL_SUBPROCESS_TIMEOUT", "5700"))  # 95 min

# Environment reset between tasks (I-10).  Options: "none", "stop", "down"
# "none" — keep container running (fastest, risk of state bleed)
# "stop" — stop container but keep it (fast restart via 'up')
# "down" — remove container entirely (pristine but slower)
ENV_RESET_MODE = os.getenv("SENTINEL_ENV_RESET", "stop")

# Sentinel bot account name — used for assign-then-verify locking (R-2).
# Must match the GitHub account the GITHUB_TOKEN authenticates as.
SENTINEL_BOT_LOGIN = os.getenv("SENTINEL_BOT_LOGIN", "")

# Setup Structured Logging
logging.basicConfig(
    level=logging.INFO,
    format=f"%(asctime)s [%(levelname)s] {SENTINEL_ID} - %(message)s",
    handlers=[logging.FileHandler("sentinel.log"), logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("OS-APOW-Sentinel")

# Graceful shutdown flag (R-4)
_shutdown_requested = False

# --- 2. Signal Handling (R-4) ---


def _handle_signal(signum, frame):
    """Set shutdown flag on SIGTERM/SIGINT so the current task can finish."""
    global _shutdown_requested
    sig_name = signal.Signals(signum).name
    logger.info(f"Received {sig_name} — will shut down after current task finishes")
    _shutdown_requested = True


signal.signal(signal.SIGTERM, _handle_signal)
signal.signal(signal.SIGINT, _handle_signal)


# --- 3. Shell Bridge Interface ---


async def run_shell_command(
    args: List[str], timeout: Optional[int] = None
) -> subprocess.CompletedProcess:
    """Invokes the local shell bridge (devcontainer-opencode.sh).

    Args:
        args: Command and arguments.
        timeout: Maximum seconds to wait. None = no limit.
    """
    try:
        logger.info(f"Executing Bridge: {' '.join(args)}")
        process = await asyncio.create_subprocess_exec(
            *args, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        try:
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=timeout,
            )
        except asyncio.TimeoutError:
            logger.warning(f"Shell command timed out after {timeout}s — killing")
            process.kill()
            stdout, stderr = await process.communicate()
            return subprocess.CompletedProcess(
                args=args,
                returncode=-1,
                stdout=stdout.decode().strip() if stdout else "",
                stderr=f"TIMEOUT after {timeout}s\n"
                + (stderr.decode().strip() if stderr else ""),
            )

        return subprocess.CompletedProcess(
            args=args,
            returncode=process.returncode,
            stdout=stdout.decode().strip() if stdout else "",
            stderr=stderr.decode().strip() if stderr else "",
        )
    except Exception as e:
        logger.error(f"Critical shell execution error: {str(e)}")
        raise


# --- 4. GitHub Queue Implementation ---


class GitHubQueue:
    """GitHub-backed work queue with session-level connection pooling (R-5)."""

    def __init__(self, token: str, org: str, repo: str = ""):
        self.token = token
        self.org = org
        self.repo = repo
        self.headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json",
        }
        # Session-level httpx client with connection pooling (I-4 / R-5)
        self._client = httpx.AsyncClient(
            headers=self.headers,
            timeout=30.0,
        )

    async def close(self):
        """Release the connection pool. Call during graceful shutdown."""
        await self._client.aclose()

    def _repo_api_url(self, repo_slug: str) -> str:
        return f"https://api.github.com/repos/{repo_slug}"

    async def fetch_queued_tasks(self) -> List[WorkItem]:
        """Queries GH for issues labeled 'agent:queued'.

        Uses the GitHub Search API for cross-repo discovery (I-8). If
        GITHUB_REPO is set, restricts to that single repo.
        """
        if self.repo:
            # Single-repo mode
            url = f"{self._repo_api_url(f'{self.org}/{self.repo}')}/issues"
            params = {"labels": WorkItemStatus.QUEUED.value, "state": "open"}
        else:
            # Cross-repo org-wide search (I-8)
            url = "https://api.github.com/search/issues"
            params = {
                "q": f"label:{WorkItemStatus.QUEUED.value} org:{self.org} is:issue is:open",
                "per_page": "30",
            }

        response = await self._client.get(url, params=params)

        if response.status_code != 200:
            logger.error(
                f"GitHub API error: {response.status_code} {response.text[:200]}"
            )
            return []

        data = response.json()
        # Search API wraps results in {"items": [...]}
        issues = data.get("items", data) if isinstance(data, dict) else data

        work_items = []
        for issue in issues:
            labels = [label["name"] for label in issue.get("labels", [])]
            task_type = TaskType.IMPLEMENT
            if "agent:plan" in labels or "[Plan]" in issue.get("title", ""):
                task_type = TaskType.PLAN
            elif "bug" in labels:
                task_type = TaskType.BUGFIX

            # Derive repo slug from issue URL for cross-repo support
            repo_slug = "/".join(issue["html_url"].split("/")[3:5])

            work_items.append(
                WorkItem(
                    id=str(issue["id"]),
                    issue_number=issue["number"],
                    source_url=issue["html_url"],
                    context_body=issue.get("body") or "",
                    target_repo_slug=repo_slug,
                    task_type=task_type,
                    status=WorkItemStatus.QUEUED,
                    node_id=issue["node_id"],
                )
            )
        return work_items

    async def claim_task(self, item: WorkItem) -> bool:
        """Claim a task using assign-then-verify distributed locking (I-2 / R-2).

        Steps:
          1. Attempt to assign SENTINEL_BOT_LOGIN to the issue.
          2. Re-fetch the issue to verify we are the assignee.
          3. Only then update labels and post the claim comment.
          If verification fails, abort gracefully.
        """
        base = self._repo_api_url(item.target_repo_slug)
        url_issue = f"{base}/issues/{item.issue_number}"

        # Step 1: Attempt assignment
        if SENTINEL_BOT_LOGIN:
            resp = await self._client.post(
                f"{url_issue}/assignees",
                json={"assignees": [SENTINEL_BOT_LOGIN]},
            )
            if resp.status_code not in (200, 201):
                logger.warning(
                    f"Failed to assign #{item.issue_number}: {resp.status_code}"
                )
                return False

            # Step 2: Re-fetch and verify assignee (R-2)
            verify_resp = await self._client.get(url_issue)
            if verify_resp.status_code == 200:
                assignees = [
                    a["login"] for a in verify_resp.json().get("assignees", [])
                ]
                if SENTINEL_BOT_LOGIN not in assignees:
                    logger.warning(
                        f"Lost race on #{item.issue_number} — "
                        f"assignees are {assignees}, expected {SENTINEL_BOT_LOGIN}"
                    )
                    return False
            else:
                logger.warning(
                    f"Could not verify assignment for #{item.issue_number}: "
                    f"{verify_resp.status_code}"
                )
                return False

        # Step 3: Update labels
        url_labels = f"{url_issue}/labels"
        try:
            await self._client.delete(f"{url_labels}/{WorkItemStatus.QUEUED.value}")
        except httpx.HTTPStatusError as exc:
            # 404/410 = label already removed (benign); anything else = real problem
            if exc.response.status_code not in (404, 410):
                logger.error(f"Label removal failed: {exc}")
                return False

        await self._client.post(
            url_labels,
            json={"labels": [WorkItemStatus.IN_PROGRESS.value]},
        )

        # Step 4: Post claim comment
        comment_url = f"{url_issue}/comments"
        msg = (
            f"🚀 **Sentinel {SENTINEL_ID}** has claimed this task.\n"
            f"- **Start Time:** {datetime.now(timezone.utc).isoformat()}\n"
            f"- **Environment:** `devcontainer-opencode.sh` initializing..."
        )
        await self._client.post(comment_url, json={"body": msg})

        logger.info(f"Successfully claimed Task #{item.issue_number}")
        return True

    async def post_heartbeat(self, item: WorkItem, elapsed_secs: int):
        """Post a heartbeat comment to keep observers informed (R-1)."""
        base = self._repo_api_url(item.target_repo_slug)
        comment_url = f"{base}/issues/{item.issue_number}/comments"
        minutes = elapsed_secs // 60
        msg = (
            f"💓 **Heartbeat** — Sentinel {SENTINEL_ID} still working.\n"
            f"- **Elapsed:** {minutes}m\n"
            f"- **Timestamp:** {datetime.now(timezone.utc).isoformat()}"
        )
        try:
            await self._client.post(comment_url, json={"body": msg})
        except Exception as exc:
            logger.warning(f"Heartbeat post failed: {exc}")

    async def update_status(
        self, item: WorkItem, status: WorkItemStatus, comment: Optional[str] = None
    ):
        """Finalizes the task state on GitHub with terminal labels and logs."""
        base = self._repo_api_url(item.target_repo_slug)
        url_labels = f"{base}/issues/{item.issue_number}/labels"

        try:
            await self._client.delete(
                f"{url_labels}/{WorkItemStatus.IN_PROGRESS.value}"
            )
        except httpx.HTTPStatusError as exc:
            if exc.response.status_code not in (404, 410):
                logger.error(f"Label cleanup failed: {exc}")

        await self._client.post(url_labels, json={"labels": [status.value]})

        if comment:
            # Scrub secrets before posting to the public issue (R-7)
            safe_comment = scrub_secrets(comment)
            comment_url = f"{base}/issues/{item.issue_number}/comments"
            await self._client.post(comment_url, json={"body": safe_comment})


# --- 5. Orchestration Logic ---


class Sentinel:
    def __init__(self, queue: GitHubQueue):
        self.queue = queue
        self._current_backoff = POLL_INTERVAL

    # --- Heartbeat coroutine (R-1) ---

    async def _heartbeat_loop(self, item: WorkItem, start_time: float):
        """Post periodic heartbeat comments while a task is running."""
        while True:
            await asyncio.sleep(HEARTBEAT_INTERVAL)
            elapsed = int(asyncio.get_event_loop().time() - start_time)
            await self.queue.post_heartbeat(item, elapsed)

    async def process_task(self, item: WorkItem):
        logger.info(f"Processing Task #{item.issue_number}...")
        start_time = asyncio.get_event_loop().time()

        # Launch heartbeat as a background task (R-1)
        heartbeat_task = asyncio.create_task(self._heartbeat_loop(item, start_time))

        try:
            # Step 1: Initialize Infrastructure
            res_up = await run_shell_command([SHELL_BRIDGE_PATH, "up"], timeout=300)
            if res_up.returncode != 0:
                err = f"❌ **Infrastructure Failure** during `up` stage:\n```\n{res_up.stderr}\n```"
                await self.queue.update_status(item, WorkItemStatus.INFRA_FAILURE, err)
                return

            # Step 2: Start Opencode Server
            res_start = await run_shell_command(
                [SHELL_BRIDGE_PATH, "start"], timeout=120
            )
            if res_start.returncode != 0:
                err = f"❌ **Infrastructure Failure** starting `opencode-server`:\n```\n{res_start.stderr}\n```"
                await self.queue.update_status(item, WorkItemStatus.INFRA_FAILURE, err)
                return

            # Step 3: Trigger Agent Workflow
            workflow_map = {
                TaskType.PLAN: "create-app-plan.md",
                TaskType.IMPLEMENT: "perform-task.md",
                TaskType.BUGFIX: "recover-from-error.md",
            }
            workflow = workflow_map.get(item.task_type, "perform-task.md")
            instruction = f"Execute workflow {workflow} for context: {item.source_url}"

            # Primary bridge call with subprocess timeout safety net (R-8)
            res_prompt = await run_shell_command(
                [SHELL_BRIDGE_PATH, "prompt", instruction],
                timeout=SUBPROCESS_TIMEOUT,
            )

            # Step 4: Handle Completion
            if res_prompt.returncode == 0:
                success_msg = (
                    f"✅ **Workflow Complete**\n"
                    f"Sentinel successfully executed `{workflow}`. "
                    f"Please review Pull Requests."
                )
                await self.queue.update_status(
                    item, WorkItemStatus.SUCCESS, success_msg
                )
            else:
                log_tail = (
                    res_prompt.stderr[-1500:]
                    if res_prompt.stderr
                    else "No error output captured."
                )
                fail_msg = f"❌ **Execution Error** during `{workflow}`:\n```\n...{log_tail}\n```"
                await self.queue.update_status(item, WorkItemStatus.ERROR, fail_msg)

        except Exception as e:
            logger.exception(f"Internal Sentinel Error on Task #{item.issue_number}")
            await self.queue.update_status(
                item,
                WorkItemStatus.INFRA_FAILURE,
                f"🚨 Sentinel encountered an unhandled exception: {str(e)}",
            )
        finally:
            heartbeat_task.cancel()
            try:
                await heartbeat_task
            except asyncio.CancelledError:
                pass

            # Environment reset between tasks (I-10)
            if ENV_RESET_MODE == "down":
                logger.info("Resetting environment (down — full teardown)")
                await run_shell_command([SHELL_BRIDGE_PATH, "down"], timeout=120)
            elif ENV_RESET_MODE == "stop":
                logger.info("Resetting environment (stop — keep container)")
                await run_shell_command([SHELL_BRIDGE_PATH, "stop"], timeout=60)
            # "none" = skip teardown

    async def run_forever(self):
        logger.info(
            f"Sentinel {SENTINEL_ID} entering polling loop "
            f"(interval: {POLL_INTERVAL}s, env-reset: {ENV_RESET_MODE})"
        )

        while not _shutdown_requested:
            try:
                tasks = await self.queue.fetch_queued_tasks()
                if tasks:
                    logger.info(f"Found {len(tasks)} queued task(s).")
                    for task in tasks:
                        if _shutdown_requested:
                            break
                        if await self.queue.claim_task(task):
                            await self.process_task(task)
                            break

                # Reset backoff on successful poll (I-3)
                self._current_backoff = POLL_INTERVAL

            except httpx.HTTPStatusError as exc:
                status = exc.response.status_code
                if status in (403, 429):
                    # Jittered exponential backoff (I-3)
                    jitter = random.uniform(0, self._current_backoff * 0.1)
                    wait = min(self._current_backoff + jitter, MAX_BACKOFF)
                    logger.warning(f"Rate limited ({status}) — backing off {wait:.0f}s")
                    self._current_backoff = min(self._current_backoff * 2, MAX_BACKOFF)
                    await asyncio.sleep(wait)
                    continue
                else:
                    logger.error(f"GitHub API error: {exc}")
            except Exception as e:
                logger.error(f"Polling cycle error: {str(e)}")

            await asyncio.sleep(self._current_backoff)

        logger.info("Shutdown flag set — exiting polling loop")


# --- 6. Entry Point ---


async def _main():
    # GITHUB_REPO is optional — empty means cross-org polling (I-8)
    required = ["GITHUB_TOKEN", "GITHUB_ORG"]
    missing = [v for v in required if not os.getenv(v)]
    if missing:
        logger.error(
            f"Critical Error: Missing environment variables: {', '.join(missing)}"
        )
        sys.exit(1)

    if not SENTINEL_BOT_LOGIN:
        logger.warning(
            "SENTINEL_BOT_LOGIN is not set — assign-then-verify locking is disabled. "
            "Set it to the GitHub login of the bot account for concurrency safety (R-2)."
        )

    gh_queue = GitHubQueue(GITHUB_TOKEN, GITHUB_ORG, GITHUB_REPO)
    sentinel = Sentinel(gh_queue)

    try:
        await sentinel.run_forever()
    finally:
        await gh_queue.close()
        logger.info("Sentinel shut down.")


if __name__ == "__main__":
    try:
        asyncio.run(_main())
    except KeyboardInterrupt:
        logger.info("Sentinel shutting down gracefully.")
