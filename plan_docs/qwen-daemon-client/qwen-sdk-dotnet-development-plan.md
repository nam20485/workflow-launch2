# qwen-sdk-dotnet — Development Plan

| | |
|---|---|
| **Plan** | Detailed development plan for the **`qwen-sdk-dotnet`** repo: implements the phases, packaging, and CI requirements of [`qwen-daemon-client-plan.md`](./qwen-daemon-client-plan.md) as epics with task-level steps and gates |
| **Parent plan** | [`qwen-daemon-client-plan.md`](./qwen-daemon-client-plan.md) (review comments incorporated 2026-09-04) |
| **Target** | New GitHub repo `nam20485/qwen-sdk-dotnet`; daemon target: `100.118.225.119:4170`, qwen 0.22.3, systemd unit `deploy/systemd/qwen-serve.service` in this repo |
| **Status** | Draft for approval — not started |
| **Date** | 2026-09-04 |
| **Stack** | `.agents/rules/app-stacks/dotnet-aspire-aspnet-blazor` (xUnit, bunit, coverlet, ReportGenerator, NSubstitute; GHA workflows) |

**Planning route:** the legacy `create-app-plan` orchestration is defunct — this
markdown document is the planning deliverable (user decision 2026-09-04).

## Inherited decisions (from the parent plan — do not relitigate here)

- .NET Aspire app model; **Kiota** for REST client generation; **Option A** for
  streaming (BCL `SseParser<T>` inside our own `QwenEventStream`).
- Spec authored as **OpenAPI 3.2** (native `text/event-stream` + `itemSchema`;
  Kiota ≥ v1.30.0 parses 3.2).
- Spec source hierarchy: TS SDK types → daemon source → protocol markdown →
  live-daemon contract probes as arbiter.
- Consuming app = Aspire **Starter App (ASP.NET Core/Blazor)** shape:
  AppHost + ServiceDefaults + `.Web` + `.ApiService`.
- NuGet packaging for `QwenDaemon.Client` only; CI per
  `.agents/rules/ci-cd.md`; drift reconciliation scripted (pwsh pipeline).

## Toolchain & pins

