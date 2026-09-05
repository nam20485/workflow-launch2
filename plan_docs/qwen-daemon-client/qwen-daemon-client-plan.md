# Qwen Daemon .NET Client — Development Plan

| | |
|---|---|
| **Plan** | Build a typed .NET client for the `qwen serve` daemon: hand-built OpenAPI spec → Kiota-generated REST client → hand-built SSE event layer, consumed from a .NET Aspire app |
| **Target** | New .NET Aspire solution in repo **`qwen-sdk-dotnet`** (named 2026-09-04); the daemon target is the one running on this machine (`100.118.225.119:4170`, qwen 0.22.3) |
| **Status** | Review comments incorporated (2026-09-04); detailed development plan drafted — [`qwen-sdk-dotnet-development-plan.md`](./qwen-sdk-dotnet-development-plan.md) (pending approval; the `create-app-plan` orchestration is defunct) |
| **Date** | 2026-09-02 (updated 2026-09-04) |
| **Reference** | Development plan: [`qwen-sdk-dotnet-development-plan.md`](./qwen-sdk-dotnet-development-plan.md). Daemon facts: [`system-setup-plan.md`](./system-setup-plan.md) Feature 1 (merged unit at `deploy/systemd/qwen-serve.service`); upstream docs: `developers/qwen-serve-protocol`, `developers/sdk-*` on the Qwen Code docs site |

## Vision

A .NET Aspire application that drives the Qwen daemon programmatically:
sessions, prompts, workspace ops, and live event streaming — through a client
that is **generated where generation pays** (REST, via Kiota from an OpenAPI
spec) and **hand-built where it doesn't** (the SSE half). The OpenAPI spec is
ours to build and keep rich: upstream publishes none.

## Decisions (user-approved 2026-09-02)

- **.NET Aspire** for the application model.
- **Kiota** for the REST client generation.
- **Spec source hierarchy** (from the prior analysis): TS SDK types (machine-tractable schemas) → daemon source code (authoritative routes/envelopes) → protocol markdown (semantics overlay) → **live daemon probing as the arbiter**.

### Additional decisions (user-approved 2026-09-04)

- **Option A confirmed** (BCL `SseParser<T>` + own `QwenEventStream`) after re-examination against OpenAPI 3.2 SSE media-type support, microsoft/kiota#7435, and dotnet/aspnetcore#64379 — all three are spec-level, server-side, or unimplemented; none generates the SSE client half (see Phase 3 review record).
- **OpenAPI 3.2** as the spec revision: first revision with native `text/event-stream` support (Media Type Object `itemSchema`), and Kiota ≥ v1.30.0 accepts 3.2 documents. Verify Kiota's 3.2 handling early in Phase 1 (fallback: 3.1 + `x-sse-events` only).
- **Repo name: `qwen-sdk-dotnet`.** Scaffolding does NOT go through `create-app-plan` — the legacy orchestration framework is defunct; the next deliverable is a detailed development plan in a markdown file. Stack file `dotnet-aspire-aspnet-blazor` confirmed.
- **Consuming app shape:** Aspire `Starter App (ASP.NET Core/Blazor)` template — AppHost, ServiceDefaults, `.Web` (Blazor frontend), `.ApiService` (ASP.NET Core API).
- **NuGet packaging** for `QwenDaemon.Client` — the only packageable library (see Packaging).
- **CI/CD** per `.agents/rules/ci-cd.md` — automated testing + coverage (> 85%, HTML report) + static analysis/security scanning, strict version pinning (see CI/CD section).
- **Swagger UI page** in the consuming app, serving the OpenAPI spec with its server pointed at the qwen daemon.
- **Drift reconciliation** as repeatable pwsh scripts (spec rebuild + Kiota regeneration), runnable now and on every daemon bump (see Risks → Spec drift).

## Verified facts (2026-09-02)

