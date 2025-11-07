

# **Architectural Blueprint for a First-Class opencode.ai Agent Integration in the Zed Editor via the Agent Client Protocol**

## **Section 1: Analysis of the Existing Zed External Agent Landscape**

To architect a successful integration of the opencode.ai command-line interface (CLI) with the Zed code editor, it is imperative to first conduct a rigorous analysis of the existing external agent ecosystem. This involves a deep examination of the underlying communication standard, the Agent Client Protocol (ACP), and a critical assessment of current agent implementations. By dissecting the successes and, more importantly, the failures of existing integrations, a clear set of requirements and anti-patterns emerges, providing the foundational knowledge necessary to avoid common pitfalls and deliver a truly first-class user experience.

### **1.1 The Agent Client Protocol (ACP) as the Foundational Standard**

The Agent Client Protocol (ACP) is the cornerstone of Zed's extensible agent architecture. Conceived as an open standard, ACP is designed to function as the "Language Server Protocol (LSP) for AI agents," establishing a standardized communication layer that decouples AI coding agents from the editors they inhabit.1 This decoupling is a strategic imperative, designed to foster an ecosystem where any ACP-compliant agent can operate within any ACP-compliant client, liberating developers from vendor lock-in and allowing agent and editor developers to innovate independently.2

Architecturally, ACP is a JSON-RPC 2.0 protocol that operates over standard input/output (stdio).2 This design choice is deliberate; it allows an editor like Zed to spawn an agent as a simple sub-process and establish a structured, high-performance communication channel. This is a significant improvement over attempting to parse unstructured ANSI escape codes from a terminal emulator, which was the primitive state-of-the-art that motivated ACP's creation.1 The protocol specification is comprehensive, defining a full lifecycle for agent interaction that includes an initialization handshake, session setup (new or loaded), and a "prompt turn" model that accommodates complex, multi-step tasks involving tool calls, file system operations, and terminal command execution.2 The protocol's schema is formally defined and available in both Rust and TypeScript, providing robust libraries that facilitate implementation for both clients and agents.4 A thorough understanding of this specification is the absolute prerequisite for any successful integration, as it dictates the contractual obligations the opencode.ai agent must fulfill to be a well-behaved citizen in the Zed environment.

### **1.2 Case Study: The Gemini CLI Reference Implementation**

The Gemini CLI, developed in partnership with Google, serves as the initial reference implementation for ACP and the baseline for what a native integration should achieve.1 When a user initiates a Gemini CLI session in Zed, the editor manages the installation and authentication of the tool and then runs the actual Gemini CLI executable as a background process.6 The communication between Zed and this sub-process occurs exclusively over ACP.

This native approach, where the agent itself speaks the protocol, is the ideal architectural pattern. It ensures that the full suite of the agent's capabilities is, in principle, available to the editor without any intermediate translation layers that could introduce limitations or performance bottlenecks. However, even this reference implementation is not without its shortcomings. Documentation and user reports indicate that certain Zed UI features, such as editing past messages, resuming threads from history, and creating checkpoints for code changes, are not yet supported by the Gemini CLI integration.7 This reveals a crucial nuance: basic ACP compliance is necessary but not sufficient for a perfect user experience. Full integration requires the agent to not only speak the protocol but also to implement the optional parts of the specification that map to the editor's advanced UI affordances.

### **1.3 Case Study: The Claude Code SDK Adapter \- A Cautionary Tale of Leaky Abstractions**

The integration of Anthropic's Claude Code provides the most critical lessons for this project, serving as a powerful case study in architectural failure. Responding to overwhelming user demand for the popular agent, the Zed team opted for a pragmatic but ultimately flawed implementation strategy.8 Instead of a native integration, they developed an open-source adapter—a separate process that wraps the official Claude Code Software Development Kit (SDK) and translates its interactions into the ACP format.8

This decision to use an adapter built upon an SDK, rather than the core CLI tool, has resulted in a severely compromised user experience, plagued by workflow-breaking issues that stem directly from the limitations of the SDK itself.7 The SDK does not expose the full feature set of the command-line tool, creating a "leaky abstraction" where the integration promises the power of Claude Code but fails to deliver it. The specific failures reported by users are illuminating:

* **Catastrophic Context Window Failure:** The most severe issue is the adapter's inability to support the /compact slash command, a feature essential for managing long conversations. This omission, a direct consequence of the SDK's limitations, leads to an inevitable "Prompt too long" error during any complex task. Without a mechanism to summarize and compact the conversation history, the agent becomes unusable, forcing users to abandon their work and start a new session.10  
* **Absence of Core Functionality:** The integration is missing other crucial features that are native to the Claude Code CLI. Users cannot switch to "Plan mode" to review the agent's proposed changes before execution, nor can they switch between different models.10 These are not minor omissions; they are fundamental parts of the established user workflow.  
* **Degraded Overall Experience:** The sum of these failures is an integration that users describe as being demonstrably worse than simply running the Claude Code CLI within Zed's integrated terminal.10 This defeats the very purpose of a deep, ACP-based integration. The official guidance from the Zed team—encouraging users to lobby Anthropic to adopt ACP natively—is a tacit admission that the adapter-based approach is a suboptimal, stopgap solution that cannot be fixed without fundamental changes from the agent provider.8

The stark contrast between the Gemini and Claude Code integrations reveals that the central strategic choice in building an external agent is not *if* to use ACP, but *how*. An adapter built on a limited, intermediate abstraction layer is a short-term tactic that incurs significant, long-term "feature debt" and user frustration. A native implementation, where the agent's core logic communicates directly via the protocol, is a strategic investment in quality, performance, and user experience. The failure of the Claude Code adapter provides an unambiguous anti-pattern that must be avoided at all costs.

## **Section 2: Deconstructing the opencode.ai CLI for Native Integration**

A successful integration requires a deep architectural understanding of the opencode.ai CLI itself. By deconstructing its core components, operational modes, and unique features, it is possible to map its functionality faithfully onto the ACP specification. This analysis reveals that opencode.ai is exceptionally well-suited for a native integration, possessing an architecture and feature set that align closely with the capabilities and philosophy of ACP.

### **2.1 Architectural Overview: Client/Server Model and Programmatic Interfaces**

A key architectural characteristic of opencode.ai is its explicit client/server design.12 While its most prominent feature is a rich Terminal User Interface (TUI), the core agentic logic is decoupled from this presentation layer. This separation is a significant advantage, as it makes the agent's logic inherently reusable by other clients, such as Zed. The CLI exposes two primary programmatic interfaces for non-TUI interaction:

1. **Non-interactive run command:** The opencode run \[prompt\] command facilitates one-shot, stateless execution. This is useful for simple scripting and automation but is insufficient for building a stateful, conversational agent.13  
2. **Headless serve command:** The opencode serve command starts a headless HTTP server that provides API access to the full functionality of the agent, including session management, without launching the TUI.13

The existence of the serve command is particularly noteworthy, as it provides a ready-made, stateful interface that could, in theory, be used for an integration. However, relying on this HTTP API introduces an unnecessary translation layer (ACP JSON-RPC \-\> HTTP \-\> opencode Core), adding latency and complexity. More critically, it would couple the integration to the public API's feature set, which may not expose every internal capability of the agent. This approach risks recreating the very "leaky abstraction" problem observed with the Claude Code SDK adapter. The true strategic advantage lies not in these public interfaces but in the open-source nature of the tool itself.12 Because the entire codebase is available, a direct, native integration that bypasses all intermediate layers is possible, eliminating the risk of feature gaps entirely.

### **2.2 The opencode.ai Agent Model: Primary, Subagent, and Custom Configurations**

The opencode.ai CLI features a sophisticated and highly configurable agent system that must be accurately represented within the Zed UI to provide a familiar and powerful experience for existing users.14

* **Primary Agents:** These are the main conversational agents, which users of the TUI cycle through using the Tab key. The two built-in primary agents, Build and Plan, represent distinct and crucial modes of operation. The Build agent has full access to tools for file modification and command execution. In contrast, the Plan agent is a read-only mode designed for analysis, code review, and strategic planning, where permissions for file edits and shell access are typically set to ask by default.14 The absence of a similar planning mode was a major criticism of the Claude Code integration, making the faithful implementation of this feature a top priority.  
* **Subagents:** opencode.ai supports specialized subagents, such as the built-in @general agent, which can be invoked either automatically by a primary agent for a specific task or manually by the user via an @ mention. These subagents handle focused tasks like complex research or multi-step code searches.14  
* **Customization:** The entire agent system is deeply customizable through project-specific opencode.json files or global Markdown configurations. Users can define new agents, set custom system prompts, select specific models, control tool permissions (allow, ask, or deny), and adjust creative parameters like temperature.14

