# **Application Implementation Specification**

## **Application Title**

Agent Client Customization Protocol (ACCP)

## **Application Synopsis**

This document specifies the implementation of the Agent Client Customization Protocol (ACCP), a unified, open standard designed to resolve the pervasive "configuration hell" plaguing the AI agent ecosystem. The current landscape is dangerously fragmented, with each agent, IDE, and tool using disparate, incompatible configuration methods—from environment variables and JSON files to proprietary formats scattered across the filesystem. This fragmentation creates significant friction, leading to wasted engineering effort in writing boilerplate loading code, a frustratingly inconsistent user experience, a complete lack of portability for valuable agent personas, and severe, often-unseen governance and security risks.

ACCP addresses this foundational problem by fundamentally decoupling the *logical definition* of an agent's configuration from its *physical storage*. It introduces a central, agnostic source of truth for all agent customizations—including system prompts, tool definitions, model parameters, and safety settings—enabling these configurations to be managed, versioned, and shared as portable, reusable assets. This architectural shift transforms configuration from a scattered liability into a managed, strategic asset.

The protocol is designed for pragmatic, phased adoption to ensure it provides immediate value to users while paving a clear path toward long-term standardization:

1. **Immediate Value (Legacy Support):** A standalone **ACCP Synchronizer** utility allows users to immediately centralize configurations for their existing, unmodified tools. It reads a simple, declarative mapping file and populates the application-specific configuration files in the locations they expect. This brings immediate order to the current chaos without requiring any integration from tool developers, solving a real and painful problem for power users and enterprise teams from day one.  
2. **Long-Term Standardization (Native Integration):** A lightweight, developer-friendly **ACCP Client SDK** allows developers of new agents and tools to natively adopt the protocol. With a simple API call (e.g., accp.get\_document('system-prompt')), applications can fetch fully resolved and composed configurations directly, eliminating the need for custom loading logic and ensuring future interoperability.

The ultimate vision is to foster a robust, interoperable ecosystem where agent capabilities are as manageable, portable, and secure as any other software library. This will accelerate development by promoting reuse, reduce operational costs by simplifying management, and enable the robust, enterprise-grade governance required to deploy AI agents safely and responsibly at scale.

## **Documents**

