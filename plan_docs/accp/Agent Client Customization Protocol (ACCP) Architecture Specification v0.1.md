# **Agent Client Customization Protocol (ACCP)**

## **Architecture Specification v0.1**

### **1\. Overview & Vision**

This document outlines the technical architecture for the Agent Client Customization Protocol (ACCP). The core vision is to create a unified, abstract standard for AI agent configuration that decouples the *definition* of a customization from its *physical storage*. This decoupling is the key to solving the widespread problem of "configuration hell," where developers and users must manage a chaotic landscape of disparate and incompatible configuration files for every AI agent and tool.

The current state leads to brittle integrations, significant engineering overhead, and a frustrating user experience. ACCP addresses this by introducing a clear, predictable, and portable system. This architecture is pragmatically designed to support a two-phase adoption:

1. **Immediate Value:** A legacy-compatible "adapter" model that allows users to centralize their configurations for existing, unmodified tools.  
2. **Long-Term Standardization:** A native client SDK that enables new applications to adopt ACCP as their standard, fostering a more robust and interoperable ecosystem.

The ultimate goal is a world where an agent's "persona," skills, and tools are as portable and manageable as any other software asset, enabling a true marketplace of reusable, enterprise-grade AI components.

### **2\. Architectural Diagram**

This diagram illustrates the four core components of the ACCP ecosystem: the **Agnostic Store**, the **Customization Resolver**, the native **ACCP Client**, and the legacy **ACCP Synchronizer**. The Resolver is the central hub, acting as an intermediary that fetches raw data from the store and provides composed, ready-to-use context to both native clients and the synchronizer. This hub-and-spoke model ensures that consuming applications are isolated from the complexities of storage and composition logic.

### **3\. Core Components**

#### **3.1. Agnostic Configuration Store**

This is a conceptual component representing any storage backend for customization documents. ACCP is intentionally designed to be agnostic to the storage implementation, interacting with it solely through a standard interface.

* **Interface:** The system interacts with the store via a URI (Uniform Resource Identifier). This allows for immense flexibility in choosing a storage solution that fits the use case. Supported schemes should include file://, git://, http(s)://, and potentially vendor-specific schemes like s3:// or db://.  
* **Examples:**  
  * **Local Filesystem:** A directory like .accp/ in a user's home or project directory. Simple and effective for individual use.  
  * **Git Repository:** A remote repository containing version-controlled configurations. This provides a powerful model for team collaboration, auditing, and rollbacks.  
  * **Object Storage:** An S3 bucket or similar service for cloud-native, scalable deployments.  
  * **Database:** A relational or NoSQL database for programmatic management of configurations, enabling fine-grained access control and dynamic lookups.  
* **Responsibility:** To perform basic CRUD (Create, Read, Update, Delete) operations on raw document content (e.g., Markdown, JSON, YAML) based on a given URI. It has no knowledge of ACCP's logic.

#### **3.2. Customization Resolver**

The "brain" of the ACCP system. It is a stateless service or library responsible for transforming a list of abstract Customization definitions into a final, ready-to-use set of context documents for an agent.

* **Inputs:** A list of Customization objects and a target context (e.g., the current project directory, active user).  
* **Responsibilities:**  
  1. **Discovery:** Identifies all Customization manifest files (e.g., accp.json) relevant to the current context. It does this by searching a predefined hierarchy of locations, such as the current project directory, the user's home directory, and system-wide configuration directories.  
  2. **Resolution:** For each discovered Customization definition, it uses the appropriate access layer to fetch the raw document content from the store via its URI. It should employ caching strategies to minimize redundant fetches.  
  3. **Precedence & Composition:** Applies a deterministic set of rules to handle overrides and merging. The default rule for precedence is that more specific scopes override more general ones: Project \> User \> System. The composition\_strategy metadata field (replace, prepend, append) allows for more granular control.  
  4. **Templating (Future):** A planned feature to support rendering template documents (e.g., using a Jinja2-like syntax) with runtime variables. This would allow for dynamic context, such as injecting the current date, filename, or user information into a prompt.  
* **Output:** A simple key-value map of the final context documents, where the key is the customization type (e.g., 'accp:core/system-prompt') and the value is the fully resolved string content.

#### **3.3. ACCP Client Library (Native Integration)**

A lightweight SDK (e.g., a Python package, an npm module) that applications integrate to become natively ACCP-compliant, eliminating the need to read configuration files directly.