- **No OpenAPI/Swagger exists anywhere** for `qwen serve`: upstream repo code search finds none; the live daemon 404s `/openapi.json`, `/swagger.json`, `/api-docs`. The contract is a ~293 KB markdown reference + runtime feature detection.
- **Live daemon** (this machine): protocol `v1`, **128 capability keys**, advertises `typed_event_schema` — i.e. the daemon formally commits to the TS SDK's event types as its wire schema.
- **Artifacts to build from:** `@qwen-code/sdk` v0.1.8 (npm, `.d.ts` types incl. `KnownDaemonEvent`), qwen-code source at the tag matching 0.22.3, `developers/qwen-serve-protocol` markdown. Docs on `main` run ahead of 0.22.3 — pin everything to the installed daemon version; the live daemon arbitrates mismatches.
- **Toolchain on this machine:** .NET SDK 10.0.400 LTS (`~/.dotnet`), pwsh, git/gh. App stack available in this repo: `.agents/rules/app-stacks/dotnet-aspire-aspnet-blazor`.
- **Daemon endpoints** (from protocol doc, spot-verified live): `/health`, `/capabilities`, `/daemon/status`, `POST /session`, `GET /session/:id/events` (SSE, `Last-Event-ID` replay, `?maxQueued=16..2048`), `POST /session/:id/prompt|load|resume|heartbeat`, `DELETE /session/:id`, `PATCH /session/:id/metadata`, `GET /session/:id/transcript|status`, workspace file routes (`/file`, `/list`, `/glob`, `/stat`, `/file/write|edit|upload`), `/workspaces`, `/extensions`. Auth: `Authorization: Bearer <token>` on everything (`--require-auth` is on; `/health` gated too).

---

## Architecture

```text
qwen-sdk-dotnet/            # repo name decided 2026-09-04
├── <App>.AppHost/          # Aspire orchestration; models the daemon as an external resource
├── <App>.ServiceDefaults/  # standard Aspire service defaults (project-reference only)
├── QwenDaemon.Client/      # THE deliverable library — the only NuGet package:
│   ├── Generated/          #   Kiota output (committed, kiota-lock.json included)
│   ├── Streaming/          #   hand-built SSE layer (QwenEventStream + reconnect)
│   └── Events/             #   typed event DTOs (shared with OpenAPI components)
├── <App>.ApiService/       # ASP.NET Core API (starter template); wraps QwenDaemon.Client
├── <App>.Web/              # Blazor frontend (starter template); hosts the Swagger UI page
└── specs/
    ├── qwen-serve.openapi.json   # the hand-built OpenAPI 3.2 spec (committed)
    └── scripts/                  # spec build + client regen pipeline (pwsh, repo convention)
```

Principle: **one source of truth per half** — the OpenAPI document owns REST
shapes (Kiota consumes it), and the same document's `components` owns the SSE
event DTOs so both halves stay schema-identical.

---

## Phase 1 — Build the OpenAPI spec (the core deliverable)

**Goal:** `specs/qwen-serve.openapi.json` — OpenAPI **3.2**, maximally annotated:
every endpoint, request/response schemas, error envelopes, header params
(`Authorization`, `Last-Event-ID`), query params (`maxQueued`, `deep`), status
codes incl. the documented `503 prompt_queue_full` / `504 session_restore_timeout`
envelopes, capability-gating notes, and SSE event schemas in `components`.
3.2 is deliberate: it is the first OpenAPI revision with native
`text/event-stream` support (Media Type Object `itemSchema`), and Kiota
≥ v1.30.0 parses 3.2 documents.

Steps:

1. **Extract schemas from the TS SDK types** (primary source): unpack
   `@qwen-code/sdk@0.1.8`, feed the daemon-client `.d.ts` files through a
   TypeScript→JSON-Schema pass (e.g. `ts-json-schema-generator` against the
   exported request/response/event types). Produces candidate `components.schemas`.
2. **Route inventory from daemon source:** in `QwenLM/qwen-code` at the tag
   matching 0.22.3, enumerate the HTTP bridge route registrations (methods,
   paths, status codes, error envelope construction). This overrides the markdown
   wherever they disagree.