| Tool | Pin / source | Notes |
|---|---|---|
| .NET SDK | 10.0.400 LTS (`~/.dotnet`) | TFM `net10.0`; already installed here |
| .NET Aspire | exact NuGet versions pinned at scaffold (13.x line at time of writing) | via `aspire new` starter template |
| Kiota | dotnet tool, **≥ v1.30.0**, exact version pinned in the repo tool manifest at E2.1 | first release accepting OpenAPI 3.2 |
| Spectral | npm, exact version pinned at E1.1 | spec lint |
| ts-json-schema-generator | npm, exact version pinned at E1.1 | TS SDK → JSON Schema extraction |
| markdownlint-cli2 | 0.22.1 (match this repo's CI pin) | docs lint |
| gitleaks | v8.21.2 (match this repo's CI pin) | secret scan |
| pwsh | installed | all repo scripts are PowerShell |
| Node/npm | v24.x via nvm (installed) | hosts Spectral + markdownlint |

NuGet pins live in `Directory.Packages.props` (central package management) so
"strict version pinning" is enforced structurally, not by convention alone.

## Solution layout (as scaffolded)

```text
qwen-sdk-dotnet/
├── QwenSdkDotNet.AppHost/        # Aspire orchestration; daemon = external resource
├── QwenSdkDotNet.ServiceDefaults/# Aspire service defaults (project-reference only)
├── QwenDaemon.Client/            # THE deliverable library — the only NuGet package
│   ├── Generated/                #   Kiota output (committed, kiota-lock.json included)
│   ├── Streaming/                #   QwenEventStream + reconnect (hand-built)
│   └── Events/                   #   typed event DTOs (shared with spec components)
├── QwenSdkDotNet.ApiService/     # ASP.NET Core API (starter template); wraps the client
├── QwenSdkDotNet.Web/            # Blazor frontend (starter template); Swagger UI page
├── QwenDaemon.Client.Tests/      # xUnit: parser, reconnect, auth, mapping fixtures
├── QwenSdkDotNet.ContractTests/  # live-daemon contract suite (tagged, opt-in)
├── specs/
│   ├── qwen-serve.openapi.json   # OpenAPI 3.2 spec (committed)
│   └── scripts/                  # Build-QwenOpenApiSpec.ps1, Update-QwenKiotaClient.ps1, extraction helpers
├── validation.ps1                # mirrors CI exactly (build → scan → test)
└── .github/workflows/ci.yml      # SHA-pinned pipeline
```

---

## Epic E0 — Repo scaffold & CI green (empty)

**Goal:** `nam20485/qwen-sdk-dotnet` exists, builds empty, and its pipeline is
green before any feature code lands.

Steps:

1. Create the repo (`gh repo create nam20485/qwen-sdk-dotnet`, visibility per
   decision D1) and the base-branch setup (D1).
2. `aspire new QwenSdkDotNet` (Starter App, ASP.NET Core/Blazor) → AppHost,
   ServiceDefaults, `.Web`, `.ApiService`; add the `QwenDaemon.Client` classlib
   and both test projects; add `Directory.Packages.props` and migrate all
   package references to it.
3. Repo conventions, copied/adapted from `linux-system-agent` where they apply:
   `.gitignore` (dotnet), `.gitleaks.toml`, `.secretscan-allow`,
   `.markdownlint.json` + `.markdownlint-cli2.jsonc`, `AGENTS.md` + `.agents/`
   baseline (memory.md + rules: validation, ci-cd, coding-style, practices —
   fresh copies, rebranded for this repo).
4. `validation.ps1` implementing `build` → `scan` → `test` mirroring the
   pipeline below (per `.agents/rules/validation.md`).
5. `.github/workflows/ci.yml`: jobs `build-test-coverage` (dotnet test +
   coverlet + ReportGenerator → HTML artifact, **fail under 85%**), `scan`
   (gitleaks, markdownlint-cli2, `dotnet format --verify-no-changes`,
   PSScriptAnalyzer on `specs/scripts/` + `validation.ps1`). Every `uses:`
   SHA-pinned with the trailing `# vX.Y.Z` comment; all tool versions exact.

**Gate:** `dotnet build` clean with 0 warnings; `validation.ps1` green; first
PR's CI green.

## Epic E1 — OpenAPI spec + contract suite (parent Phase 1)

**Goal:** `specs/qwen-serve.openapi.json` (OpenAPI 3.2, maximally annotated)
proven against the live daemon, with the build scripted for repeatability.

Steps:

1. **E1.1 — Pin spec tooling:** npm-install Spectral and
   ts-json-schema-generator at exact versions; download
   `@qwen-code/sdk@0.1.8` tarball on demand in scripts (node_modules and
   tarballs never committed).
2. **E1.2 — `Build-QwenOpenApiSpec.ps1` skeleton** in `specs/scripts/`:
   orchestrates steps 3–7, idempotent, takes `-SdkVersion` / `-DaemonTag`
   params so a version bump is a one-line invocation.
3. **E1.3 — Schema extraction:** unpack the SDK `.d.ts`, run the TS→JSON-Schema
   pass over the exported request/response/event types → candidate
   `components.schemas`.
4. **E1.4 — Route inventory:** in `QwenLM/qwen-code` at the tag matching 0.22.3,
   enumerate HTTP bridge route registrations (methods, paths, status codes,
   error-envelope construction) → machine-readable routes file consumed by the
   assembler. Overrides the protocol markdown wherever they disagree.
5. **E1.5 — Semantics overlay:** replay semantics, ring-buffer eviction,
   `slow_client_warning`, CORS/origin rules, token exemptions, the documented
   `503 prompt_queue_full` / `504 session_restore_timeout` envelopes, and
   capability-gating notes → `description`/`x-` annotations.
6. **E1.6 — SSE modeling (OpenAPI 3.2):** `GET /session/:id/events` response
   with media type `text/event-stream` whose `itemSchema` is the discriminated
   event-union DTO; `Last-Event-ID` header + `maxQueued` query params modeled;
   `history_truncated` marker documented; `x-sse-events` extension indexes the
   event DTOs for our tooling.
7. **E1.7 — Assemble + lint gates:** emit `specs/qwen-serve.openapi.json` with
   `servers` entries (tailnet URL + localhost); Spectral lint clean;
   `kiota show -d specs/qwen-serve.openapi.json` renders the path tree with
   pinned Kiota ≥ v1.30.0.
8. **E1.8 — Contract suite** (`QwenSdkDotNet.ContractTests`): for every
   path+method in the spec, probe the running daemon (token read from
   `~/.qwen-serve-token` at runtime — never committed): status codes, response
   shapes diffed against the schemas, SSE sample capture. Tests tagged so they
   only run when a daemon endpoint + token are configured.

**Gate:** Spectral clean; `kiota show` green; contract suite green against the
live daemon 0.22.3 (all spec paths probed); `Build-QwenOpenApiSpec.ps1`
re-runs idempotently.

## Epic E2 — Kiota REST client (parent Phase 2)

**Goal:** `QwenDaemon.Client/Generated/` committed, build-stable, and
round-trip-proven against the live daemon.

Steps:

1. **E2.1 — Pin Kiota** in the repo's dotnet tool manifest at the exact latest
   stable ≥ v1.30.0.
2. **E2.2 — Generate + lock:** `kiota generate -d specs/qwen-serve.openapi.json
   -l CSharp -o QwenDaemon.Client/Generated -c QwenDaemonClient -n
   QwenDaemon.Client.Generated --clean-output --structured-mime-types
   application/json`; commit output **and** `kiota-lock.json`.
   `Update-QwenKiotaClient.ps1` wraps generate → build → test (the drift-repair
   half of the pipeline).
3. **E2.3 — Runtime + auth:** `Microsoft.Kiota.Bundle` pinned via CPM; static
   bearer auth for the daemon token (implement
   `StaticBearerAuthenticationProvider : IAuthenticationProvider` or reuse
   `ApiKeyAuthenticationProvider` — decide at implementation, decision D3).
4. **E2.4 — DI/Aspire wiring:** register the client over `IHttpClientFactory`
   with base URL + token sourced from Aspire configuration.
5. **E2.5 — Round-trip integration test:** create session → prompt →
   load/status → close against the live daemon.

**Gate:** `kiota generate` reproducible from the lock; round-trip test green;
builds with 0 warnings.

## Epic E3 — SSE layer (parent Phase 3)

**Goal:** `QwenDaemon.Client/Streaming/QwenEventStream` — typed, resumable,
backpressure-aware — with the daemon-specific behaviors implemented
deliberately and tested.

Steps:

1. **E3.1 — Event DTOs:** typed DTOs in `Events/` matching the spec's
   `components` schemas; decide custom-generator vs hand-synced partials
   (decision D4). Unknown events tolerated (ignore, don't crash).
2. **E3.2 — `QwenEventStream` core:** `HttpClient` streaming +
   `SseParser<QwenDaemonEvent>`; bearer on the connect request; `Last-Event-ID`
   resume from the tracked last id; `?maxQueued=` sizing;
   `history_truncated` surfaced to consumers.
3. **E3.3 — Reconnect loop:** backoff on transport drops; proactive reconnect
   on `slow_client_warning` (drain before eviction); idempotent re-attach;
   cancellation + structured logging (Aspire lifecycle friendly).
4. **E3.4 — Test suite:** parser mapping fixtures; reconnect-after-drop (test
   server that severs connections); `slow_client_warning` triggers reconnect;
   replay gap surfaces `history_truncated`; cancellation. Plus the live soak:
   prompt → events observed → kill/reconnect resumes via `Last-Event-ID`.

**Gate:** unit + reconnect suite green; live soak passed; API shape matches the
parent plan's `Build shape` sketch.

## Epic E4 — Aspire consuming app (parent Phase 4)

**Goal:** `aspire run` brings up Web + ApiService wired to the daemon, with the
Swagger UI page and a minimal end-to-end session demo. Feature requirements for
the app surface beyond this are deliberately deferred (parent plan).

Steps:

1. **E4.1 — Daemon as external resource:** AppHost declares a parameterized
   endpoint (base URL) + secret (token); health probe `GET /health` with
   bearer. Not an Aspire-owned process (the daemon is systemd-managed).
2. **E4.2 — Config flow:** token from user-secrets/env in dev → Aspire config →
   client registration; no token in source. Dev loops: local loopback daemon
   vs tailnet daemon, both via configuration.
3. **E4.3 — ApiService minimal surface:** wrap the client behind the API
   (e.g. create session, send prompt, expose status/events) — the Blazor
   frontend consumes this, never the daemon directly.
4. **E4.4 — Web minimal surface:** starter-template Blazor page exercising the
   ApiService round-trip (kept basic; scope deferred).
5. **E4.5 — Swagger UI page:** serve Swagger UI from
   `specs/qwen-serve.openapi.json` (library per decision D5), server URL
   pointed at the configured daemon endpoint, bearer-token input enabled.
6. **E4.6 — (conditional)** if `.ApiService` re-exposes streams as its own SSE
   endpoints, enable ASP.NET Core's native OpenAPI 3.2 SSE doc generation for
   them (dotnet/aspnetcore#64379).

**Gate:** `aspire run` health-checked against the tailnet daemon; one
end-to-end session from the app; Swagger UI page serves the spec pointed at the
daemon.

## Epic E5 — Packaging, drift pipeline, runbook

**Goal:** the library ships as a NuGet package and the drift-reconciliation
pipeline is a documented, repeatable operation.

Steps:

1. **E5.1 — Packaging:** `QwenDaemon.Client` csproj packaging props —
   PackageId (decision D2), strict SemVer, XML docs, Source Link, README
   embedding; `dotnet pack` added to CI; package smoke-test (reference the
   built nupkg from a scratch project).
2. **E5.2 — Drift pipeline end-to-end:** finalize
   `specs/scripts/Build-QwenOpenApiSpec.ps1` +
   `specs/scripts/Update-QwenKiotaClient.ps1`; run the full sequence once
   (rebuild spec → regenerate client → contract suite) and record it as the
   upgrade runbook. Optional: wrap as a repo-local agent skill (decision D6).
3. **E5.3 — Runbook + README:** daemon-bump procedure documented in the new
   repo's README; contract-suite cadence (every daemon bump) stated.

**Gate:** `dotnet pack` clean; pipeline runs end-to-end; runbook committed.

---

## Testing strategy

| Layer | Framework | Where it runs |
|---|---|---|
| Unit (parser mapping, reconnect state machine, auth provider, DTO round-trip) | xUnit + NSubstitute | every CI run |
| Blazor components (if/when non-trivial) | bunit | every CI run |
| Contract (every spec path+method vs live daemon) | xUnit, tagged `[DaemonContract]` | locally + CI dispatch/schedule with daemon token secret (D7) |
| Integration (Kiota REST round-trip, live soak) | xUnit, tagged | locally; CI where a connected runner exists (D7) |
| Coverage | coverlet + ReportGenerator | > 85% gate + HTML artifact, every run |

TDD per `.agents/rules/validation.md`: failing test → implement → iterate.
Live-daemon tests read the endpoint/token from configuration and skip cleanly
when absent, so a bare checkout still passes `dotnet test`.

## CI pipeline (`.github/workflows/ci.yml`)

- **Triggers:** PRs; contract suite additionally on `workflow_dispatch` +
  schedule.
- **Job `build-test-coverage`:** setup-dotnet (SHA-pinned, 10.0.x) → restore →
  build → `dotnet test` with coverlet → ReportGenerator HTML → upload artifact
  → **fail below 85%**.
- **Job `scan`:** gitleaks v8.21.2 → markdownlint-cli2@0.22.1 →
  `dotnet format --verify-no-changes` → PSScriptAnalyzer on all `.ps1`.
- **Job `spec-lint`:** Spectral (pinned) on `specs/qwen-serve.openapi.json`.
- **Job `contract` (dispatch/schedule):** checkout → configure endpoint +
  `DAEMON_TOKEN` secret → run tagged contract suite.
- Every `uses:` line SHA-pinned with `# vX.Y.Z`; every tool version exact
  (`.agents/rules/ci-cd.md`).

## Branch & delivery strategy

- One branch per epic: `dev/e<N>-<slug>` → PR → CI green → merge (safe-commit
  before every commit; base branch per D1).
- Milestone: `Qwen SDK v0` (or per D1's board convention).
- Epics land in order E0 → E5; E3 depends on E1's event schemas, E4 on E2+E3,
  E5 on all.

## Decisions needed (D1–D7)

| # | Decision | Options | Recommended default |
|---|---|---|---|
| D1 | Repo visibility + base branch | private vs public; `main` vs `development` integration branch | private; `main` (new repo, no legacy consumers) |
| D2 | NuGet PackageId | `QwenDaemon.Client` vs `Qwen.Sdk.DotNet` | `QwenDaemon.Client` (matches namespace; rename is breaking) |
| D3 | Bearer auth provider | custom `StaticBearerAuthenticationProvider` vs `ApiKeyAuthenticationProvider` reuse | whichever is fewer lines at E2.3 — decide with code in hand |
| D4 | Event DTO codegen | small custom generator from `components` vs hand-synced partials | hand-synced first (≤ few dozen types), generator only if drift bites |
| D5 | Swagger UI library | Swashbuckle vs Scalar | decide at E4.5; whichever pins cleanest on net10.0 |
| D6 | Drift pipeline skill wrapper | pwsh scripts only vs + repo-local agent skill | scripts only first; skill later if the loop repeats |
| D7 | Contract-suite CI runner | self-hosted runner on the tailnet vs local-only runs | local-only until a self-hosted runner exists |

## Success criteria (mirror of the parent plan's acceptance criteria)

- [ ] `specs/qwen-serve.openapi.json` committed, lint-clean, `kiota show`-valid, contract-proven against daemon 0.22.3.
- [ ] Kiota REST client generated + committed with lock file; bearer auth; REST round-trip test green.
- [ ] `QwenEventStream` implemented with typed events from the shared schemas; reconnect/replay/backpressure tests green; live soak passed.
- [ ] Aspire AppHost runs the consuming app against the tailnet daemon with health-checked wiring; Swagger UI page serves the spec pointed at the daemon.
- [ ] `QwenDaemon.Client` packs cleanly (`dotnet pack`).
- [ ] CI pipeline green: tests, coverage > 85% + HTML artifact, scanning; `validation.ps1` mirrors it.
- [ ] Upgrade runbook (daemon bump → re-extract → regenerate → contract suite) documented in the new repo and driven by the two pipeline scripts.