This rich, multi-agent, multi-mode system is a core part of the opencode.ai value proposition. A successful integration must therefore expose these concepts to the user within Zed. The Build and Plan modes map cleanly to ACP's concept of session modes, while subagents present a unique implementation challenge that will require a thoughtful approach to their representation in the UI, as ACP lacks a native construct for nested agent sessions.

### **2.3 Core Capabilities and Context Management**

Beyond its agent model, opencode.ai possesses several core capabilities that are critical to its effectiveness and align well with the ACP specification.

* **Tools:** The agent is equipped with a comprehensive suite of tools that mirror the capabilities defined in ACP. It has tools for filesystem interaction (read, write, edit, patch), directory traversal and searching (list, glob, grep), and shell command execution (bash).14 These have direct counterparts in the fs/\* and terminal/\* methods of the ACP specification, making for a straightforward mapping.2  
* **Persistent Context (AGENTS.md):** opencode.ai utilizes a system of AGENTS.md files to provide persistent, project-specific instructions and context to the LLM, a concept similar to CLAUDE.md.15 These rule files can be defined globally or locally within a project and are automatically loaded at the start of a session. The /init command can be used to bootstrap this file by analyzing the project structure.15 This mechanism for providing durable context must be respected and implemented as part of the ACP session initialization process.  
* **Automatic Context Compaction:** Crucially, the opencode.ai CLI includes a feature to automatically summarize a conversation when it approaches the model's context window limit.17 This feature directly solves the most critical failure point of the Claude Code adapter.10 Implementing this capability is not merely a feature enhancement; it is a fundamental requirement for building a usable and reliable agent for complex, long-running tasks.

## **Section 3: Strategic Integration Plans and Architectural Options**

Based on the analysis of the ACP landscape and the opencode.ai CLI, three distinct architectural plans for integration can be formulated. These options range from a simplistic but deeply flawed wrapper to a more intensive but unequivocally superior native implementation. A careful evaluation of each plan against the primary goals of feature parity, performance, and robustness leads to a clear and definitive recommendation.

### **3.1 Option A: The "CLI Wrapper" Approach (Anti-Pattern)**

This approach represents the most naive implementation strategy. It involves creating a simple adapter process that receives ACP requests from Zed and, for each user prompt, spawns a new, non-interactive opencode run process with the relevant flags (e.g., \--prompt "...", \--model "...").13 The standard output of this process would be captured, parsed, and streamed back to Zed as session/update notifications.

* **Assessment:** While this method might allow for a rapid prototype of a text-only "hello world" exchange, it is a fundamentally unworkable architecture for a real-world agent. The opencode run command is stateless, meaning the adapter would have to manually manage conversation history by concatenating it into each new prompt, an inefficient and error-prone process. This architecture is incapable of supporting any interactive or stateful features, such as tool calls that require client-side execution (e.g., file system access), permission prompts (ask mode), or the distinct operational modes of Plan vs. Build. It would be impossible to implement context compaction or subagent workflows.  
* **Conclusion:** This option is presented solely as an anti-pattern to be explicitly rejected. It would replicate and likely exacerbate every critical issue identified in the flawed Claude Code integration, resulting in a frustrating and useless tool.

### **3.2 Option B: The "Headless Server" Approach**

A more plausible strategy involves leveraging the opencode.ai CLI's headless server mode. This architecture would consist of two processes. First, the opencode serve command would be started to run the agent's backend as a headless HTTP server.13 Second, a dedicated ACP adapter process would be configured in Zed's agent\_servers settings.6 This adapter would function as an ACP server on its stdio interface while acting as an HTTP client to the opencode server. It would translate ACP methods like session/new and session/prompt into corresponding RESTful API calls.

* **Assessment:** This approach is a significant improvement over the CLI wrapper, as it correctly utilizes a stateful, programmatic interface provided by the opencode.ai team. It decouples the ACP implementation from the core opencode application, which could simplify the initial development of the adapter. However, this strategy carries a significant and familiar risk: it is entirely dependent on the completeness and stability of the opencode serve HTTP API. The available documentation for this API is sparse 13, and there is no guarantee that it exposes all the granular functionality required for a first-class integration, such as hooks for triggering context compaction or fine-grained control over subagent invocation.  
* **Conclusion:** This is a viable but high-risk approach. It risks recreating the leaky abstraction problem that plagues the Claude Code integration, where the capabilities of the agent are constrained by an incomplete intermediate layer. It is a technically superior option to the CLI wrapper but remains inferior to a truly native solution.

