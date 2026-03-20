# OS-APOW Simplification Report

*Generated: March 19, 2026*

This report identifies areas of over-engineering or natural simplification opportunities across the three plan docs and reference code files. **No changes have been made.** Each item is presented for review and feedback before action.

---

## S-1. Abstract ITaskQueue / Strategy Pattern — YAGNI

**Files:** `notifier_service.py`, Architecture Guide §ADR 09, Impl Spec

The `ITaskQueue` ABC with `GitHubIssuesQueue` as the sole concrete implementation exists purely for a hypothetical future where the queue backend is swapped to Linear, Notion, or Redis. The MVP targets GitHub exclusively. Meanwhile, the Sentinel has its own completely separate `GitHubQueue` class that does the real work — so the abstraction isn't even shared. The FastAPI dependency-injection wiring (`Depends(get_queue)`) is also overhead given there's exactly one backend.

**Opportunity:** Drop the ABC. Use a plain `GitHubIssuesQueue` class directly. Re-introduce the interface if/when a second provider is actually needed.

**Remarks:**

---

## S-2. Duplicate Prose Across Three Documents

**Files:** All three plan docs

The same concepts — the four pillars, assign-then-verify, heartbeat, credential scrubbing, env-reset modes, Search API cross-repo polling — are described in full detail in the Dev Plan, Architecture Guide, **and** Implementation Spec. For example, the assign-then-verify protocol is explained step-by-step in:

- Dev Plan §3 Story 4 "Implementation Directions — Locking"
- Architecture Guide §2B "Concurrency Control"
- Architecture Guide §2C step 1 (partial)
- Impl Spec "Concurrency Control" feature
- Impl Spec "Acceptance Criteria → Task Claiming"

Every change to a design decision requires edits in 3+ places. This is the single largest maintenance burden.

**Opportunity:** Define each mechanism **once** in the Architecture Guide, then reference it by section number from the Dev Plan and Impl Spec. Example: *"Concurrency control uses assign-then-verify (see Architecture Guide §2B)."*

**Remarks:**

---

## S-3. Ten Configurable Environment Variables for an MVP

**File:** `orchestrator_sentinel.py` (configuration block)

The Sentinel exposes: `SENTINEL_POLL_INTERVAL`, `SENTINEL_MAX_BACKOFF`, `SENTINEL_ID`, `GITHUB_TOKEN`, `GITHUB_ORG`, `GITHUB_REPO`, `SENTINEL_HEARTBEAT_INTERVAL`, `SENTINEL_SUBPROCESS_TIMEOUT`, `SENTINEL_ENV_RESET`, `SENTINEL_BOT_LOGIN`. Of these, only `GITHUB_TOKEN`, `GITHUB_ORG`, and `SENTINEL_BOT_LOGIN` are truly required inputs. The remaining 7 are tuning knobs with sensible defaults that are unlikely to be changed in the first deployment.

**Opportunity:** Keep the 3 required vars. Hardcode the rest with their current defaults and promote to env vars later if operational experience warrants it. This cuts the `.env` documentation surface by 70%.

**Remarks:**

---

## S-4. Three-Mode ENV_RESET_MODE

**File:** `orchestrator_sentinel.py`, Dev Plan §7, Architecture Guide §2C step 6, Impl Spec "Docker Compose"

Three options (`"none"` / `"stop"` / `"down"`) with corresponding branching logic, documented across all three plan docs. For MVP, `"stop"` is the correct default — it's the middle ground. `"none"` risks state bleed and `"down"` is slow; neither will be used initially.

**Opportunity:** Default to `"stop"` only. Remove the branching. Add the config knob later when multi-tenant or high-throughput scenarios arise.

**Remarks:**

---

## S-5. Cross-Repo Org-Wide Polling

**File:** `orchestrator_sentinel.py` `fetch_queued_tasks()`, Dev Plan §3 Story 2

The Search API path (`/search/issues`) and the single-repo path (`/repos/.../issues`) have different response formats (Search wraps in `{"items": [...]}`, repo returns bare `[...]`), different rate limits (30 req/min for Search vs 5,000/hr for REST), and different pagination. The MVP is bootstrapping from a single template clone — cross-repo polling adds format-branching complexity for no immediate gain.

**Opportunity:** Start with single-repo mode only. Add the Search API path when the org actually has multiple workflow repos.

**Remarks:**

---

## S-6. GitHubIssuesQueue Is a Stub

