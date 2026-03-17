"""
OS-APOW Work Event Notifier
A FastAPI-based webhook receiver that maps provider events (GitHub, etc.)
to a unified Work Item queue.
"""

import hmac
import hashlib
import json
from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any
from enum import Enum
from fastapi import FastAPI, Request, HTTPException, Header, Depends
from pydantic import BaseModel

# --- 1. Modular Interface Definitions ---


class WorkItemType(str, Enum):
    APPLICATION_PLAN = "APPLICATION_PLAN"
    EPIC = "EPIC"
    STORY = "STORY"
    TASK = "TASK"


class WorkItemStatus(str, Enum):
    QUEUED = "queued"
    IN_PROGRESS = "in-progress"
    COMPLETED = "completed"
    FAILED = "failed"


class WorkItem(BaseModel):
    provider_id: str
    target_repo: str
    item_type: WorkItemType
    content: str
    raw_payload: Dict[str, Any]


class ITaskQueue(ABC):
    """Interface for the Work Queue (e.g., GH Issues, Redis, etc.)"""

    @abstractmethod
    async def add_to_queue(self, item: WorkItem) -> bool:
        pass

    @abstractmethod
    async def update_status(
        self, provider_id: str, status: WorkItemStatus, comment: str
    ):
        pass


# --- 2. Concrete Implementation: GitHub Issues Queue ---


class GitHubIssuesQueue(ITaskQueue):
    """Phase 1 Implementation: Maps WorkItems to GitHub Issue Labels/Comments"""

    def __init__(self, token: str):
        self.token = token
        # In a real impl, we'd use httpx or a GH library here
        print(f"Initialized GH Issues Queue with token: {token[:4]}***")

    async def add_to_queue(self, item: WorkItem) -> bool:
        print(f"[Queue] Triage: Adding {item.item_type} to GH Issue {item.provider_id}")
        # Logic: Add 'agent:queued' label to the issue via GH API
        return True

    async def update_status(
        self, provider_id: str, status: WorkItemStatus, comment: str
    ):
        print(f"[Queue] Status Update: {provider_id} -> {status}")
        # Logic: Post comment and update labels


# --- 3. FastAPI Application ---

app = FastAPI(title="OS-APOW Event Notifier")


# Dependency Injection for the Queue Implementation
def get_queue() -> ITaskQueue:
    # Phase 1: Default to GitHub implementation
    # This can be swapped for LinearIssuesQueue() in Phase 4
    return GitHubIssuesQueue(token="YOUR_GITHUB_TOKEN")


# Webhook Secret (Configured in GH App)
WEBHOOK_SECRET = b"your_webhook_secret_here"


async def verify_signature(request: Request, x_hub_signature_256: str = Header(None)):
    if not x_hub_signature_256:
        raise HTTPException(status_code=401, detail="X-Hub-Signature-256 missing")

    body = await request.body()
    signature = "sha256=" + hmac.new(WEBHOOK_SECRET, body, hashlib.sha256).hexdigest()

    if not hmac.compare_digest(signature, x_hub_signature_256):
        raise HTTPException(status_code=401, detail="Invalid signature")


# --- 4. Endpoints ---


@app.post("/webhooks/github", dependencies=[Depends(verify_signature)])
async def handle_github_webhook(
    request: Request, queue: ITaskQueue = Depends(get_queue)
):
    payload = await request.json()
    event_type = request.headers.get("X-GitHub-Event")

    # Triage Logic: Map GH Events to Unified Work Items
    if event_type == "issues" and payload.get("action") == "opened":
        issue = payload["issue"]

        # Check if it matches an OS-APOW template (simulated)
        if "[Application Plan]" in issue["title"] or "agent:plan" in [
            l["name"] for l in issue["labels"]
        ]:
            work_item = WorkItem(
                provider_id=str(issue["number"]),
                target_repo=payload["repository"]["full_name"],
                item_type=WorkItemType.APPLICATION_PLAN,
                content=issue["body"],
                raw_payload=payload,
            )
            await queue.add_to_queue(work_item)
            return {"status": "accepted", "item_id": work_item.provider_id}

    return {"status": "ignored", "reason": "No actionable OS-APOW event mapping found"}


@app.get("/health")
def health_check():
    return {"status": "online", "system": "OS-APOW Notifier"}


if __name__ == "__main__":
    import uvicorn

    # In dev, run with: uv run uvicorn notifier_service:app --reload
    uvicorn.run(app, host="0.0.0.0", port=8000)