### **3.3 Option C: The "Native Protocol" Approach (Recommended)**

The optimal strategy involves modifying the open-source opencode.ai codebase to implement native support for the Agent Client Protocol.12 This would be accomplished by introducing a new command, opencode acp. When invoked, this command would initialize the agent's core logic but, instead of launching the TUI or an HTTP server, it would listen for JSON-RPC messages on stdin and send responses and notifications to stdout. This single, self-contained process would be configured directly in Zed's agent\_servers setting.

* **Assessment:** This architecture offers overwhelming advantages that directly address the goals of the project.  
  * **Maximum Performance:** By eliminating all intermediate layers, protocol translations, and network overhead, communication occurs directly and efficiently via stdio pipes.  
  * **Guaranteed Feature Parity:** The ACP implementation has direct access to the same core application logic, internal state, and configuration system as the TUI. This guarantees that every feature—from Plan mode and subagents to context compaction and custom commands—can be implemented without compromise.  
  * **Robustness and Simplicity:** A single-process architecture simplifies deployment for the end-user, as well as debugging and long-term maintenance for the developers.  
  * **Ecosystem Leadership:** This approach would result in a high-quality, open-source ACP implementation that can serve as a new gold-standard reference for the community. It would benefit users of both opencode.ai and Zed, and it would set a high bar for other agent developers, demonstrating the power of native protocol support.  
* **Conclusion:** The native protocol approach is unequivocally the superior strategy. Although it requires a greater initial investment in understanding and modifying a third-party codebase, it is the only path that mitigates the critical risks of feature gaps and performance degradation. It is a strategic investment in quality that will produce a genuinely first-class user experience.

## **Section 4: Feature Mapping and Implementation Roadmap for the Native Protocol Approach**

Executing the recommended native protocol approach requires a detailed technical plan. This begins with a comprehensive mapping of opencode.ai's unique features to their corresponding implementations within the ACP framework. This mapping serves as the blueprint for development and de-risks the project by ensuring no critical functionality is overlooked. Following this, a phased roadmap provides a structured, iterative path for implementation, testing, and community contribution.

### **4.1 Table: opencode.ai to ACP Concept Mapping**

The following table provides a detailed specification for translating opencode.ai's core concepts into the language of the Agent Client Protocol. This ensures that the integration will be both feature-complete and architecturally sound.

| opencode.ai Feature/Concept | ACP Implementation Strategy | Relevant Sources |
| :---- | :---- | :---- |
| **Session Initialization** | The client calls the initialize method. The agent responds with its capabilities (e.g., fs, terminal). The client then calls session/new, passing the project's current working directory (cwd). | 2 |
| **AGENTS.md Context** | Upon receiving a session/new request, the agent's core logic will automatically discover, parse, and load the project's AGENTS.md file, injecting its contents as the initial system prompt for the LLM. This process is transparent to the client. | 16 |
| **User Prompt** | The client sends a session/prompt request containing the user's message within a ContentBlock::Text. | 2 |
| **Agent Response Streaming** | The agent sends a continuous stream of session/update notifications with the sessionUpdate field set to "agent\_message\_chunk". | 2 |
| **"Build" vs. "Plan" Modes** | The primary agents (build, plan) are mapped to ACP Session Modes. The agent advertises these available modes in its session/new response. The Zed client can then switch between them using the session/set\_mode method. When in Plan mode, the agent will not use file-writing or terminal tools and will instead stream its strategy via session/update with sessionUpdate set to "plan". | 2 |
| **File System Tools (read, write, edit)** | The agent's internal tool-calling logic translates its file operations into standard ACP methods, making fs/read\_text\_file and fs/write\_text\_file requests to the client. | 2 |
| **Shell Command Tool (bash)** | The agent's bash tool is implemented by making a sequence of requests to the client: terminal/create, terminal/wait\_for\_exit, and finally terminal/release. The captured output is then fed back to the LLM for analysis. | 2 |
| **Tool Permissions (allow, ask, deny)** | If an agent's configuration specifies a tool permission as ask, the agent will first call the session/request\_permission method before executing a sensitive operation like fs/write\_text\_file or terminal/create. This triggers Zed's native confirmation dialog. | 2 |
| **Subagent Invocation (@general)** | As ACP does not support nested sessions, subagent invocation will be represented at the UI level. When a subagent is triggered, the agent will send a session/update notification with sessionUpdate: "agent\_thought\_chunk" to inform the user (e.g., "Invoking @general to research..."). The subagent's subsequent work and results will be streamed back as regular agent\_message\_chunk and tool\_call updates within the same parent session. | 2 |
| **Context Window Auto-Compaction** | The agent's core logic will actively monitor the token count of the conversation history. Upon reaching a predefined threshold (e.g., 95% of the context limit), it will internally perform a summarization, clear the existing history, prepend the summary, and then proceed with the user's prompt. It will notify the client of this event via a session/update with sessionUpdate: "agent\_thought\_chunk". | 10 |
| **Custom Commands (/test, etc.)** | Custom commands defined by the user in opencode.json or Markdown files will be advertised to the client via a session/update notification with sessionUpdate: "available\_commands\_update". This allows Zed's UI to populate its command suggestion list when the user types /. | 16 |