3. **Semantics overlay from the protocol markdown:** replay semantics, eviction,
   `slow_client_warning`, CORS/origin rules, token exemptions — into
   `description`/`x-` annotations (this is what makes the spec "rich" rather than
   merely complete).
4. **SSE representation:** OpenAPI cannot model streams first-class, but 3.2
   natively recognizes `text/event-stream`: represent `GET /session/:id/events`
   as a response with that media type, whose `itemSchema` is the discriminated
   event-union DTO (event schemas live in `components`) and whose description
   documents replay/backpressure. Keep an `x-sse-events` extension as the
   single machine-readable index of event DTOs for our own tooling. (AsyncAPI
   companion doc remains a future option; rejected for now — no .NET codegen
   story.) Note: Kiota will not generate anything from this half — SSE codegen
   is an open, untriaged feature request (microsoft/kiota#7435).
5. **Validate against the live daemon (contract tests):** for every path+method
   in the spec, probe the running daemon (token in `~/.qwen-serve-token`): status
   codes, response shapes diffed against the schemas, SSE sample capture. Record
   results as a repeatable pwsh/xunit contract suite in the repo — this is what
   turns the spec from plausible to proven, and catches future daemon drift.
6. **Spec quality gates:** lint with Spectral (or Microsoft.OpenAPI validator);
   smoke-test with `kiota show -d specs/qwen-serve.openapi.json` using Kiota
   ≥ v1.30.0 (first release accepting OpenAPI 3.2 documents; pin the exact
   tool version per the CI rules); enforce `servers` entry (tailnet URL +
   localhost) to avoid Kiota's `NoServerEntry` validation noise.

## Phase 2 — Kiota REST client

**Goal:** `QwenDaemon.Client/Generated/` committed and build-stable.

1. `dotnet tool install --global microsoft.openapi.kiota`.
2. `kiota generate -d specs/qwen-serve.openapi.json -l CSharp -o QwenDaemon.Client/Generated -c QwenDaemonClient -n QwenDaemon.Client.Generated --clean-output` — commit output **and** `kiota-lock.json` (Kiota skips regeneration when spec+params unchanged; `kiota update` refreshes from the lock).
3. Runtime packages: prefer `Microsoft.Kiota.Bundle` (abstractions + HTTP + serialization in one); drop Azure auth (not Entra) — auth is a **static bearer token**: implement a ~10-line `StaticBearerAuthenticationProvider : IAuthenticationProvider` (or reuse `ApiKeyAuthenticationProvider` with header placement — decide at implementation).
4. **Aspire/DI wiring:** register the client over `IHttpClientFactory` with base URL + token sourced from Aspire configuration; `--structured-mime-types application/json` so binary routes (file upload) surface as streams.
5. Verify: generated client performs the full REST round-trip against the live daemon (create session → prompt → load/status → close) in an integration test.

## Phase 3 — SSE client implementation (analysis + build)

### Requirements (from the daemon contract)

- `GET /session/:id/events`, bearer auth on the stream request.
- **Replay/resume:** `Last-Event-ID: N` header; daemon replays from its per-session ring buffer (`--event-ring-size` default 8000); `history_truncated` marker when the backlog was dropped.
- **Backpressure:** `?maxQueued=N` (16–2048, default 256); daemon emits a synthetic `slow_client_warning` at 75% queue fill — clients must drain/reconnect before eviction.
- **Typed events:** `session_update` envelopes (`agent_message_chunk`, `agent_thought_chunk`, `user_message_chunk`, `permission_request`, …) conforming to the SDK's `KnownDaemonEvent` (daemon advertises `typed_event_schema`); unknown events must be tolerated (ignore, don't crash).
- Reconnect with backoff; idempotent attach (`POST /session` with existing `sessionId`); lifecycle integration with Aspire (start/stop with the app, cancellation, structured logging).

### Options

