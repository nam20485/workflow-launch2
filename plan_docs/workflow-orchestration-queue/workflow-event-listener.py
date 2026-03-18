"""
OS-APOW Sentinel Orchestrator
Implementation of Phase 1: Story 2 & 3.
This script polls GitHub for queued work and dispatches it to the 
Opencode Worker via the established shell-bridge.
"""


import asyncio
import os
import subprocess
import uuid
import json
import logging
from datetime import datetime
from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


# --- 1. Models & Configuration ---


class TaskType(str, Enum):
    PLAN = "PLAN"
    IMPLEMENT = "IMPLEMENT"
    BUGFIX = "BUGFIX"


class WorkItemStatus(str, Enum):
    QUEUED = "agent:queued"
    IN_PROGRESS = "agent:in-progress"
    SUCCESS = "agent:success"
    ERROR = "agent:error"
    INFRA_FAILURE = "agent:infra-failure"


class WorkItem(BaseModel):
    id: str
    issue_number: int
    source_url: str
    context_body: str
    target_repo_slug: str
    task_type: TaskType
    status: WorkItemStatus
    node_id: str  # GraphQL Node ID for efficient updates


# Configuration from Environment
POLL_INTERVAL = int(os.getenv("SENTINEL_POLL_INTERVAL", "60"))
SENTINEL_ID = os.getenv("SENTINEL_ID", f"sentinel-{uuid.uuid4().hex[:8]}")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GITHUB_ORG = os.getenv("GITHUB_ORG")
GITHUB_REPO = os.getenv("GITHUB_REPO")
SHELL_BRIDGE_PATH = "./scripts/devcontainer-opencode.sh"


# Setup Logging
logging.basicConfig(
    level=logging.INFO,
    format=f"%(asctime)s [%(levelname)s] {SENTINEL_ID} - %(message)s",
    handlers=[logging.FileHandler("sentinel.log"), logging.StreamHandler()]
)
logger = logging.getLogger("OS-APOW-Sentinel")


# --- 2. Shell Bridge Interface ---


async def run_shell_command(args: List[str], capture_output: bool = True) -> subprocess.CompletedProcess:
    """Invokes the local shell bridge (devcontainer-opencode.sh)."""
    try:
        process = await asyncio.create_subprocess_exec(
            *args,
            stdout=subprocess.PIPE if capture_output else None,
            stderr=subprocess.PIPE if capture_output else None
        )
        stdout, stderr = await process.communicate()
        
        return subprocess.CompletedProcess(
            args=args,
            returncode=process.returncode,
            stdout=stdout.decode() if stdout else "",
            stderr=stderr.decode() if stderr else ""
        )
    except Exception as e:
        logger.error(f"Failed to execute shell command {' '.join(args)}: {str(e)}")
        raise


# --- 3. GitHub Queue Implementation ---


class GitHubQueue:
    def __init__(self, token: str, org: str, repo: str):
        self.token = token
        self.base_url = f"https://api.github.com/repos/{org}/{repo}"
        self.headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json"
        }


    async def fetch_queued_tasks(self) -> List[WorkItem]:
        """Queries GH for issues labeled 'agent:queued'."""
        import httpx # Required dependency for this implementation
        
        async with httpx.AsyncClient() as client:
            # Query issues with the queued label
            url = f"{self.base_url}/issues?labels={WorkItemStatus.QUEUED}"
            response = await client.get(url, headers=self.headers)
            
            if response.status_code != 200:
                logger.error(f"GH API Error: {response.status_code} - {response.text}")
                return []
            
            issues = response.json()
            work_items = []
            for issue in issues:
                # Basic Triage Logic
                task_type = TaskType.IMPLEMENT
                if "[Plan]" in issue["title"] or "agent:plan" in [l["name"] for l in issue["labels"]]:
                    task_type = TaskType.PLAN
                
                work_items.append(WorkItem(
                    id=str(issue["id"]),
                    issue_number=issue["number"],
                    source_url=issue["html_url"],
                    context_body=issue["body"] or "",
                    target_repo_slug=f"{GITHUB_ORG}/{GITHUB_REPO}",
                    task_type=task_type,
                    status=WorkItemStatus.QUEUED,
                    node_id=issue["node_id"]
                ))
            return work_items


    async def claim_task(self, item: WorkItem) -> bool:
        """Assigns the issue and updates label to 'in-progress'."""
        import httpx
        async with httpx.AsyncClient() as client:
            # 1. Update Label to in-progress
            url_labels = f"{self.base_url}/issues/{item.issue_number}/labels"
            # Remove queued, add in-progress
            await client.delete(f"{url_labels}/{WorkItemStatus.QUEUED}", headers=self.headers)
            await client.post(url_labels, json={"labels": [WorkItemStatus.IN_PROGRESS]}, headers=self.headers)
            
            # 2. Add Comment
            comment_url = f"{self.base_url}/issues/{item.issue_number}/comments"
            msg = f"🚀 **Sentinel {SENTINEL_ID}** has claimed this task.\nInitializing worker environment..."
            await client.post(comment_url, json={"body": msg}, headers=self.headers)
            
            logger.info(f"Task #{item.issue_number} claimed successfully.")
            return True


    async def update_status(self, item: WorkItem, status: WorkItemStatus, comment: Optional[str] = None):
        """Finalizes the task state on GitHub."""
        import httpx
        async with httpx.AsyncClient() as client:
            url_labels = f"{self.base_url}/issues/{item.issue_number}/labels"
            # Remove in-progress, add target status
            await client.delete(f"{url_labels}/{WorkItemStatus.IN_PROGRESS}", headers=self.headers)
            await client.post(url_labels, json={"labels": [status.value]}, headers=self.headers)
            
            if comment:
                comment_url = f"{self.base_url}/issues/{item.issue_number}/comments"
                await client.post(comment_url, json={"body": comment}, headers=self.headers)


# --- 4. Orchestration Logic ---


class Sentinel:
    def __init__(self, queue: GitHubQueue):
        self.queue = queue


    async def process_task(self, item: WorkItem):
        logger.info(f"Starting execution for Task #{item.issue_number} ({item.task_type})")
        
        try:
            # Step 1: Ensure Environment is UP
            logger.info("Running shell-bridge: up")
            res_up = await run_shell_command([SHELL_BRIDGE_PATH, "up"])
            if res_up.returncode != 0:
                await self.queue.update_status(item, WorkItemStatus.INFRA_FAILURE, f"❌ Infra Failure during 'up':\n