### **4.2 Phased Implementation Roadmap**

A phased approach will ensure steady progress and allow for iterative testing and refinement.

* **Phase 1: Foundational Handshake & Communication (1-2 Sprints)**  
  * **Objective:** Establish a basic, text-only conversational loop between Zed and the opencode agent.  
  * **Tasks:** Fork the sst/opencode repository; implement the opencode acp command structure; implement the initialize and session/new methods, including the logic for loading AGENTS.md context; and implement a basic session/prompt loop that streams responses via agent\_message\_chunk notifications.  
  * **Deliverable:** A user can successfully start an opencode agent thread in Zed and have a simple text-based conversation.  
* **Phase 2: Core Agentic Tooling (2-3 Sprints)**  
  * **Objective:** Enable the agent to fully interact with the user's workspace, including reading/writing files and executing commands.  
  * **Tasks:** Map opencode's internal file system and shell tools to the corresponding ACP fs/\* and terminal/\* methods; implement the session/request\_permission flow for tools configured with permission: "ask"; and ensure file edits are correctly reported as diffs to integrate with Zed's review UI.  
  * **Deliverable:** The build agent can reliably perform file operations and run shell commands, with all changes being reviewable and controllable from within the Zed interface.  
* **Phase 3: Advanced Feature Parity and UX (2-3 Sprints)**  
  * **Objective:** Implement the sophisticated features that differentiate opencode.ai and solve the critical problems identified in existing third-party integrations.  
  * **Tasks:** Implement ACP Session Modes to support switching between Build and Plan agents; implement the plan update notification for Plan mode; implement the critical context window auto-compaction logic; and develop the UI representation for subagent invocation.  
  * **Deliverable:** A feature-complete agent that supports strategic planning, robustly manages long conversations without context overflow, and provides a rich, intuitive user experience that mirrors the power of the native TUI.  
* **Phase 4: Community Contribution and Stabilization (1 Sprint)**  
  * **Objective:** Finalize the integration, ensure its quality, and contribute it back to the open-source community for long-term sustainability.  
  * **Tasks:** Add comprehensive unit and integration tests; write clear documentation for end-users and developers; prepare and submit a high-quality Pull Request to the main sst/opencode repository; and actively engage with both the opencode and Zed communities for feedback.  
  * **Deliverable:** A merged and officially supported ACP integration within the opencode.ai CLI, available to all users.

## **Section 5: Strategic Recommendations and Conclusion**

### **5.1 Final Recommendation**

This report strongly and unequivocally recommends the adoption of **Option C: The "Native Protocol" Approach**. This strategy, which involves adding native ACP support directly to the opencode.ai open-source codebase, is the only one that aligns with the goal of creating a high-performance, feature-complete, and robust integration. It directly addresses and mitigates the fundamental risks of leaky abstractions, performance degradation, and feature gaps that have been shown to plague adapter-based solutions. While this path requires a greater initial engineering investment, the long-term returns in product quality, user satisfaction, and maintainability are immense. Pursuing this approach is a strategic investment that will yield a superior product and position this integration as a benchmark of quality for the entire ACP ecosystem.