| Option | Description | Pros | Cons |
|---|---|---|---|
| **A (recommended)** | **BCL `System.Net.ServerSentEvents.SseParser<T>` inside our own thin `QwenEventStream`** over `HttpClient`/`HttpResponseMessage` streaming | Ships with .NET (no dependency; confirmed in .NET 9 networking improvements); spec-compliant parsing incl. multiline data; exposes `LastEventId`/`ReconnectionInterval` so *we* control replay semantics exactly the way this daemon wants (ring replay, `maxQueued`, `slow_client_warning` handling, custom backoff); event DTOs deserialize straight from `SseItem<T>.Data` into the OpenAPI-derived types; fully unit-testable | We own the reconnect loop (~150 lines) and its tests; must handle transport drops/cancellation ourselves (bounded, well-trodden code) |
| B | BCL `SseClient` (higher-level connection class, if available in the targeted runtime) | Would give built-in connect/reconnect state machine | **Not verifiable in current docs** (API reference 404s; the .NET 9 announcement documents `SseParser` only) — adopting an unverifiable API is a risk; its reconnection semantics likely don't map to this daemon's ring-buffer/eviction model anyway |
| C | `LaunchDarkly.EventSource` (third-party) | Mature auto-reconnect + jittered backoff; netstandard2.0 reach | Extra dependency in an Aspire app for one stream type; W3C-generic reconnect policy ≠ daemon-specific `slow_client_warning`/`maxQueued` behavior (still need our logic on top); string-typed event payloads add a mapping layer we'd write anyway |
| D | Fully hand-rolled parser over raw streams | Total control, zero deps | Reimplements exactly what `SseParser` already does correctly (field parsing, BOM, multiline `data:`); pure cost, no benefit |

**Recommendation: A.** It's the only option that is simultaneously
dependency-free, documented/verifiable on our runtime (.NET 10 LTS target), and
honest about the daemon's non-generic stream semantics: `Last-Event-ID` resume,
`maxQueued` sizing, and `slow_client_warning`-driven reconnect are protocol
behaviors *we must implement deliberately* — so the layer that owns them should
be ours, small, and testable, with parsing delegated to the BCL. B is an
unverifiable API, C buys reconnection we'd override anyway, D reinvents parsing.

### Review record (2026-09-04): Option A confirmed