* [ACCP: A Unified Standard for AI Agent Configuration \- Problem Statement & Solution](https://www.google.com/search?q=ACCP:%2520A%2520Unified%2520Standard%2520for%2520AI%2520Agent%2520Configuration%2520-%2520Problem%2520Statement%2520%26%2520Solution)  
* [The ACCP Solution: A Phased Approach to Standardization](https://www.google.com/search?q=The%2520ACCP%2520Solution:%2520A%2520Phased%2520Approach%2520to%2520Standardization)  
* [Agent Client Customization Protocol (ACCP) Architecture Specification v0.1](https://www.google.com/search?q=Agent%2520Client%2520Customization%2520Protocol%2520\(ACCP\)%2520Architecture%2520Specification%2520v0.1)  
* [Agent Client Customization Protocol (ACCP) Development Plan & Roadmap v0.1](https://www.google.com/search?q=Agent%2520Client%2520Customization%2520Protocol%2520\(ACCP\)%2520Development%2520Plan%2520%26%2520Roadmap%2520v0.1)

## **Target Platform Specification**

* **Primary Implementation:** The core reference implementation, encompassing the Customization Resolver and the Synchronizer CLI tool, will be developed in Python. This choice is driven by Python's dominance in the AI/ML ecosystem, its excellent support for creating cross-platform CLI applications, and the wealth of libraries for handling various data formats.  
* **Client Libraries:** The initial native client SDK will be developed for Python to serve the primary AI developer community. Future expansions will strategically prioritize a TypeScript/JavaScript SDK to support the rapidly growing number of web-based and Node.js agents, as well as integrations into popular web IDEs like VS Code.  
* **Operating Systems:** The CLI tools and libraries will be rigorously tested and packaged to be fully cross-platform, ensuring compatibility and consistent behavior on Windows, macOS, and Linux. A comprehensive CI/CD pipeline will be used to automate builds and tests across all target platforms for every release.

## **User Interface Framework**

Not applicable for the core libraries and CLI tool. The primary interfaces are the command-line for the Synchronizer and the developer-facing APIs of the Client SDK. The protocol is designed to be headless and easily integrated into automated workflows. However, the standardized nature of ACCP could enable a third-party ecosystem of graphical front-ends for managing configurations.

## **Architectural Pattern**

The ACCP ecosystem is architected using a combination of a **Hub-and-Spoke** model and a **Provider/Adapter** pattern to achieve maximum flexibility and extensibility.

* **Customization Resolver (The Hub):** This central component is the logical hub of the entire system. It is the sole authority on configuration resolution, ensuring that all consuming applications receive a consistent, predictable context. By centralizing the composition logic, we avoid the "N-to-N" problem where every application would need to know how to talk to every type of configuration store, a brittle and unscalable approach.  
* **Storage Backends (The Spokes via Providers):** The system's "Agnostic Store" concept is implemented using a Provider pattern. Each storage mechanism (local filesystem, Git repository, object storage) is accessed through a standardized interface (e.g., a StorageProvider class). The Resolver interacts with these providers solely through a URI, making the system incredibly extensible. Adding support for a new backend, like a HashiCorp Vault store, requires only the implementation of a new provider, with no changes needed to the core Resolver logic.  
* **ACCP Synchronizer (The Adapter):** This tool is a classic example of the Adapter pattern. It acts as a bridge between the modern, standardized ACCP world and the fragmented world of legacy applications. It adapts the output of the ACCP Resolver into the specific file formats and directory structures that existing tools expect, allowing them to benefit from ACCP without being aware of its existence.

## **Core Application Logic and Architecture**

The system comprises four main, decoupled components that work in concert:

1. **Agnostic Configuration Store:** This is a conceptual layer representing any storage backend capable of hosting configuration documents. ACCP is intentionally un-opinionated about storage; it interacts with this layer solely via URIs (e.g., file://, git://, s3://). This delegates the responsibilities of access control, versioning, and durability to the chosen storage medium, allowing users to leverage their existing, trusted infrastructure.  
2. **Customization Resolver:** This is the core logic engine, implemented as a stateless service or library. Its sole responsibility is to compute the final, correct configuration context for a given request. This process involves three distinct steps:  
   * **Discovery:** Searching a predefined, hierarchical path (e.g., Current Project Directory \-\> User Home Directory \-\> System-wide Directory) for configuration manifest files (accp.json). This deterministic search order is what enables the powerful scope-based overrides.  
   * **Resolution:** Fetching the raw content of configuration documents from the store by resolving their URIs. This step includes an in-memory cache to ensure that a given URI is only fetched once per operation, optimizing performance.  
   * **Composition:** Applying deterministic precedence rules to merge and override configurations. The fundamental rule is that more specific scopes override more general ones (Project \> User \> System). A composition\_strategy metadata field within the manifest allows for fine-grained control over how documents of the same type are combined (e.g., replace, prepend, append).  
3. **ACCP Client Library (Native SDK):** A lightweight, developer-focused package that provides the "easy button" for adopting ACCP. It embeds the Customization Resolver and exposes a high-level, intuitive API (e.g., accp.get\_document('accp:core/system-prompt')). This single function call transparently handles the entire discovery, resolution, and composition process, freeing the application developer from writing any configuration-loading or file-parsing boilerplate.  
4. **ACCP Synchronizer Utility (Legacy Adapter):** A standalone CLI tool for end-users and CI/CD systems. It reads a declarative accp.map.yaml file, which defines a set of targets. For each target, it invokes the Resolver to get the final context and then writes the resulting documents to the specific file paths that non-ACCP-compliant applications expect. Crucially, it is designed to be idempotent: if the source configuration hasn't changed, the synchronizer will make no changes to the filesystem on subsequent runs, making it safe and efficient for automated pipelines.

## **AI/ML Model Specification**

Not applicable. This is a protocol and tooling for managing AI agent configurations, not an AI model itself.

## **AI/ML Integration Strategy**

Not applicable.

## **Data Sources and Management**

The system's primary data artifacts are configuration documents, which are typically human-readable formats like Markdown, JSON, or YAML. The core data models that drive the protocol are:

* **Customization Object:** The fundamental data structure, defined as an entry within an accp.json manifest. It acts as a pointer to a specific configuration document and provides the necessary metadata for the Resolver.  
  {  
    "name": "Project-Specific Python Prompt",  
    "type": "accp:core/system-prompt",  
    "scope": "Project",  
    "uri": "file://prompts/python\_expert.md",  
    "version": "1.1.0",  
    "metadata": {  
      "author": "jane@example.com",  
      "composition\_strategy": "replace"  
    }  
  }

  * type: A crucial, namespaced identifier. Applications don't ask for files by name; they ask for a configuration of a specific type, allowing the underlying physical location to change without breaking the application.  
* **Mapping Manifest File (accp.map.yaml):** A simple, declarative file used exclusively by the Synchronizer to bridge ACCP-managed configurations to legacy tools.  
  version: 1  
  targets:  
    \- name: "Zed Editor Instructions"  
      type: "accp:core/system-prompt"  
      destination:  
        path: "\~/.config/zed/instructions.md"  
        format: "markdown"

## **Key Functional Features**

* **Centralized Configuration:**  
  * **Feature:** Manage all AI agent configurations from a single, version-controllable source of truth (e.g., a dedicated Git repository).  
  * **Benefit:** Dramatically simplifies configuration management, reduces duplication, and provides a clear audit trail for all changes to agent behavior.  
* **Hierarchical Overrides:**  
  * **Feature:** Apply configurations at different scopes (Project, User, System) with predictable, deterministic precedence rules.  
  * **Benefit:** Enables platform administrators to set safe, system-wide defaults while empowering individual developers to customize and experiment at the project level without conflict.  
* **Legacy Tool Support:**  
  * **Feature:** Use the accp sync command to manage configurations for existing, non-compliant tools without modifying them.  
  * **Benefit:** Provides immediate value and solves a pressing user problem, driving adoption and creating a smooth migration path towards a fully standardized ecosystem.  
* **Native Integration:**  
  * **Feature:** Provide a simple, high-level SDK for new applications to adopt the ACCP standard directly.  
  * **Benefit:** Radically simplifies the development of new AI agents by eliminating boilerplate configuration code and ensuring they are "good citizens" of the interoperable ecosystem from the start.  
* **Storage Agnosticism:**  
  * **Feature:** Store configuration files anywhere that can be accessed by a URI, including the local filesystem, Git repositories, and web servers.  
  * **Benefit:** Offers maximum flexibility, allowing teams to use their existing, trusted infrastructure for storing and managing configurations without being locked into a specific vendor or platform.  
* **Portability:**  
  * **Feature:** Define an agent's persona, skills, and tools once as a "customization pack" and reuse them across any ACCP-compliant application.  
  * **Benefit:** Unlocks true portability for agent capabilities, fostering an ecosystem where high-quality agent personas can be shared and reused like any other software library.

## **Security Architecture and Considerations**

* **Principle of Least Privilege:** The Synchronizer tool is designed with safety as a primary concern. It will only have permissions to write to the specific file paths explicitly defined in the mapping manifest. Robust path validation will be implemented to prevent directory traversal attacks or accidental overwrites of critical system files.  
* **Input Sanitization:** While ACCP itself does not execute or interpret the content of configuration documents, it is a critical conduit. Consuming applications MUST treat all resolved configurations as untrusted user input. For example, any configuration value that will be rendered in an HTML context must be properly escaped to prevent Cross-Site Scripting (XSS) attacks.  
* **Access Control Delegation:** When using remote stores like private Git repositories or S3 buckets, access control is entirely delegated to the underlying storage provider's mature and battle-tested authentication and authorization mechanisms (e.g., SSH keys for Git, IAM policies for S3). The ACCP tools simply leverage the credentials present in the user's environment.  
* **Templating Security (Future):** The planned templating engine represents a potential security risk. It must be implemented using a securely sandboxed engine (e.g., Jinja2) with its environment strictly controlled. The engine must be prevented from accessing the filesystem, network, or sensitive environment variables to mitigate the risk of arbitrary code execution or information disclosure.

## **Deployment and Distribution Strategy**

* **Core Libraries:** The core Python libraries (Resolver, Client SDK) will be packaged and distributed via the Python Package Index (PyPI) for easy installation using pip.  
* **CLI Tool:** The accp sync utility will be packaged as a standalone, single-binary executable using a tool like PyInstaller. This ensures a frictionless installation experience for end-users, who will not need to have a Python interpreter or manage dependencies. Installers will be provided for Windows, macOS, and Linux.  
* **Documentation:** All protocol specifications, user guides, API documentation, and tutorials will be hosted on a public, versioned website built with a modern static site generator and hosted on GitHub Pages.  
* **CI/CD:** A robust CI/CD pipeline using GitHub Actions will fully automate the testing, packaging, and publishing of all libraries, executables, and documentation. This ensures high quality and rapid, reliable releases.

## **Dependencies and Libraries**

* **Language:** Python 3.9+  
* **CLI Framework:** A modern, type-hinted Python CLI library like Typer or Click to provide a robust and user-friendly command-line interface.  
* **Configuration Parsing:** PyYAML for handling YAML files and the standard library json module.  
* **External URI Handling:** A library like GitPython will be required to implement the git:// URI scheme. The requests or httpx library will be used for http:// and https:// URIs.  
* **Testing:** Pytest will be used for writing clear, scalable unit and integration tests.  
* **Documentation:** Sphinx with the Furo theme will be used to auto-generate professional API documentation from docstrings.

## **Phased Development Plan & User Stories**

### **Milestone 1: Core Protocol & Filesystem MVP**

* **Objective:** Establish the core data models and a functional, in-memory resolver for the local filesystem use case. This milestone is about building a solid, well-tested foundation.  
* **User Stories:**  
  * As a protocol developer, I want to formalize the Customization object schema in a JSON Schema document so that there is a clear, unambiguous, and machine-verifiable specification.  
  * As a protocol developer, I want to implement a CustomizationResolver that can correctly apply scope-based precedence (Project \> User \> System) so that configuration overrides are predictable and deterministic.  
  * As a protocol developer, I want the resolver to handle file:// URIs, including both absolute and relative paths, so that it can read configurations from the local filesystem.  
* **Acceptance Criteria:** A comprehensive test suite exists that verifies the resolver correctly merges configurations from three different scope levels, respecting the composition\_strategy metadata.

### **Milestone 2: The Synchronizer (The Bridge to Legacy)**

* **Objective:** Deliver the accp sync CLI tool for end-users. This is the most critical milestone for driving initial adoption and proving the protocol's value.  
* **User Stories:**  
  * As an end-user, I want a CLI command accp sync that reads an accp.map.yaml file and writes the correct configurations to their destinations so that I can manage my existing tools from a central location.  
  * As an end-user, I want the accp sync command to be idempotent so that running it multiple times in a CI/CD pipeline does not cause errors or unnecessary file changes.  
  * As an end-user, I want to use a \--dry-run flag to preview what changes the synchronizer will make without writing any files, so I can safely verify my mapping configuration.  
  * As an end-user, I want clear "Getting Started" documentation with recipes for managing my VS Code, Cursor, and Zed configurations via ACCP so that I can immediately solve my "configuration hell" problem.  
* **Acceptance Criteria:** Running accp sync twice in a row on an unchanged configuration results in zero file system writes on the second run, and the CLI reports this clearly.

### **Milestone 3: The Native Client & SDK**

* **Objective:** Provide the official Python library to enable developers of new applications to adopt ACCP natively.  
* **User Stories:**  
  * As a developer, I want to pip install accp and use a simple API like accp.get\_document() to fetch my application's configuration so that I can avoid writing my own configuration-loading logic.  
  * As a developer, I want comprehensive API documentation with clear examples and "how-to" guides so that I can quickly and correctly integrate the ACCP client into my new agent.  
  * As a developer, I want a reference "hello world" agent application that is configured entirely via the ACCP client so that I have a complete, working example to follow.  
* **Acceptance Criteria:** The SDK can be installed via pip into a virtual environment and can resolve a project-scoped configuration with a single function call.

### **Milestone 4: Advanced Features & Ecosystem Growth**

* **Objective:** Evolve the protocol based on community feedback and expand its capabilities to support more advanced, collaborative use cases.  
* **User Stories:**  
  * As a user on a team, I want to resolve configurations from a remote git:// URI (e.g., git://github.com/my-org/agent-configs.git?ref=main/prompts/analyst.md) so that my team can manage shared configurations in a version-controlled repository.  
  * As a developer, I want to use a simple, secure templating syntax (like Jinja2) in my configuration documents to dynamically inject runtime variables (e.g., the current filename or date) into my prompts.  
* **Acceptance Criteria:** The resolver can successfully clone a remote public Git repository and read a configuration file from it.

## **Risks and Mitigations**

| Risk | Description | Mitigation Strategy |
| :---- | :---- | :---- |
| **Slow Adoption** | The protocol is perceived as a "solution in search of a problem" or as "yet another standard" and fails to gain traction with users and developers. | **Aggressively focus on Milestone 2 (The Synchronizer).** This provides immediate, tangible value to users by solving a painful, existing problem without requiring any developer changes. Create high-quality documentation, blog posts, and tutorials with compelling "recipes" (e.g., "How to Unify Your Prompts Across VS Code, Cursor, and Zed"). Success here will create a strong pull for native adoption. |
| **Protocol Over-Engineering** | The specification becomes bloated with complex, niche features, making it difficult to implement correctly and increasing the barrier to entry for new clients. | **Adhere strictly to an iterative development plan.** Defer advanced features like templating and complex composition strategies until the core protocol is proven and there is clear community demand. Establish a formal, lightweight RFC process and a "Protocol Council" or BDFL to act as stewards, ensuring the spec remains focused, pragmatic, and simple. |
| **Inconsistent Implementations** | Different third-party clients interpret the specification differently, leading back to the same fragmentation the protocol was designed to solve. | **Provide an official reference implementation (the Python library) and a separate, public compliance test suite.** This suite will contain a set of standard test cases (configuration files and expected outputs) that any implementation can run against. A client must pass the full compliance suite to be officially considered "ACCP-compliant," ensuring consistent and predictable behavior across the entire ecosystem. |