### **5.2 Concluding Remarks**

The integration of opencode.ai into the Zed editor via a native ACP implementation is more than a technical exercise; it is an opportunity to define what a "first-class" integration looks like in the nascent ecosystem of editor-agnostic AI agents. By learning from the documented failures of previous attempts and strategically leveraging the open-source nature of both opencode.ai and the Agent Client Protocol, it is possible to deliver an experience that is seamless, powerful, and reliable.

This project will not only provide significant value to the users of Zed and opencode.ai but will also serve as a powerful, positive case study for the broader community. It will demonstrate the tangible benefits of native protocol adoption and encourage other agent developers to prioritize open standards over fragile, incomplete adapters. The ultimate result will be a more interoperable, competitive, and innovative landscape for AI-assisted software development, benefiting all developers regardless of their preferred tools.

#### **Works cited**

1. Bring Your Own Agent to Zed — Featuring Gemini CLI, accessed October 6, 2025, [https://zed.dev/blog/bring-your-own-agent-to-zed](https://zed.dev/blog/bring-your-own-agent-to-zed)  
2. Agent Client Protocol: Introduction, accessed October 6, 2025, [https://agentclientprotocol.com/](https://agentclientprotocol.com/)  
3. How the Community is Driving ACP Forward — Zed's Blog, accessed October 6, 2025, [https://zed.dev/blog/acp-progress-report](https://zed.dev/blog/acp-progress-report)  
4. zed-industries/agentic-coding-protocol \- NPM, accessed October 6, 2025, [https://www.npmjs.com/package/@zed-industries/agentic-coding-protocol](https://www.npmjs.com/package/@zed-industries/agentic-coding-protocol)  
5. zed-industries/agent-client-protocol \- GitHub, accessed October 6, 2025, [https://github.com/zed-industries/agent-client-protocol](https://github.com/zed-industries/agent-client-protocol)  
6. External Agents | Zed Code Editor Documentation | Новости Радио-Т, accessed October 6, 2025, [https://news.radio-t.com/post/external-agents-zed-code-editor-documentation](https://news.radio-t.com/post/external-agents-zed-code-editor-documentation)  
7. External Agents | Zed Code Editor Documentation, accessed October 6, 2025, [https://zed.dev/docs/ai/external-agents](https://zed.dev/docs/ai/external-agents)  
8. Claude Code: Now in Beta in Zed — Zed's Blog, accessed October 6, 2025, [https://zed.dev/blog/claude-code-via-acp](https://zed.dev/blog/claude-code-via-acp)  
9. Zed+Claude Code/GLM Code & ACP Overview: You need to KNOW ABOUT THIS\!, accessed October 6, 2025, [https://www.youtube.com/watch?v=7VY3KolDyKk](https://www.youtube.com/watch?v=7VY3KolDyKk)  
10. Claude Code: Now in Beta in Zed | Hacker News, accessed October 6, 2025, [https://news.ycombinator.com/item?id=45116688](https://news.ycombinator.com/item?id=45116688)  
11. Add support for Agent Client Protocol (ACP) · Issue \#6686 · anthropics/claude-code \- GitHub, accessed October 6, 2025, [https://github.com/anthropics/claude-code/issues/6686](https://github.com/anthropics/claude-code/issues/6686)  
12. sst/opencode: The AI coding agent built for the terminal. \- GitHub, accessed October 6, 2025, [https://github.com/sst/opencode](https://github.com/sst/opencode)  
13. CLI | opencode, accessed October 6, 2025, [https://opencode.ai/docs/cli/](https://opencode.ai/docs/cli/)  
14. Agents | opencode, accessed October 6, 2025, [https://opencode.ai/docs/agents/](https://opencode.ai/docs/agents/)  
15. Intro \- OpenCode, accessed October 6, 2025, [https://opencode.ai/docs/](https://opencode.ai/docs/)  
16. Commands | opencode, accessed October 6, 2025, [https://opencode.ai/docs/commands/](https://opencode.ai/docs/commands/)  
17. Feature Request: Auto Compact (from OpenCode) · zed-industries zed · Discussion \#34515, accessed October 6, 2025, [https://github.com/zed-industries/zed/discussions/34515](https://github.com/zed-industries/zed/discussions/34515)