Reviewer question: how do OpenAPI v3.2's native SSE support,
[microsoft/kiota#7435](https://github.com/microsoft/kiota/issues/7435), and
[dotnet/aspnetcore#64379](https://github.com/dotnet/aspnetcore/issues/64379)
compare to the options above? **All three reinforce the Option A split** —
none of them builds the client half:

- **OpenAPI 3.2 media types**
  ([spec](https://learn.openapis.org/specification/media-types.html)) — native
  `text/event-stream` support via the Media Type Object's `itemSchema`.
  Annotation-level only, as already noted: it describes the stream, it
  generates nothing. Adopted at the spec level (Phase 1 step 4); no
  client-construction impact.
- **microsoft/kiota#7435** — feature request for SSE support in generated
  clients; open, untriaged (`status:waiting-for-triage`), no .NET workaround
  offered. Confirms the SSE half stays hand-built (Option A). Kept as a
  future-codegen watch item.
- **dotnet/aspnetcore#64379** — closed/implemented (PR #67461), but it is
  *server-side* OpenAPI 3.2 doc generation for Minimal-API SSE responses
  (`SseItems`), not a client surface. The client-side BCL story remains
  `SseParser<T>` — already included in Option A. Becomes relevant if
  `.ApiService` re-exposes streams as its own SSE endpoints.

### Build shape

```csharp
// QwenDaemon.Client/Streaming
QwenEventStream stream = client.StreamEvents(sessionId, o => o.MaxQueued(512));
await foreach (QwenDaemonEvent ev in stream.EventsAsync(ct)) { /* typed switch */ }
// owns: bearer on connect, Last-Event-ID resume, maxQueued, backoff,
// slow_client_warning → proactive reconnect, unknown-event tolerance,
// history_truncated surfacing
```

Tests: parser mapping fixtures; reconnect-after-drop (test server that severs
connections); `slow_client_warning` triggers reconnect; replay gap surfaces
`history_truncated`; cancellation/Aspire lifecycle.

## Phase 4 — Aspire orchestration

- Model `qwen-serve` as an **external resource**: the daemon is systemd-managed
  on the VM (Feature 1 of the system-setup plan), so AppHost declares it as a
  parameterized endpoint (base URL) + secret (token) — not an Aspire-owned
  process. Health probe: `GET /health` with bearer.
- Config flow: token from user secrets/environment in dev → Aspire config →
  client registration; no token in source.
- Dev loops: local `qwen serve` (loopback, zero-config) vs the tailnet daemon —
  both targets via configuration.
- **Swagger UI page:** the consuming app serves a Swagger UI page configured
  from `specs/qwen-serve.openapi.json` (e.g. Swashbuckle or Scalar behind a
  spec route), with its server URL pointed at the configured qwen daemon
  endpoint (loopback daemon in dev, tailnet URL in prod) so the daemon API is
  explorable and callable with the bearer token from inside the app.
- If `.ApiService` re-exposes streams as its own SSE endpoints, ASP.NET Core's
  native OpenAPI 3.2 SSE doc generation (dotnet/aspnetcore#64379) covers them.

## Packaging (NuGet)

Exactly **one** project is a packageable library — `QwenDaemon.Client`; the
rest are executables or internal shared code:

| Project | Kind | NuGet package? |
|---|---|---|
| `QwenDaemon.Client` | class library: Generated + Streaming + Events | **Yes — the only package** |
| `<App>.ServiceDefaults` | class library (Aspire convention) | No — project-reference only |
| `<App>.AppHost` | executable (Aspire orchestration) | No |
| `<App>.ApiService` | executable (ASP.NET Core API) | No |
| `<App>.Web` | executable (Blazor frontend) | No |

Packaging requirements for `QwenDaemon.Client`: strict SemVer versioning, XML
docs, Source Link; `dotnet pack` verified in CI. Embedding
`qwen-serve.openapi.json` as package content (spec traceability for
consumers) is a development-plan decision.

## CI/CD (per `.agents/rules/ci-cd.md`)

The `qwen-sdk-dotnet` pipeline enforces the mandatory floors:

1. **Build + automated test suite** (xUnit, coverlet, ReportGenerator per the
   stack file) with the **> 85% coverage gate** and an **HTML coverage report
   artifact**.
2. **Static analysis + security scanning** — .NET analyzers/`dotnet format`
   check, Spectral lint on the OpenAPI spec, gitleaks secret scan, markdownlint
   on docs; exact tool pins (this repo's CI pins are the starting point).
3. **Strict version pinning** for all dependencies, tools, and images; every
   workflow `uses:` line SHA-pinned with the trailing `# vX.Y.Z` comment (tag
   refs prohibited).
4. A root `validation.ps1` mirroring the pipeline exactly (build → scan →
   test), per `.agents/rules/validation.md`, with TDD for new features.
5. **Live-daemon contract suite** — needs tailnet access + bearer token, so it
   runs on workflow dispatch/schedule on a runner that can reach the daemon
   (token as a repo secret), and on every daemon version bump; otherwise
   locally via the validation script.

## Validation plan

| Phase | Gate |
|---|---|
| 1 | Spectral lint clean; `kiota show` renders the path tree; contract suite green against the live daemon (all spec paths probed) |
| 2 | `kiota generate` reproducible (lock file); REST round-trip integration test green; builds with 0 warnings |
| 3 | SSE unit + reconnect suite green; live soak: prompt → events observed → kill/reconnect resumes via `Last-Event-ID` |
| 4 | `aspire run` brings up the app wired to the tailnet daemon; health + one end-to-end session from the app UI/API; Swagger UI page serves the spec pointed at the daemon |
| Pack/CI | `dotnet pack` clean for `QwenDaemon.Client`; pipeline green — tests, coverage > 85% + HTML artifact, scanning; `validation.ps1` mirrors CI |

## Risks & resolved items

- **Spec drift:** upstream owns no versioned contract; daemon upgrades can shift
  shapes. Detection: contract suite (Phase 1.5) runs on every daemon bump; spec
  regenerates from the pinned SDK tag, never from memory.
  **Reconciliation (resolved 2026-09-04):** repair is a repeatable pipeline,
  scripted per repo convention (pwsh under `specs/scripts/`) so it can run now
  and on every future drift event:
  1. `Build-QwenOpenApiSpec.ps1` — bump the pinned SDK/daemon version →
     re-extract schemas → route inventory → semantics overlay → assemble spec →
     Spectral lint → `kiota show`.
  2. `Update-QwenKiotaClient.ps1` — `kiota generate` from the lock file →
     build → unit tests.
  3. Contract suite against the live daemon → commit spec + regenerated client
     together. The upgrade runbook is these three steps, written down.
  Wrapping 1+2 as a repo-local agent skill is optional polish — decide in the
  development plan.
- **SSE in OpenAPI is annotation-only** — even 3.2's native `itemSchema`
  describes the stream without generating a client; the event DTO schemas are
  ours to maintain, and their codegen path is a small custom generator or
  hand-synced partials (decide during Phase 1.4).
- **Kiota validation rules** may complain about the spec's exotic corners
  (`--disable-validation-rules` exists but prefer fixing the spec).
- **Resolved (2026-09-04):** app repo = **`qwen-sdk-dotnet`**. Scaffolding does
  not go through `create-app-plan` — the legacy orchestration framework is
  defunct; the next deliverable is a detailed development plan in a markdown
  file. Stack file `dotnet-aspire-aspnet-blazor` confirmed.
- **Resolved (2026-09-04):** consuming-app scope = the Aspire
  `Starter App (ASP.NET Core/Blazor)` template shape — `.Web` (Blazor
  frontend) + `.ApiService` (ASP.NET Core API) + AppHost + ServiceDefaults.
  (Answer to "what's the difference?": *web dashboard* scoped the client to a
  UI-only consumer; *API service* scoped it to a backend that wraps the client
  behind its own API. The starter template wires both — Web → ApiService →
  daemon — so the dichotomy dissolves.) Concrete feature requirements are
  defined in the development plan.
- **Resolved (2026-09-04):** NuGet packaging — exactly one packageable library
  project, `QwenDaemon.Client` (see Packaging section).
- **Resolved (2026-09-04):** CI — automated testing and scanning are mandatory
  floors (see CI/CD section, per `.agents/rules/ci-cd.md`).

## Acceptance criteria

- [ ] `specs/qwen-serve.openapi.json` committed, lint-clean, `kiota show`-valid, contract-proven against daemon 0.22.3.
- [ ] Kiota REST client generated + committed with lock file; bearer auth; REST round-trip test green.
- [ ] `QwenEventStream` (Option A) implemented with typed events from the shared schemas; reconnect/replay/backpressure tests green; live soak passed.
- [ ] Aspire AppHost runs the consuming app against the tailnet daemon with health-checked wiring; Swagger UI page serves `qwen-serve.openapi.json` pointed at the daemon.
- [ ] `QwenDaemon.Client` packs cleanly (`dotnet pack`): strict version, XML docs, Source Link.
- [ ] CI pipeline green: tests, coverage > 85% + HTML report artifact, static analysis + security scanning; root `validation.ps1` mirrors it.
- [ ] Upgrade runbook: daemon bump → re-extract → regenerate → contract suite, documented in the new repo and driven by `Build-QwenOpenApiSpec.ps1` / `Update-QwenKiotaClient.ps1`.
- [x] Detailed development plan for `qwen-sdk-dotnet` written (markdown) — [`qwen-sdk-dotnet-development-plan.md`](./qwen-sdk-dotnet-development-plan.md), drafted 2026-09-04, pending approval.
