# **New Application Implementation Specification**

## **App Title**

**Qwen Daemon .NET Client (qwen-sdk-dotnet)**

## **Development Plan**

Detailed architectural, engineering, and phased implementation plan for building a typed, high-performance .NET 10 Aspire client and SDK ecosystem that interfaces programmatically with the qwen serve background daemon. The project delivers an automated OpenAPI 3.2 REST client generation pipeline via Microsoft Kiota, a custom-built resilient Server-Sent Events (SSE) streaming engine, an Aspire starter dashboard with Swagger/Scalar exploration, and enterprise CI/CD verification.

## **Description**

### **Overview**

The qwen-sdk-dotnet ecosystem provides a robust, idiomatic .NET client for the qwen serve daemon (protocol v1, supporting 128 capability keys). Because upstream publishes no machine-readable OpenAPI or Swagger specifications—relying instead on a \~293 KB markdown reference, dynamic runtime capabilities, and TypeScript SDK definitions—this application implements a dual-layer architectural model:

1. **REST Protocol Layer (Generated via Kiota):** A hand-built, maximally annotated OpenAPI 3.2 specification authored from TypeScript SDK type extractions (@qwen-code/sdk), daemon route AST inspections, and live daemon contract probes. The REST client is compiled via Microsoft Kiota (\>= v1.30.0) with committed lockfiles and centralized package management.  
2. **Real-Time Streaming Layer (Custom Resilient Engine):** A hand-built, high-throughput SSE consumer built on the Base Class Library's (BCL) System.Net.ServerSentEvents.SseParser\<T\>. It implements ring-buffer replay reconciliation (Last-Event-ID), daemon backpressure buffer tracking (?maxQueued=16..2048), proactive reconnect on slow\_client\_warning, unknown-event resilience, and lifecycle-aware cancellation tokens.  
3. **Consuming Application & Orchestration:** Built upon the .NET Aspire Starter App model (AppHost, ServiceDefaults, ApiService, and Web Blazor frontend), treating the systemd-managed Qwen daemon as an authenticated external resource with integrated health probes and an interactive API documentation explorer.

### **Document Links**

1. Upstream Protocol Reference: developers/qwen-serve-protocol (Qwen Code documentation)  
2. Upstream TypeScript SDK Reference: @qwen-code/sdk@0.1.8 (KnownDaemonEvent definitions)  
3. Daemon System Service Unit: deploy/systemd/qwen-serve.service (100.118.225.119:4170)  
4. OpenAPI 3.2 Specification: specs/qwen-serve.openapi.json  
5. Kiota Generation Lock: QwenDaemon.Client/Generated/kiota-lock.json  
6. Validation Script: validation.ps1

### **Requirements**

* **Target Daemon Environment:** Target daemon running at 100.118.225.119:4170 (qwen version 0.22.3, protocol v1, advertising typed\_event\_schema).  
* **Authentication:** Mandatory static bearer token authorization (Authorization: Bearer \<token\>) passed across all REST endpoints, SSE streams, and health probes (--require-auth enabled).  
* **Single Source of Truth:** OpenAPI 3.2 document acts as the definitive contract for REST operations and shares its components.schemas with the streaming event DTO models.  
* **Resilient SSE Replay:** Client must persist and track Last-Event-ID across disconnections to enable ring-buffer replay (daemon default ring size: 8,000 events) and detect history\_truncated markers.  
* **Adaptive Backpressure:** Monitor stream queues (sizing 16–2048, default 256\) and execute proactive drain-and-reconnect routines upon receiving slow\_client\_warning (emitted at 75% queue fill).  
* **Zero-Warning Codebase:** Compilation under C\# 13 / .NET 10 LTS with \<TreatWarningsAsErrors\>true\</TreatWarningsAsErrors\> and nullable reference types enabled.  
* **Automated Drift Reconciliation:** Scripted pipeline to re-extract schemas, re-inventory routes, update OpenAPI specs, and regenerate Kiota clients upon daemon version increments.

### **Features**

* \[x\] **Test cases:** Unit test suite (xUnit, NSubstitute), live daemon contract test suite (QwenSdkDotNet.ContractTests), and integration soak tests.  
* \[x\] **Logging:** Structured logging across REST and SSE layers utilizing Microsoft.Extensions.Logging and OpenTelemetry via Aspire ServiceDefaults.  
* \[x\] **Containerization (Docker):** Multi-stage production Dockerfile for the .Web and .ApiService applications using .NET 10 distroless base images.  
* \[x\] **Containerization (Docker Compose):** Local integration compose manifests enabling mock/staging daemon containers with custom bearer tokens.  
* \[x\] **Swagger/OpenAPI:** Embedded OpenAPI 3.2 specification served via Swagger UI and Scalar interactive documentation in the Blazor portal.  
* \[x\] **Documentation:** Comprehensive XML documentation comments on all public types, drift reconciliation runbook, and Markdown architectural guides.

## **Acceptance Criteria**

1. specs/qwen-serve.openapi.json compiles as valid OpenAPI 3.2, passes Spectral linting without errors, successfully executes kiota show, and passes 100% of live contract probe tests against 100.118.225.119:4170.  
2. QwenDaemon.Client REST client is generated via Microsoft Kiota (\>= v1.30.0), maintains a valid kiota-lock.json, authenticates via static bearer token, and completes end-to-end session lifecycle workflows (Create Session ![][image1] Send Prompt ![][image1] Read Status ![][image1] Terminate Session).  
3. QwenEventStream successfully parses SSE streams using System.Net.ServerSentEvents.SseParser\<T\>, cleanly deserializes typed QwenDaemonEvent models, handles unknown event types gracefully, and survives network drops by resuming via Last-Event-ID.  
4. The SSE layer detects slow\_client\_warning payloads and executes a proactive drain-and-reconnect sequence without dropping active prompt execution chunks.  
5. The .NET Aspire solution (QwenSdkDotNet.AppHost) models the external daemon, passes /health probes, and orchestrates seamless communication from Web ![][image1] ApiService ![][image1] QwenDaemon.Client ![][image1] qwen serve.  
6. Code coverage across unit and client tests strictly exceeds **85%**, producing verifiable HTML reports via ReportGenerator.  
7. QwenDaemon.Client packs cleanly (dotnet pack) with strict SemVer, embedded README, Source Link metadata, and XML documentation.  
8. The drift reconciliation scripts (Build-QwenOpenApiSpec.ps1 and Update-QwenKiotaClient.ps1) execute idempotently from PowerShell 7+.

## **Language**

**C\#**

## **Language Version**