**File:** `notifier_service.py`

`add_to_queue()` and `update_status()` contain only `print()` statements and don't call the GitHub API. Meanwhile the Sentinel's `GitHubQueue` has the real label-management, assignment, and comment-posting logic. These are two unrelated classes with similar names doing different things (or nothing).

**Opportunity:** Either implement the Notifier's queue methods (using shared code from the Sentinel's `GitHubQueue`) or remove the stub and have the Notifier simply add the `agent:queued` label directly in the webhook handler — which is a 3-line httpx call.

**Remarks:**

---

## S-7. IPv4 Scrubbing in scrub_secrets()

**File:** `src/models/work_item.py`

The regex `\b\d{1,3}(\.\d{1,3}){3}\b` matches **all** IPv4 addresses, including innocuous ones like `127.0.0.1` in log messages, version strings like `2.31.1` (false positive), or Docker subnet info that's useful for debugging. It will also redact version numbers in pip output.

**Opportunity:** Either remove the IPv4 pattern entirely (the real secrets are tokens, not IPs) or restrict it to RFC 1918 private ranges only.

**Remarks:**

---

## S-8. "Encrypted Black Box" Logs — Mentioned But Undesigned

**Files:** Architecture Guide §5, Impl Spec "Worker Output (Black Box)"

Multiple references to "raw, encrypted local files" for forensic audit trails, but no encryption scheme, key management, or storage format is specified. This is aspirational prose that inflates the apparent scope without guiding implementation.

**Opportunity:** Drop the "encrypted" qualifier. For MVP, plain local log files (already captured by the shell bridge) are sufficient. If compliance requires encryption at rest, that's a separate story with its own key management design.

**Remarks:**

---

## S-9. Phase 3 "Architect Sub-Agent" Detail in MVP Docs

**Files:** Dev Plan §5, Impl Spec "Hierarchical Task Delegation"

Phase 3 describes a LangChain-based Architect Sub-Agent that decomposes Epics into child issues with dependency ordering. This is described at feature-requirement level in the **Implementation Spec** alongside MVP acceptance criteria. Including speculative Phase 3 features at the same detail level as Phase 1 requirements makes it hard to distinguish what's actually being built now.

**Opportunity:** Move Phase 3 features to a separate "Future Directions" appendix or a dedicated Phase 3 spec. Keep the Implementation Spec focused on what's being built in the current iteration.

**Remarks:**

---

## S-10. Dual Logging (File + Stdout) in Sentinel

**File:** `orchestrator_sentinel.py`

The Sentinel logs to both `sentinel.log` (FileHandler) and stdout (StreamHandler). When running in Docker, stdout is already captured by the container runtime (`docker logs`). The file handler adds disk management concerns (rotation, volume mounts, cleanup) without providing anything Docker doesn't already give you.

**Opportunity:** Log to stdout only. Use `docker logs` or a log aggregator to persist. Add file logging later if running outside Docker.

**Remarks:**

---

## S-11. raw_payload Field on WorkItem

**File:** `src/models/work_item.py`

`raw_payload: Optional[Dict[str, Any]]` is populated by the Notifier but never read by the Sentinel or any other consumer. It's dead weight on every WorkItem instance.

**Opportunity:** Remove it. If a future consumer needs the raw payload, add it then.

**Remarks:**

---

## Summary Table

| ID | Area | Severity | Effort to Simplify |
|----|------|----------|-------------------|
| S-1 | ITaskQueue ABC | Medium | Low — delete ABC + DI wiring |
| S-2 | Doc duplication | High | Medium — refactor to single-source-of-truth |
| S-3 | 10 env vars | Medium | Low — hardcode 7, keep 3 |
| S-4 | 3-mode env reset | Low | Low — hardcode "stop" |
| S-5 | Cross-repo polling | Medium | Low — remove Search API branch |
| S-6 | Stub queue class | Medium | Low — inline or implement |
| S-7 | IPv4 scrubbing | Low | Low — remove or restrict |
| S-8 | Encrypted logs | Low | Low — remove prose |
| S-9 | Phase 3 in MVP spec | Medium | Medium — move to appendix |
| S-10 | Dual logging | Low | Low — remove FileHandler |
| S-11 | raw_payload field | Low | Low — delete field |

**Highest-impact simplifications:** S-2 (doc dedup) and S-1 + S-6 (remove abstractions nobody uses) would do the most to reduce cognitive overhead and maintenance burden.