* **API:** Exposes a simple, high-level API to developers. Key methods would include accp.get\_context() to fetch all resolved documents, and accp.get\_document('accp:core/system-prompt') to get a specific one. A future version could include a watch() method to subscribe to configuration changes.  
* **Function:** Contains a built-in Customization Resolver and transparently handles the entire logic of discovering, fetching, composing, and caching configurations.  
* **Audience:** Primarily for developers of new AI agents, IDEs, and client applications who wish to adopt the ACCP standard.

#### **3.4. ACCP Synchronizer Utility (Legacy Adapter)**

A standalone command-line interface (CLI) tool that bridges the gap for existing applications that are not natively ACCP-compliant. It acts as the engine for the "adapter" pattern.

* **Function:** Reads a declarative Mapping Manifest file, invokes the Customization Resolver to get the final context, and then writes the resulting documents to the specific file paths and formats that legacy applications expect. The tool should be idempotent, meaning running it multiple times will produce the same result without error.  
* **Use Case:** A user can maintain all their agent configurations in a central Git repository and run accp sync to automatically populate the correct settings files for Zed, VS Code, and other tools across their system.  
* **Audience:** End-users and system administrators who need to manage configurations for a heterogeneous toolchain.

### **4\. Data Models & Protocol Definitions**

#### **4.1. Customization Object**

The core data structure representing a single configuration artifact. These objects are typically defined in a manifest file (e.g., accp.json) located in a standard discovery path.

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

* **name (string):** A human-readable name for the customization.  
* **type (string):** A namespaced identifier for the customization's purpose (e.g., accp:core/system-prompt, openai:tools/spec-v1). This is the primary key used by applications.  
* **scope (enum):** The context in which this customization applies. Must be one of System, User, or Project.  
* **uri (string):** The URI pointing to the raw content of the customization document.  
* **version (string):** A semantic version number for the artifact, enabling dependency management and reproducibility.  
* **metadata (object):** A key-value store for arbitrary metadata, such as author, ui\_hints, or a composition\_strategy (replace, prepend, append).

#### **4.2. Mapping Manifest File**

A declarative file, typically accp.map.yaml, used by the ACCP Synchronizer to map resolved ACCP types to physical files in the filesystem.

\# accp.map.yaml  
version: 1  
targets:  
  \- name: "Zed Editor Instructions"  
    type: "accp:core/system-prompt"  
    destination:  
      path: "\~/.config/zed/instructions.md"  
      format: "markdown" \# Future: allows for format conversion  
        
  \- name: "Some Other Tool Config"  
    type: "acme:config/api-settings"  
    destination:  
      path: "/etc/some-tool/config.json"  
      format: "json"

* **version (int):** The version of the mapping file schema.  
* **targets (array):** A list of synchronization targets.  
  * **name (string):** A human-readable name for the mapping rule.  
  * **type (string):** The ACCP customization type to resolve.  
  * **destination (object):** Specifies where and how to write the file.  
    * **path (string):** The destination file path. Environment variables and tildes (\~) should be expanded.  
    * **format (string, optional):** Specifies the output format, enabling future format-shifting capabilities.

### **5\. Interaction Flows**

#### **5.1. Native Client Flow**

This flow describes how a modern, ACCP-compliant application retrieves its configuration.

1. **Initialization:** The application instantiates the ACCP Client library.  
2. **API Call:** The application's code requests its configuration via context \= accp.get\_context().  
3. **Discovery:** The ACCP Client library scans the filesystem hierarchy (e.g., ./.accp/, \~/.config/accp/) for accp.json manifest files.  
4. **Resolution:** It passes the discovered list of Customization objects to its internal Resolver.  
5. **Composition:** The Resolver fetches content for all URIs, applies the scope-based precedence and composition rules, and assembles the final context map.  
6. **Return:** The final map (e.g., {'accp:core/system-prompt': '...', 'openai:tools/spec-v1': '...'}) is returned to the application, which can now use it to configure its agent.

#### **5.2. Synchronizer Flow**

This flow describes how a user manages configuration for legacy, non-ACCP-compliant tools.

1. **User Command:** The user runs accp sync in their terminal.  
2. **Map Discovery:** The Synchronizer CLI finds and reads the accp.map.yaml file from the current directory or a global location.  
3. **Iterate Targets:** It loops through each entry in the targets list.  
4. **Resolve Content:** For each target, it invokes the Resolver to get the final, composed content for the specified type.  
5. **State Check:** It checks if the destination file at path already exists and if its content matches the resolved content.  
6. **Write to Disk:** If the content is different (or the file doesn't exist), it writes the new content to the destination path, creating directories as needed. If the content is the same, it does nothing, ensuring idempotency.  
7. **Output:** The CLI reports a summary of its actions (e.g., Updated: \~/.config/zed/instructions.md, Unchanged: /etc/some-tool/config.json).