**.NET 10.0 (C\# 13\)**

* \[x\] Include global.json:

{  
  "sdk": {  
    "version": "10.0.400",  
    "rollForward": "latestFeature"  
  }  
}

## **Frameworks, Tools, Packages**

### **Core Runtime & SDKs**

* **.NET SDK:** 10.0.400 LTS  
* **.NET Aspire:** 13.x Aspire Hosting and Component Stack  
* **Target Framework Moniker (TFM):** net10.0

### **Client & Protocol Libraries**

* **Microsoft.Kiota.Bundle:** (\>= 1.30.0) Unified Kiota HTTP, serialization, and abstraction bundle  
* **System.Net.ServerSentEvents:** Native BCL SSE parsing (SseParser\<T\>)  
* **Scalar.AspNetCore / Swashbuckle.AspNetCore:** OpenAPI interactive API exploration

### **Testing & Code Quality**

* **xUnit:** 2.9.x Unit and Contract Testing  
* **NSubstitute:** 5.3.x Mocking framework  
* **FluentAssertions:** 6.12.x Assertion engine  
* **bunit:** 1.38.x Blazor Component Testing  
* **Coverlet.collector:** Code coverage instrumentation  
* **ReportGenerator:** 5.4.x HTML coverage reporting

### **Build & Scripting Tools**

* **Microsoft Kiota CLI:** dotnet tool pinned \>= v1.30.0  
* **Spectral CLI (@stoplight/spectral-cli):** OpenAPI linting  
* **ts-json-schema-generator:** TypeScript AST to JSON Schema compiler  
* **PowerShell (pwsh):** Core automation and drift pipeline scripting  
* **Gitleaks:** v8.21.2 Secret scanning  
* **markdownlint-cli2:** 0.22.1 Documentation linting

## **Project Structure / Package System**

Central Package Management (CPM) is enforced via Directory.Packages.props. Directory.Build.props enforces unified analyzer rules, nullability, and packaging standards.

qwen-sdk-dotnet/  
├── .github/  
│   └── workflows/  
│       ├── ci.yml                     \# SHA-pinned CI pipeline (build, test, scan, coverage gate)  
│       └── contract-tests.yml         \# Scheduled/dispatch live daemon contract suite  
├── .agents/                           \# Agent memory, coding standards, and validation rules  
├── specs/  
│   ├── qwen-serve.openapi.json        \# The hand-crafted OpenAPI 3.2 specification  
│   ├── spectral.yml                   \# Spectral linting ruleset  
│   └── scripts/  
│       ├── Build-QwenOpenApiSpec.ps1  \# Extracts schemas, inventories routes, builds spec  
│       ├── Update-QwenKiotaClient.ps1 \# Drives Kiota codegen from lockfile & runs verification  
│       └── Extract-SdkSchemas.js      \# ts-json-schema-generator bridge for @qwen-code/sdk  
├── src/  
│   ├── QwenDaemon.Client/             \# \[THE DELIVERABLE NUGET PACKAGE\]  
│   │   ├── Auth/  
│   │   │   └── StaticBearerAuthenticationProvider.cs  
│   │   ├── Events/                    \# Strongly typed SSE event records & polymorphic unions  
│   │   │   ├── QwenDaemonEvent.cs  
│   │   │   ├── AgentMessageChunkEvent.cs  
│   │   │   ├── SlowClientWarningEvent.cs  
│   │   │   └── HistoryTruncatedEvent.cs  
│   │   ├── Generated/                 \# Output of Kiota generation (committed)  
│   │   │   ├── kiota-lock.json  
│   │   │   └── QwenDaemonClient.cs  
│   │   ├── Streaming/                 \# Hand-built SSE resilience & replay layer  
│   │   │   ├── IQwenEventStream.cs  
│   │   │   ├── QwenEventStream.cs  
│   │   │   ├── QwenStreamOptions.cs  
│   │   │   └── ReconnectionPolicy.cs  
│   │   ├── Extensions/  
│   │   │   └── ServiceCollectionExtensions.cs  
│   │   └── QwenDaemon.Client.csproj  
│   ├── QwenSdkDotNet.AppHost/         \# Aspire Orchestrator (external daemon resource model)  
│   ├── QwenSdkDotNet.ServiceDefaults/ \# Aspire telemetry, health checks, and resilience  
│   ├── QwenSdkDotNet.ApiService/      \# ASP.NET Core API wrapping client operations  
│   └── QwenSdkDotNet.Web/             \# Blazor Web App (Interactive dashboard & Swagger UI)  
├── tests/  
│   ├── QwenDaemon.Client.Tests/       \# Unit tests: SSE parser, backpressure, reconnect loops  
│   │   ├── Streaming/  
│   │   ├── Auth/  
│   │   └── Deserialization/  
│   └── QwenSdkDotNet.ContractTests/   \# Integration & Contract tests against live daemon  
│       ├── Contract/  
│       └── LiveSoak/  
├── Directory.Build.props              \# Global build settings, warnings-as-errors, deterministic builds  
├── Directory.Packages.props            \# Central Package Management (CPM)  
├── global.json                        \# Locked .NET SDK 10.0.400  
├── validation.ps1                     \# Local mirror of GitHub Actions CI pipeline  
└── README.md

## **GitHub**

### **Repo**

https://github.com/nam20485/qwen-sdk-dotnet

### **Branch**

* **Default/Base Branch:** main  
* **Feature Branches:** dev/e\<Epic\#\>-\<feature-slug\> (e.g., dev/e1-openapi-spec, dev/e3-sse-streaming)

## **Deliverables**

1. **QwenDaemon.Client NuGet Package:** Fully packaged, Source Link-enabled, XML-documented .NET 10 class library.  
2. **specs/qwen-serve.openapi.json:** Comprehensive OpenAPI 3.2 specification capturing 100% of daemon routes and event schemas.  
3. **PowerShell Automation Engine:** Repeatable drift reconciliation scripts (Build-QwenOpenApiSpec.ps1, Update-QwenKiotaClient.ps1).  
4. **Complete Test Suite & Coverage Reports:** Unit, contract, and soak test suites maintaining ![][image2] code coverage.  
5. **.NET Aspire Reference Application:** Executable AppHost, ApiService, and Web dashboard demonstrating live streaming and prompt interaction.  
6. **Local & CI Validation Harness:** Root validation.ps1 and SHA-pinned .github/workflows/ci.yml.

# **User Story Epic Templates**

\# Epic Title: OpenAPI 3.2 Specification Engineering & Contract Verification

\#\# 1\. Epic Summary & Goal  
The Qwen background daemon (\`qwen serve\`) lacks an authoritative machine-readable schema, providing only runtime capability queries and raw TypeScript types. This epic constructs an exhaustive, lint-verified OpenAPI 3.2 specification (\`qwen-serve.openapi.json\`) by combining TypeScript AST schema extraction, daemon route decompilation/inspection, and protocol markdown overlays. The resulting specification serves as the single source of truth for both REST client generation and SSE event contracts, validated against the live daemon running on the network.

\*\*Core User Value Proposition:\*\*  
\- \*\*As an\*\* SDK Developer,  
\- \*\*I want\*\* a rich, validated OpenAPI 3.2 document reflecting all REST routes and SSE payload models,  
\- \*\*So that\*\* client code generators can produce typed, drift-resistant communication layers without guesswork.

\#\# 2\. Personas Involved  
\- \*\*Primary Persona:\*\* SDK Infrastructure Developer (builds, verifies, and maintains client generators and specs).  
\- \*\*Secondary Persona:\*\* Solutions Architect (audits API contracts, security configurations, and capability matrices).

\#\# 3\. User Stories (The "What")  
\- \*\*Story 1: Automated TypeScript Schema Extraction\*\*    
  \*\*As an\*\* SDK Developer,    
  \*\*I want\*\* a script that extracts JSON schemas from \`@qwen-code/sdk@0.1.8\`,    
  \*\*So that\*\* all request, response, and event DTOs match upstream TypeScript definitions exactly.  
\- \*\*Story 2: Daemon Route Inventory Extraction\*\*    
  \*\*As an\*\* SDK Developer,    
  \*\*I want\*\* to extract HTTP bridge route registrations from \`QwenLM/qwen-code\` at release \`0.22.3\`,    
  \*\*So that\*\* all undocumented parameters, error status codes, and path variables are accurately declared.  
\- \*\*Story 3: OpenAPI 3.2 Assembly & SSE Media Type Modeling\*\*    
  \*\*As an\*\* SDK Developer,    
  \*\*I want\*\* to assemble an OpenAPI 3.2 specification utilizing the \`text/event-stream\` media type and \`itemSchema\`,    
  \*\*So that\*\* streaming payloads are formally coupled to the REST contract.  
\- \*\*Story 4: Automated Contract Test Harness\*\*    
  \*\*As a\*\* Quality Engineer,    
  \*\*I want\*\* an automated test suite that executes HTTP probes against the live daemon for every defined route,    
  \*\*So that\*\* any breaking API drift between the daemon and specification is caught immediately.

\#\# 4\. Acceptance Criteria (The "Proof of Done")  
\- \*\*Scenario 1: Spectral Spec Validation\*\*  
  \- \*\*Given\*\* the assembled \`specs/qwen-serve.openapi.json\` file.  
  \- \*\*When\*\* the Spectral linter executes with the custom rule file.  
  \- \*\*Then\*\* zero errors and zero warnings must be emitted.  
  \- \*\*And\*\* \`kiota show \-d specs/qwen-serve.openapi.json\` must render the full route tree without exceptions.  
\- \*\*Scenario 2: Live Contract Probe Execution\*\*  
  \- \*\*Given\*\* a reachable daemon at \`100.118.225.119:4170\` and a valid bearer token in \`\~/.qwen-serve-token\`.  
  \- \*\*When\*\* \`QwenSdkDotNet.ContractTests\` executes against the endpoint.  
  \- \*\*Then\*\* all documented routes (\`/health\`, \`/capabilities\`, \`/session\`, \`/workspaces\`) return matching HTTP status codes and payloads conforming to schema definitions.  
\- \*\*Scenario 3: Route Mismatch Detection\*\*  
  \- \*\*Given\*\* an invalid or drifted parameter type in the OpenAPI spec.  
  \- \*\*When\*\* the contract test suite executes.  
  \- \*\*Then\*\* the test assertion fails with a detailed JSON diff identifying the schema discrepancy.

\#\# 5\. Non-Functional Requirements (NFRs)  
\- \*\*Performance:\*\* Schema extraction and spec assembly scripts must execute in $\< 15$ seconds on standard developer hardware.  
\- \*\*Security:\*\* Secret tokens must never be hardcoded into the OpenAPI specification file or committed scripts; all paths must accept bearer auth references.  
\- \*\*Maintainability:\*\* The extraction script must accept parameterized SDK versions and daemon Git tags to enable zero-friction upgrades.

\#\# 6\. Out of Scope  
\- Direct upstream PR submissions to \`QwenLM/qwen-code\`.  
\- Generating AsyncAPI 3.0 documents (deferred due to lack of .NET codegen support).

\#\# 7\. UI/UX Considerations  
\- Developer Experience: The OpenAPI specification must contain rich descriptions, parameter examples, and cross-references for every route to enhance IntelliSense and Swagger UI usability.

\# Epic Title: Typed Kiota REST Client & Authentication Engine

\#\# 1\. Epic Summary & Goal  
Using the OpenAPI 3.2 specification produced in Epic 1, this epic generates and configures the typed C\# REST client utilizing Microsoft Kiota (\`\>= v1.30.0\`). It establishes the static bearer authentication mechanism, HTTP connection pooling via \`IHttpClientFactory\`, and fluent request execution patterns. The output is a strongly typed, clean-compiled class library capable of executing session, workspace, and prompt commands.

\*\*Core User Value Proposition:\*\*  
\- \*\*As an\*\* Application Developer,  
\- \*\*I want\*\* a strongly typed, auto-generated C\# client for \`qwen serve\`'s REST API,  
\- \*\*So that\*\* I can manage sessions, prompt runs, and workspace files with compile-time type safety.

\#\# 2\. Personas Involved  
\- \*\*Primary Persona:\*\* Application Backend Developer (integrates Qwen daemon calls into enterprise workflows).  
\- \*\*Secondary Persona:\*\* DevOps Engineer (configures connection strings, tokens, and telemetry).

\#\# 3\. User Stories (The "What")  
\- \*\*Story 1: Deterministic Kiota Codegen Integration\*\*    
  \*\*As an\*\* SDK Developer,    
  \*\*I want\*\* Kiota generation committed to \`QwenDaemon.Client/Generated\` along with \`kiota-lock.json\`,    
  \*\*So that\*\* builds remain 100% deterministic across developer machines and CI pipelines.  
\- \*\*Story 2: Static Bearer Authentication Provider\*\*    
  \*\*As a\*\* Security Engineer,    
  \*\*I want\*\* an implementation of \`IAuthenticationProvider\` that injects static bearer credentials,    
  \*\*So that\*\* all outbound REST calls are authenticated without relying on interactive OAuth or Azure identity flows.  
\- \*\*Story 3: Aspire Service Collection Extensions\*\*    
  \*\*As an\*\* Application Developer,    
  \*\*I want\*\* an \`AddQwenClient()\` extension method for \`IServiceCollection\`,    
  \*\*So that\*\* the client is configured cleanly via \`IConfiguration\` with structured resilience and timeouts.  
\- \*\*Story 4: End-to-End Session REST Lifecycle Integration\*\*    
  \*\*As an\*\* Application Developer,    
  \*\*I want\*\* to execute Create Session, Load Metadata, Send Prompt, and Delete Session operations,    
  \*\*So that\*\* the client manages complete daemon lifecycles reliably.

\#\# 4\. Acceptance Criteria (The "Proof of Done")  
\- \*\*Scenario 1: Deterministic Compilation\*\*  
  \- \*\*Given\*\* a clean clone of the repository without local tools pre-cached.  
  \- \*\*When\*\* \`dotnet build\` executes on \`QwenDaemon.Client.csproj\`.  
  \- \*\*Then\*\* the project builds with 0 errors and 0 warnings.  
  \- \*\*And\*\* the committed Kiota generated files match \`kiota-lock.json\`.  
\- \*\*Scenario 2: Authenticated REST Call Success\*\*  
  \- \*\*Given\*\* an injected \`QwenDaemonClient\` configured with a valid bearer token.  
  \- \*\*When\*\* calling \`client.Session.PostAsync(sessionCreateRequest)\`.  
  \- \*\*Then\*\* the daemon responds with HTTP 200 OK and a valid \`SessionResponse\` containing a non-empty \`sessionId\`.  
\- \*\*Scenario 3: Handled Daemon Errors (503 / 504)\*\*  
  \- \*\*Given\*\* a saturated daemon event queue.  
  \- \*\*When\*\* submitting a prompt request.  
  \- \*\*Then\*\* the Kiota client throws an \`ApiException\` deserializing the daemon's \`503 prompt\_queue\_full\` envelope.

\#\# 5\. Non-Functional Requirements (NFRs)  
\- \*\*Performance:\*\* Serialization and deserialization overhead must add $\< 5\\text{ms}$ per request on standard payloads.  
\- \*\*Security:\*\* Static bearer tokens must be passed securely in memory using secure string patterns or non-logged string references.  
\- \*\*Reliability:\*\* HTTP clients must utilize standard socket pooling to prevent socket exhaustion under high concurrency.

\#\# 6\. Out of Scope  
\- Generation of Azure Entra ID / OAuth 2.0 token acquisition flows.  
\- Multi-daemon load balancing at the client layer.

\#\# 7\. UI/UX Considerations  
\- Fluent API style: Method chaining and path navigation must follow standard Kiota conventions (e.g., \`client.Session\[id\].Prompt.PostAsync(...)\`).

\# Epic Title: Resilient Real-Time Server-Sent Events (SSE) Streaming Layer

\#\# 1\. Epic Summary & Goal  
The Qwen daemon delivers real-time token generation, agent thoughts, workspace updates, and permission prompts over Server-Sent Events via \`GET /session/:id/events\`. Because OpenAPI tools (including Kiota) do not generate reactive streaming clients, this epic delivers a custom, resilient streaming engine built on .NET's \`System.Net.ServerSentEvents.SseParser\<T\>\`. It implements ring-buffer replay reconciliation (\`Last-Event-ID\`), daemon backpressure buffer tracking (\`?maxQueued=16..2048\`), proactive reconnect on \`slow\_client\_warning\`, unknown-event resilience, and lifecycle-aware cancellation tokens.

\*\*Core User Value Proposition:\*\*  
\- \*\*As an\*\* AI Application Developer,  
\- \*\*I want\*\* to consume an asynchronous stream of typed daemon events (\`IAsyncEnumerable\<QwenDaemonEvent\>\`),  
\- \*\*So that\*\* I can stream agent message tokens and thoughts to end-users without dropped packets or transport freezes.

\#\# 2\. Personas Involved  
\- \*\*Primary Persona:\*\* Full-Stack AI Engineer (builds streaming chat interfaces and real-time execution dashboards).  
\- \*\*Secondary Persona:\*\* System Reliability Engineer (monitors stream stability, drops, and reconnect rates).

\#\# 3\. User Stories (The "What")  
\- \*\*Story 1: High-Performance SSE Parser Implementation\*\*    
  \*\*As an\*\* SDK Developer,    
  \*\*I want\*\* to parse raw HTTP event streams using \`System.Net.ServerSentEvents.SseParser\<T\>\`,    
  \*\*So that\*\* multiline data, event types, and IDs are processed with zero allocations where possible.  
\- \*\*Story 2: Reconnection & Last-Event-ID State Tracking\*\*    
  \*\*As an\*\* Application Developer,    
  \*\*I want\*\* the client to automatically reconnect when a connection drops, supplying the \`Last-Event-ID\` header,    
  \*\*So that\*\* unread events in the daemon's ring buffer are replayed without data loss.  
\- \*\*Story 3: Adaptive Backpressure & Slow Client Mitigation\*\*    
  \*\*As a\*\* System Engineer,    
  \*\*I want\*\* the stream to trigger an immediate, graceful reconnect when a \`slow\_client\_warning\` event arrives,    
  \*\*So that\*\* the client avoids eviction from the daemon's buffer.  
\- \*\*Story 4: Truncation Detection & Unknown Event Tolerance\*\*    
  \*\*As an\*\* Application Developer,    
  \*\*I want\*\* unknown events to be safely logged/skipped and \`history\_truncated\` markers surfaced,    
  \*\*So that\*\* the application handles future protocol updates without crashing.

\#\# 4\. Acceptance Criteria (The "Proof of Done")  
\- \*\*Scenario 1: Continuous Event Stream Processing\*\*  
  \- \*\*Given\*\* an active session with an executing prompt.  
  \- \*\*When\*\* calling \`stream.EventsAsync(cancellationToken)\`.  
  \- \*\*Then\*\* the client yields typed \`AgentMessageChunkEvent\` instances matching incoming JSON tokens.  
\- \*\*Scenario 2: Automatic Reconnect on Network Severance\*\*  
  \- \*\*Given\*\* an active SSE stream connection that has received event ID \`42\`.  
  \- \*\*When\*\* the underlying TCP connection is abruptly severed by a mock server.  
  \- \*\*Then\*\* \`QwenEventStream\` re-establishes the HTTP connection using exponential backoff.  
  \- \*\*And\*\* includes \`Last-Event-ID: 42\` in the request headers.  
  \- \*\*And\*\* resumes event delivery without throwing an unhandled exception to the caller.  
\- \*\*Scenario 3: Handling Buffer Eviction (\`history\_truncated\`)\*\*  
  \- \*\*Given\*\* an SSE connection that has been disconnected longer than the daemon ring buffer retention.  
  \- \*\*When\*\* reconnecting.  
  \- \*\*Then\*\* the stream yields a \`HistoryTruncatedEvent\` alerting the consumer to refresh full state via REST.

\#\# 5\. Non-Functional Requirements (NFRs)  
\- \*\*Performance:\*\* Event dispatch latency inside the client must not exceed $2\\text{ms}$ between TCP packet arrival and enumeration yield.  
\- \*\*Memory:\*\* Zero buffer accumulation on the heap; streaming must process items sequentially without buffering entire response transcripts.  
\- \*\*Resilience:\*\* Default backoff policy must implement jittered exponential retry (e.g., $100\\text{ms} \\rightarrow 200\\text{ms} \\rightarrow 400\\text{ms} \\dots \\max 5\\text{s}$).

\#\# 6\. Out of Scope  
\- Webhook or WebSocket translation layers.  
\- Persisting received events to local databases (responsibility of the consuming app).

\#\# 7\. UI/UX Considerations  
\- Developer Experience: Idiomatic C\# \`await foreach\` consumption pattern:  
\`\`\`csharp  
await foreach (QwenDaemonEvent evt in client.StreamEventsAsync(sessionId, ct)) {  
    if (evt is AgentMessageChunkEvent chunk) Console.Write(chunk.Text);  
}

\`\`\`markdown  
\# Epic Title: Aspire Orchestration, API Service, and Interactive Web Portal

\#\# 1\. Epic Summary & Goal  
This epic implements the end-to-end consuming architecture using the .NET Aspire Starter App model. It encapsulates the daemon as an external managed resource in \`AppHost\`, provides an ASP.NET Core backend (\`ApiService\`) wrapping the client SDK, and delivers a Blazor frontend (\`Web\`) featuring interactive chat and live Swagger/Scalar OpenAPI exploration directly targeted at the Qwen daemon.

\*\*Core User Value Proposition:\*\*  
\- \*\*As a\*\* Developer or Operator,  
\- \*\*I want\*\* to launch the full Aspire application with a single command and explore daemon capabilities through an interactive UI,  
\- \*\*So that\*\* I can test prompts, inspect streaming events, and verify daemon health instantly.

\#\# 2\. Personas Involved  
\- \*\*Primary Persona:\*\* End-User / Developer (interacts with the Blazor interface to test models).  
\- \*\*Secondary Persona:\*\* System Administrator (monitors Aspire telemetry, dashboard metrics, and health checks).

\#\# 3\. User Stories (The "What")  
\- \*\*Story 1: External Daemon Resource Modeling in Aspire\*\*    
  \*\*As a\*\* DevOps Engineer,    
  \*\*I want\*\* \`AppHost\` to model \`qwen-serve\` as an external HTTP resource with a \`/health\` probe,    
  \*\*So that\*\* Aspire's dashboard displays real-time health and connection status for the background daemon.  
\- \*\*Story 2: ApiService Proxy & Gateway Endpoints\*\*    
  \*\*As an\*\* Application Developer,    
  \*\*I want\*\* \`ApiService\` to expose clean endpoints for session creation, prompt dispatching, and SSE forwarding,    
  \*\*So that\*\* the Blazor UI never interacts directly with raw daemon credentials.  
\- \*\*Story 3: Interactive Blazor Streaming Client\*\*    
  \*\*As an\*\* End-User,    
  \*\*I want\*\* a Blazor UI component that renders real-time token streaming and thought disclosure panels,    
  \*\*So that\*\* I can observe the agent reasoning process interactively.  
\- \*\*Story 4: Embedded OpenAPI / Scalar Explorer\*\*    
  \*\*As a\*\* Developer,    
  \*\*I want\*\* a dedicated page in the Blazor portal rendering the OpenAPI 3.2 specification via Scalar,    
  \*\*So that\*\* I can test ad-hoc REST calls directly against the configured daemon with pre-populated tokens.

\#\# 4\. Acceptance Criteria (The "Proof of Done")  
\- \*\*Scenario 1: Aspire Dashboard Health Verification\*\*  
  \- \*\*Given\*\* the Qwen daemon running on \`100.118.225.119:4170\`.  
  \- \*\*When\*\* launching the application via \`dotnet run \--project QwenSdkDotNet.AppHost\`.  
  \- \*\*Then\*\* the Aspire dashboard displays \`qwen-serve\` with a "Healthy" status.  
\- \*\*Scenario 2: End-to-End Chat Prompt Execution\*\*  
  \- \*\*Given\*\* the Blazor frontend loaded in a browser.  
  \- \*\*When\*\* the user types "List files in workspace" and clicks Send.  
  \- \*\*Then\*\* \`ApiService\` creates a session, forwards the prompt, receives SSE tokens, and streams them to the Blazor UI with $\< 100\\text{ms}$ initial latency.  
\- \*\*Scenario 3: OpenAPI UI Route Exploration\*\*  
  \- \*\*Given\*\* navigation to \`/scalar\` or \`/swagger\` in the web application.  
  \- \*\*When\*\* inspecting available endpoints.  
  \- \*\*Then\*\* the exact OpenAPI 3.2 schema from \`specs/qwen-serve.openapi.json\` is rendered with active "Try It Out" capabilities wired to the daemon.

\#\# 5\. Non-Functional Requirements (NFRs)  
\- \*\*Observability:\*\* OpenTelemetry traces and metrics must flow seamlessly into the Aspire dashboard for all inbound and outbound calls.  
\- \*\*Security:\*\* The Blazor frontend must never expose the raw daemon bearer token to browser clients; tokens are strictly managed by \`ApiService\` and server-side configurations.  
\- \*\*Responsiveness:\*\* Blazor Server / WebAssembly components must render streaming chunks smoothly at $\> 30\\text{fps}$ without UI thread hitching.

\#\# 6\. Out of Scope  
\- Production identity provider integration (e.g., Azure AD B2C / Keycloak).  
\- Multi-tenant workspace data persistence.

\#\# 7\. UI/UX Considerations  
\- Real-time token streaming should appear as a continuous typewriter effect.  
\- Collapsible accordions for \`\<agent\_thought\_chunk\>\` events to keep the primary message view uncluttered.

\# Epic Title: Packaging, CI/CD Quality Gates, and Drift Reconciliation Runbook

\#\# 1\. Epic Summary & Goal  
This epic hardens the repository into an enterprise-grade open-source package. It establishes strict CI/CD pipelines in GitHub Actions enforcing $\>85\\%$ code coverage, security scanning, tool version pinning, and package compilation. Crucially, it provides automated PowerShell runbooks for spec drift reconciliation when upstream releases new versions of \`qwen serve\`.

\*\*Core User Value Proposition:\*\*  
\- \*\*As a\*\* Maintainer,  
\- \*\*I want\*\* an automated drift-reconciliation workflow and strict CI quality gates,  
\- \*\*So that\*\* daemon upgrades can be incorporated safely with zero regression risk.

\#\# 2\. Personas Involved  
\- \*\*Primary Persona:\*\* Repository Maintainer (oversees releases, version bumps, and pipeline health).  
\- \*\*Secondary Persona:\*\* Security Auditor (reviews dependency chains, secret scans, and static analysis).

\#\# 3\. User Stories (The "What")  
\- \*\*Story 1: Automated Multi-Stage CI Pipeline\*\*    
  \*\*As a\*\* Maintainer,    
  \*\*I want\*\* GitHub Actions to enforce build verification, format checks, static security scans, and test execution,    
  \*\*So that\*\* unverified or non-compliant PRs cannot be merged.  
\- \*\*Story 2: Strict Coverage Quality Gate (\> 85%)\*\*    
  \*\*As a\*\* Quality Engineer,    
  \*\*I want\*\* Coverlet and ReportGenerator to fail the pipeline if total line coverage is below 85%,    
  \*\*So that\*\* high test fidelity is maintained across all core classes.  
\- \*\*Story 3: Automated Drift Reconciliation Scripting\*\*    
  \*\*As a\*\* Maintainer,    
  \*\*I want\*\* PowerShell scripts (\`Build-QwenOpenApiSpec.ps1\` and \`Update-QwenKiotaClient.ps1\`),    
  \*\*So that\*\* updating to a new daemon version is executed in a single command.  
\- \*\*Story 4: NuGet Packaging Automation\*\*    
  \*\*As a\*\* Consumer,    
  \*\*I want\*\* \`QwenDaemon.Client\` distributed as a properly versioned NuGet package with XML docs and Source Link,    
  \*\*So that\*\* I can consume the client in external .NET solutions effortlessly.

\#\# 4\. Acceptance Criteria (The "Proof of Done")  
\- \*\*Scenario 1: Quality Gate Pipeline Enforcement\*\*  
  \- \*\*Given\*\* a pull request that introduces untested code causing coverage to drop to 84.9%.  
  \- \*\*When\*\* the CI workflow executes.  
  \- \*\*Then\*\* the \`build-test-coverage\` job fails with an exit code indicating coverage floor violation.  
\- \*\*Scenario 2: Security & Linting Verification\*\*  
  \- \*\*Given\*\* a commit containing a mock API token or unformatted C\# code.  
  \- \*\*When\*\* the \`scan\` CI job runs.  
  \- \*\*Then\*\* Gitleaks or \`dotnet format \--verify-no-changes\` flags the error and stops the build.  
\- \*\*Scenario 3: Executing Drift Reconciliation Runbook\*\*  
  \- \*\*Given\*\* an upstream release bump (e.g., \`0.23.0\`).  
  \- \*\*When\*\* the maintainer executes \`./specs/scripts/Build-QwenOpenApiSpec.ps1 \-DaemonTag 0.23.0\`.  
  \- \*\*Then\*\* schemas are re-extracted, route diffs applied, Spectral linter verified, and Kiota clients regenerated cleanly.

\#\# 5\. Non-Functional Requirements (NFRs)  
\- \*\*Deterministic Builds:\*\* All GitHub Actions \`uses:\` actions must be SHA-pinned with trailing \`\# vX.Y.Z\` tags; dependencies must utilize CPM with locked versions.  
\- \*\*Compliance:\*\* Full compliance with \`.agents/rules/ci-cd.md\` and \`.agents/rules/validation.md\`.

\#\# 6\. Out of Scope  
\- Automatic deployment to public \`nuget.org\` without manual maintainer release tagging.

\#\# 7\. UI/UX Considerations  
\- Clear terminal progress logging in PowerShell scripts using ANSI colors and step counters (e.g., \`\[1/5\] Extracting TypeScript Schemas...\`).

# **Qwen Daemon .NET Client: Development Plan**

## **1\. Motivation & Guiding Principles**

### **Core Problem & Value Proposition**

The Qwen code assistant daemon (qwen serve) operates as an orchestration backbone for deep workspace introspection, autonomous shell and code modifications, and real-time agent execution. However, upstream provides no native SDK for .NET developers—only a TypeScript package and raw HTTP/SSE endpoints with dynamic capabilities.

The qwen-sdk-dotnet project bridges this gap, delivering an enterprise-ready, idiomatic .NET 10 client library and Aspire reference application. By blending automated OpenAPI 3.2 generation via Microsoft Kiota with a resilient, hand-built Server-Sent Events engine, .NET developers gain a type-safe, observable, and drift-tolerant interface to control Qwen sessions programmatically.

### **Guiding Principles**

1. **One Source of Truth per Half:** REST schemas are owned exclusively by specs/qwen-serve.openapi.json and compiled via Kiota. The SSE event contracts share the identical schema component models in QwenDaemon.Client/Events, guaranteeing that wire contracts never diverge.  
2. **Resilience over Naive Streaming:** Real-time event streams cannot rely on basic HTTP drops. Reconnection must track Last-Event-ID, honor daemon ring-buffer sizes, proactively mitigate eviction warnings (slow\_client\_warning), and gracefully ignore unknown event types.  
3. **Strict Quality Floors:** Zero-warning compilations (\<TreatWarningsAsErrors\>true\</TreatWarningsAsErrors\>), ![][image2] verified line coverage, SHA-pinned workflows, and Central Package Management are non-negotiable standards.  
4. **Deterministic Reproducibility:** Tooling versions (Kiota, Spectral, .NET SDK) and generated artifacts (kiota-lock.json) are committed to version control, ensuring any developer or CI runner reproduces identical builds.

## **2\. Architectural Decisions**

### **Architectural Summary**

The solution decouples the REST command-and-control surface from the reactive event stream. The REST client is generated using Microsoft Kiota (\>= v1.30.0) targeting an OpenAPI 3.2 specification. The streaming layer is implemented natively using .NET 10's Base Class Library System.Net.ServerSentEvents.SseParser\<T\> inside a custom resilience wrapper (QwenEventStream). The application tier is composed via .NET Aspire, modeling the daemon as an authenticated external resource.

\+-----------------------------------------------------------------------------------+  
|                            QwenSdkDotNet.AppHost                                  |  
|         (Aspire Orchestration \- External Daemon Resource & Health Probes)         |  
\+-----------------------------------------------------------------------------------+  
                                         |  
                     \+-------------------+-------------------+  
                     |                                       |  
                     v                                       v  
    \+---------------------------------+     \+----------------------------------+  
    |      QwenSdkDotNet.Web          |     |    QwenSdkDotNet.ApiService      |  
    |  (Blazor UI & Scalar Explorer)  |\<---\>|    (ASP.NET Core Proxy/API)      |  
    \+---------------------------------+     \+----------------------------------+  
                                                             |  
                                                             v  
                        \+----------------------------------------------------------+  
                        |                 QwenDaemon.Client (NuGet)                |  
                        |  \+-----------------------+   \+------------------------+  |  
                        |  |  Kiota REST Client    |   |    QwenEventStream     |  |  
                        |  |  (Generated from      |   |   (BCL SseParser\<T\>    |  |  
                        |  |   OpenAPI 3.2 Spec)   |   |   \+ Replay/Backoff)    |  |  
                        |  \+-----------------------+   \+------------------------+  |  
                        |              \\                            /              |  
                        |               \+------------+-------------+               |  
                        |                            |                             |  
                        |                            v                             |  
                        |             QwenDaemon.Client.Events                     |  
                        |          (Shared Typed Event DTO Models)                 |  
                        \+----------------------------------------------------------+  
                                                     |  
                                                     v (HTTP REST / SSE Stream \+ Bearer Auth)  
                        \+----------------------------------------------------------+  
                        |              External Target: qwen serve                 |  
                        |         (100.118.225.119:4170 \- Protocol v1)             |  
                        \+----------------------------------------------------------+

### **Alternatives Evaluated & Trade-offs**

#### **1\. REST Client Generation: Microsoft Kiota vs. NSwag / AutoRest / Hand-Rolled**

* **NSwag / AutoRest:** Evaluated for maturity. Rejected because neither natively supports OpenAPI 3.2 documents (itemSchema media type features), and their generated code models introduce heavier runtime dependencies and less flexible middleware customization.  
* **Hand-Rolled HttpClient Wrapper:** Considered for total control. Rejected due to the massive operational cost of maintaining \~40 endpoints, pagination, error envelopes, and query parameters manually against an evolving upstream daemon.  
* **Chosen Approach (Microsoft Kiota \>= v1.30.0):** Kiota generates lightweight, dependency-clean client code, utilizes standard System.Text.Json, supports OpenAPI 3.2 parsing, and supports lockfile-based change tracking (kiota-lock.json).

#### **2\. SSE Streaming: BCL SseParser\<T\> vs. Third-Party vs. BCL SseClient**

* **LaunchDarkly.EventSource:** Mature library with built-in reconnect. Rejected because it introduces external dependencies, only yields raw strings (requiring a secondary JSON deserialization pass), and its generic W3C reconnect semantics cannot handle daemon-specific ring-buffer eviction (slow\_client\_warning and history\_truncated).  
* **BCL SseClient:** Evaluated based on proposed .NET networking updates. Rejected because the high-level connection client is unreleased or unverifiable in the current .NET 10 preview runtime docs, risking project blockage.  
* **Fully Hand-Rolled Stream Parser:** Rejected because reimplementing UTF-8 byte chunking, multiline data: framing, and SSE carriage-return parsing reinvents what the BCL already provides.  
* **Chosen Approach (BCL System.Net.ServerSentEvents.SseParser\<T\> inside custom QwenEventStream):** Delivers a zero-dependency, high-speed parser. Wrapping it in our own thin (\~150 LOC) engine allows total control over Last-Event-ID tracking, ring-buffer replay, custom backoff, and proactive queue draining.

## **3\. Core Technologies**

* **Language:** C\# 13 (.NET 10 LTS, SDK 10.0.400). Chosen for modern language ergonomics (records, pattern matching), native memory efficiency (Span\<T\>, ReadOnlySequence\<T\>), and long-term enterprise support.  
* **Application Framework:** .NET Aspire (13.x). Standardizes orchestration, distributed telemetry (OpenTelemetry), and external resource management.  
* **Web Portal Framework:** Blazor Server / WebAssembly (Interactive Server Mode). Provides a responsive UI with direct server-side stream consumption.  
* **REST Codegen Engine:** Microsoft Kiota CLI (\>= 1.30.0) with Microsoft.Kiota.Bundle.  
* **Streaming Parser:** System.Net.ServerSentEvents (SseParser\<T\>).  
* **OpenAPI Tooling:** Spectral CLI (validation ruleset) and Scalar API Explorer.  
* **Test Frameworks:** xUnit 2.9, NSubstitute, FluentAssertions, bUnit.  
* **CI/CD Platform:** GitHub Actions with SHA-pinned dependencies.

## **4\. Phased Development Plan**

### **Phase 1: Repo Scaffold, CI Baseline & Tooling Lockdown (Epic E0)**

* **Objective:** Establish the repository structure, central package management, strict compiler flags, and an initial green CI pipeline before functional code is written.  
* **Tasks:**  
  1. Initialize nam20485/qwen-sdk-dotnet with .gitignore, global.json (SDK 10.0.400), and Directory.Build.props (\<Nullable\>enable\</Nullable\>, \<TreatWarningsAsErrors\>true\</TreatWarningsAsErrors\>).  
  2. Create Directory.Packages.props for Central Package Management (CPM).  
  3. Scaffold Aspire Starter solution: QwenSdkDotNet.AppHost, QwenSdkDotNet.ServiceDefaults, QwenSdkDotNet.ApiService, QwenSdkDotNet.Web.  
  4. Scaffold QwenDaemon.Client, QwenDaemon.Client.Tests, and QwenSdkDotNet.ContractTests.  
  5. Establish validation.ps1 mirroring CI: dotnet format \--verify-no-changes ![][image1] gitleaks ![][image1] markdownlint-cli2 ![][image1] dotnet build ![][image1] dotnet test.  
  6. Configure .github/workflows/ci.yml with SHA-pinned actions and coverage threshold (![][image2]).  
* **Deliverables:** Fully green empty build pipeline and local validation harness.

### **Phase 2: OpenAPI 3.2 Engineering & Live Contract Suite (Epic E1)**

* **Objective:** Author specs/qwen-serve.openapi.json from TypeScript definitions and daemon source code; verify all contracts against the live daemon at 100.118.225.119:4170.  
* **Tasks:**  
  1. Create specs/scripts/Extract-SdkSchemas.js to execute ts-json-schema-generator against @qwen-code/sdk@0.1.8 exports (KnownDaemonEvent, requests, responses).  
  2. Inventory routes, path variables, query flags (maxQueued), and HTTP bridge error envelopes from QwenLM/qwen-code (release 0.22.3).  
  3. Overlay protocol semantics: document 503 prompt\_queue\_full, 504 session\_restore\_timeout, bearer auth requirements, and capability requirements.  
  4. Model GET /session/:id/events under OpenAPI 3.2 utilizing text/event-stream with itemSchema referencing the event discriminated union; add x-sse-events index.  
  5. Build specs/scripts/Build-QwenOpenApiSpec.ps1 to automate the extraction and assembly pipeline.  
  6. Implement QwenSdkDotNet.ContractTests: execute authenticated HTTP probes against every route on 100.118.225.119:4170, diffing returned payloads against JSON schemas.  
  7. Enforce Spectral linting gates in CI.  
* **Deliverables:** specs/qwen-serve.openapi.json committed, lint-clean, and contract-proven.

### **Phase 3: Kiota REST Client & Authentication Engine (Epic E2)**

* **Objective:** Generate and verify the strongly typed REST client library.  
* **Tasks:**  
  1. Pin Kiota in .config/dotnet-tools.json (\>= v1.30.0).  
  2. Execute Kiota generation into QwenDaemon.Client/Generated, emitting kiota-lock.json.  
  3. Implement StaticBearerAuthenticationProvider : IAuthenticationProvider supporting static token injection into the Authorization header.  
  4. Implement ServiceCollectionExtensions.AddQwenClient() registering QwenDaemonClient with IHttpClientFactory, base URL, and telemetry.  
  5. Author specs/scripts/Update-QwenKiotaClient.ps1 to automate regeneration and locking.  
  6. Write integration tests validating the REST round-trip against the daemon (create ![][image1] prompt ![][image1] status ![][image1] delete).  
* **Deliverables:** Working, tested REST client in QwenDaemon.Client.

### **Phase 4: Resilient Server-Sent Events (SSE) Layer (Epic E3)**

* **Objective:** Deliver QwenEventStream supporting typed parsing, resume via Last-Event-ID, and proactive backpressure handling.  
* **Tasks:**  
  1. Construct typed event records in QwenDaemon.Client/Events representing all KnownDaemonEvent variants (AgentMessageChunkEvent, AgentThoughtChunkEvent, SlowClientWarningEvent, HistoryTruncatedEvent).  
  2. Implement custom JSON polymorphic type discriminator converters for event envelopes.  
  3. Build QwenEventStream wrapping HttpClient.GetStreamAsync() with System.Net.ServerSentEvents.SseParser\<QwenDaemonEvent\>.  
  4. Implement Last-Event-ID tracking, injecting the header into subsequent reconnection requests.  
  5. Build reconnection loop with jittered exponential backoff for unexpected disconnections.  
  6. Implement proactive reconnection on SlowClientWarningEvent (eviction avoidance).  
  7. Author unit test harness with mock HTTP servers to test disconnect recovery, backpressure triggers, and truncation handling.  
* **Deliverables:** Resilient, tested SSE streaming engine.

### **Phase 5: Aspire Consuming App & Portal UI (Epic E4)**

* **Objective:** Build the developer experience platform containing the Blazor dashboard and embedded API explorer.  
* **Tasks:**  
  1. Configure QwenSdkDotNet.AppHost to declare qwen-serve as an external HTTP resource, reading endpoint and token from configuration.  
  2. Add health checks in ServiceDefaults executing GET /health with bearer auth.  
  3. Implement backend proxy endpoints in QwenSdkDotNet.ApiService wrapping client operations.  
  4. Build Blazor components in QwenSdkDotNet.Web for interactive prompt dispatch and real-time streaming token display.  
  5. Embed Scalar / Swagger UI in Web serving specs/qwen-serve.openapi.json, pointed directly at the daemon endpoint with pre-authenticated bearer headers.  
* **Deliverables:** Complete running Aspire application showcasing client capabilities.

### **Phase 6: Packaging, Runbooks & Final Quality Verification (Epic E5)**

* **Objective:** Finalize NuGet packaging for QwenDaemon.Client and document upgrade runbooks.  
* **Tasks:**  
  1. Configure QwenDaemon.Client.csproj with package metadata, SemVer, license, README, and Source Link.  
  2. Test package compilation via dotnet pack \--configuration Release.  
  3. Document the daemon upgrade runbook in README.md and verify end-to-end execution of Build-QwenOpenApiSpec.ps1 followed by Update-QwenKiotaClient.ps1.  
  4. Run full validation.ps1 verification: format, scan, test, ![][image2] coverage report generation.  
* **Deliverables:** Production-ready NuGet artifact and completed documentation.

## **5\. Critical System Code Implementations**

### **A. Resilient SSE Stream Engine (QwenEventStream.cs)**

namespace QwenDaemon.Client.Streaming;

using System;  
using System.IO;  
using System.Net.Http;  
using System.Net.Http.Headers;  
using System.Net.ServerSentEvents;  
using System.Runtime.CompilerServices;  
using System.Text.Json;  
using System.Threading;  
using System.Threading.Tasks;  
using Microsoft.Extensions.Logging;  
using QwenDaemon.Client.Events;

public class QwenEventStream : IQwenEventStream  
{  
    private readonly HttpClient \_httpClient;  
    private readonly string \_streamUrl;  
    private readonly string \_bearerToken;  
    private readonly QwenStreamOptions \_options;  
    private readonly ILogger\<QwenEventStream\> \_logger;  
    private string? \_lastEventId;

    public QwenEventStream(  
        HttpClient httpClient,  
        string baseUrl,  
        string sessionId,  
        string bearerToken,  
        QwenStreamOptions options,  
        ILogger\<QwenEventStream\> logger)  
    {  
        \_httpClient \= httpClient;  
        \_streamUrl \= $"{baseUrl.TrimEnd('/')}/session/{sessionId}/events?maxQueued={options.MaxQueued}";  
        \_bearerToken \= bearerToken;  
        \_options \= options;  
        \_logger \= logger;  
    }

    public async IAsyncEnumerable\<QwenDaemonEvent\> ReadEventsAsync(\[EnumeratorCancellation\] CancellationToken ct \= default)  
    {  
        int retryAttempt \= 0;

        while (\!ct.IsCancellationRequested)  
        {  
            HttpRequestMessage request \= new(HttpMethod.Get, \_streamUrl);  
            request.Headers.Authorization \= new AuthenticationHeaderValue("Bearer", \_bearerToken);  
            request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("text/event-stream"));

            if (\!string.IsNullOrEmpty(\_lastEventId))  
            {  
                request.Headers.TryAddWithoutValidation("Last-Event-ID", \_lastEventId);  
                \_logger.LogInformation("Reconnecting SSE stream with Last-Event-ID: {LastId}", \_lastEventId);  
            }

            HttpResponseMessage? response \= null;  
            Stream? stream \= null;

            try  
            {  
                response \= await \_httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct).ConfigureAwait(false);  
                response.EnsureSuccessStatusCode();

                stream \= await response.Content.ReadAsStreamAsync(ct).ConfigureAwait(false);  
                retryAttempt \= 0; // Connected successfully, reset retry counter

                var sseParser \= SseParser.Create(stream, (eventType, dataBytes) \=\>  
                {  
                    if (dataBytes.IsEmpty) return null;  
                    try  
                    {  
                        return JsonSerializer.Deserialize\<QwenDaemonEvent\>(dataBytes.Span, QwenJsonOptions.Default);  
                    }  
                    catch (Exception ex)  
                    {  
                        \_logger.LogWarning(ex, "Failed to deserialize event of type '{EventType}'. Skipping.", eventType);  
                        return null;  
                    }  
                });

                await foreach (SseItem\<QwenDaemonEvent?\> item in sseParser.EnumerateAsync(ct).ConfigureAwait(false))  
                {  
                    if (\!string.IsNullOrEmpty(item.EventId))  
                    {  
                        \_lastEventId \= item.EventId;  
                    }

                    if (item.Data is null) continue;

                    // Handle daemon backpressure warnings proactively  
                    if (item.Data is SlowClientWarningEvent warning)  
                    {  
                        \_logger.LogWarning("Received slow\_client\_warning ({FillPercent}% filled). Triggering proactive reconnection.", warning.QueueFillPercent);  
                        break; // Break inner loop to trigger proactive reconnect  
                    }

                    yield return item.Data;  
                }  
            }  
            catch (OperationCanceledException) when (ct.IsCancellationRequested)  
            {  
                yield break;  
            }  
            catch (Exception ex)  
            {  
                \_logger.LogWarning(ex, "SSE stream connection severed. Preparing to reconnect.");  
            }  
            finally  
            {  
                stream?.Dispose();  
                response?.Dispose();  
            }

            retryAttempt++;  
            TimeSpan delay \= CalculateBackoff(retryAttempt, \_options);  
            \_logger.LogInformation("Backing off SSE reconnect for {DelayMs}ms (Attempt {Attempt})", delay.TotalMilliseconds, retryAttempt);  
            await Task.Delay(delay, ct).ConfigureAwait(false);  
        }  
    }

    private static TimeSpan CalculateBackoff(int attempt, QwenStreamOptions options)  
    {  
        double maxBackoff \= options.MaxRetryDelay.TotalMilliseconds;  
        double calculated \= options.InitialRetryDelay.TotalMilliseconds \* Math.Pow(2, attempt \- 1);  
        double jitter \= Random.Shared.NextDouble() \* (options.InitialRetryDelay.TotalMilliseconds \* 0.5);  
        return TimeSpan.FromMilliseconds(Math.Min(calculated \+ jitter, maxBackoff));  
    }  
}

### **B. Static Bearer Authentication Provider (StaticBearerAuthenticationProvider.cs)**

namespace QwenDaemon.Client.Auth;

using System;  
using System.Collections.Generic;  
using System.Threading;  
using System.Threading.Tasks;  
using Microsoft.Kiota.Abstractions;  
using Microsoft.Kiota.Abstractions.Authentication;

public sealed class StaticBearerAuthenticationProvider : IAuthenticationProvider  
{  
    private const string AuthorizationHeader \= "Authorization";  
    private readonly string \_bearerToken;

    public StaticBearerAuthenticationProvider(string bearerToken)  
    {  
        if (string.IsNullOrWhiteSpace(bearerToken))  
            throw new ArgumentException("Bearer token cannot be null or empty.", nameof(bearerToken));

        \_bearerToken \= bearerToken.Trim();  
    }

    public Task AuthenticateRequestAsync(  
        RequestInformation request,   
        Dictionary\<string, object\>? additionalAuthenticationContext \= null,   
        CancellationToken cancellationToken \= default)  
    {  
        ArgumentNullException.ThrowIfNull(request);

        if (request.Headers.ContainsKey(AuthorizationHeader))  
        {  
            request.Headers.Remove(AuthorizationHeader);  
        }

        request.Headers.Add(AuthorizationHeader, $"Bearer {\_bearerToken}");  
        return Task.CompletedTask;  
    }  
}

### **C. Aspire AppHost Configuration (Program.cs)**

var builder \= DistributedApplication.CreateBuilder(args);

// Read daemon target and token from secure configuration / user secrets  
var daemonEndpoint \= builder.Configuration\["QwenDaemon:Endpoint"\] ?? "http://100.118.225.119:4170";  
var daemonToken \= builder.AddParameter("qwen-token", secret: true);

// Model the background systemd service as an external resource with health checks  
var qwenDaemon \= builder.AddResource(new ExternalServiceResource("qwen-serve", new Uri(daemonEndpoint)))  
    .WithHttpHealthCheck("/health");

var apiService \= builder.AddProject\<Projects.QwenSdkDotNet\_ApiService\>("apiservice")  
    .WithReference(qwenDaemon)  
    .WithEnvironment("QwenDaemon\_\_Endpoint", daemonEndpoint)  
    .WithEnvironment("QwenDaemon\_\_Token", daemonToken);

builder.AddProject\<Projects.QwenSdkDotNet\_Web\>("webfrontend")  
    .WithExternalHttpEndpoints()  
    .WithReference(apiService);

builder.Build().Run();

## **6\. Risks and Mitigations**

| Risk | Impact | Likelihood | Mitigation Strategy |
| :---- | :---- | :---- | :---- |
| **Upstream Protocol Drift** (No official OpenAPI spec; daemon upgrades shift schemas) | High | High | Automated schema extraction pipeline (Build-QwenOpenApiSpec.ps1). Tagged live contract tests run on every daemon bump to identify breaking diffs immediately. |
| **SSE Ring-Buffer Eviction** (Slow client causes dropped tokens under heavy execution) | High | Medium | Implement proactive reconnection upon receiving slow\_client\_warning (at 75% capacity). Surface HistoryTruncatedEvent to trigger full REST state refreshes. |
| **Kiota OpenAPI 3.2 Compatibility Quirks** | Medium | Low | Tooling manifest pins Kiota \>= v1.30.0 (which officially supports 3.2 parsing). Fallback strategy: automated fallback flag generating 3.1 compatible docs with x- annotations. |
| **Daemon Authentication Leakage** | Critical | Low | Gitleaks secret scanning enforced in CI. Aspire configuration passes tokens through secure parameters; frontend interacts via ApiService proxy without accessing tokens. |
| **Tailnet Network Connectivity Dropouts** | Medium | Medium | Resilient jittered exponential backoff in QwenEventStream using Last-Event-ID ensures seamless reconnection without dropping stream context. |

## **7\. Quality & Validation Plan**

### **Local Validation (./validation.ps1)**

The local validation script enforces identical checks to CI:

\#\!/usr/bin/env pwsh  
$ErrorActionPreference \= "Stop"  
Write-Host "=== \[1/5\] Code Formatting Check \===" \-ForegroundColor Cyan  
dotnet format \--verify-no-changes

Write-Host "=== \[2/5\] Security & Secret Scan \===" \-ForegroundColor Cyan  
gitleaks detect \--no-git \--source .

Write-Host "=== \[3/5\] OpenAPI Specification Linting \===" \-ForegroundColor Cyan  
npx @stoplight/spectral-cli lint specs/qwen-serve.openapi.json \--ruleset specs/spectral.yml

Write-Host "=== \[4/5\] Build (TreatWarningsAsErrors) \===" \-ForegroundColor Cyan  
dotnet build \-c Release

Write-Host "=== \[5/5\] Unit Tests & Coverage Gate (\>85%) \===" \-ForegroundColor Cyan  
dotnet test \-c Release \--collect:"XPlat Code Coverage" \--results-directory ./TestResults  
reportgenerator \-reports:./TestResults/\*\*/coverage.cobertura.xml \-targetdir:./TestResults/CoverageReport \-reporttypes:"Html;TextSummary"

$summary \= Get-Content ./TestResults/CoverageReport/Summary.txt \-Raw  
if ($summary \-match 'Line coverage: (\\d+\\.\\d+)%') {  
    $cov \= \[double\]$matches\[1\]  
    if ($cov \-lt 85.0) {  
        Write-Error "Coverage failed: $cov% is below the required 85.0% threshold."  
    }  
    Write-Host "Coverage passed: $cov%" \-ForegroundColor Green  
}

### **Continuous Integration Pipeline (.github/workflows/ci.yml)**

* Executes on all pull requests and pushes to main.  
* Jobs:  
  * **scan**: Executes gitleaks@v8.21.2, markdownlint-cli2@0.22.1, and dotnet format.  
  * **spec-lint**: Lints OpenAPI 3.2 specs with Spectral and runs kiota show.  
  * **build-test-coverage**: Builds with .NET SDK 10.0.400, executes xUnit tests with Coverlet, verifies line coverage ![][image2], and uploads HTML coverage reports.  
  * **contract-suite** (Triggered on schedule / workflow dispatch): Executes live probes against 100.118.225.119:4170 using repository secrets.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAZCAYAAADe1WXtAAAAe0lEQVR4XmNgGAWjYOCBvLz8XnQxigHQ0MnoYlQBQIO70cUoBnJyco+AOA5dHA4UFBQcyMQFQBcfBdIW6GaCvLKbAvwLiJejm0kuYAR6f4aMjIw0ugTZAOi6OyoqKqLo4hQBUJiii1EEgN7egS5GMQAamocuNgpGAQ0BAATwKIpIvM31AAAAAElFTkSuQmCC>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADsAAAAZCAYAAACPQVaOAAADWklEQVR4Xu2X20tUURTGNY1uUBbF5Dg3Z4ygK2Hko2C9SBRJ/QNlkeFLUREF0UuB0VOEEBHdHiK6PHQjKHookO5kFy3oSqVYSWUQkj3Ybzl7x3IxYzMTaA/zweKcb33fvqx9zj6zp6AgjzxGFNFo9ADRFYvFSqzmEQ6Hg6FQaIbN/zeggDpdAPfVxEZlKcTTVlFRMUYI9w+JX0RtPB6f5NpUwTuIXtVueMHg+4j7RHskEjlqdQFavwT6Da7PHD+r9KWS8xzfKvhz1+9AW+KHu27xvmGDPAUGfsptoc9VVlaOJteDNk1ZpRgpsJc4SazVmtOPSCGe036i5s5Tw+s7V+fSAvNuVuyYzecK+quzE3J5Wf0dOscr2KC5Bfp23RfznA3v8zwQCEyAv/E8Y9DRNhp2EisL1FPJFq4fKaxU5yXH5FfrHHyD5hbuLXngOf4L8nA8lz75MC30PCvwOoyTgun0MXSU1TMBxS5zxfbQzwrJcS2Bv+K2WHvJr3f7UPbdPe4na11AbpY84WAwOB7PC3mVJS+c/F7rzwkMsi6a/BjUy56z+lBwxUnBPnqsR0D+E97piou3TXtSoby8fJF4PZfFgH8harUvWxTRwRPidbYF0+arKrafCUath1dwuebeq3OpgKeVAvc7OgreTWwmunhIiweZcwEd3cpkIvLa4evktkg4943EZ1fIIWMfBPR2N0babwaLNo8xlnhO0TfVQhajvfNa1mBvTKWDXXR6nE5nWt2CyV6R4nSOdgFX7E/6Gas1DfQW8clpyGoORczljuJy6OiT/esT8MtKzxxlZWUhGnczwEGrpYMr6nCK/MChgWKrhXO9Cr9mPHJC6vcnJgu0rcQHzxOJRFj8xtOs+ZCQH2gmcppGLVyrrP43uILO2zy5JtHof4rzfSN2ao/odvIKhSz6KZvE/1YvDvyi1tMC4wI34KAVzwa0vR1VP/wq3yFbQfETWnc5GfulzQto2yBbyubxX+KcHFFcTm+pIfsQw3WimZWLWz0XsOcSbuIfie9yn+ofCQXcjSZf7zaij3ZzrEeAdoY4Z/MeaK1EKfGIaLT6HzDgJgx7bP5fEUke7eToWK+/ngbygakh1rDo863ogf4+1VP1iCVPVrJ9mqyWRx555JFHHiOE31v/9HrfXDH/AAAAAElFTkSuQmCC>