# **New Application**

## **App Title**

GHCP Interaction Intelligence Platform

## **Development Plan**

The plan is to create a new class of developer tooling designed to provide **observability, explainability, and optimization** for the collaborative partnership between a human developer and an AI coding assistant like GitHub Copilot. This involves moving beyond simple interaction logs to create a comprehensive, correlated view of the entire developer-AI workflow. Observability will be achieved by capturing data from multiple sources simultaneously. Explainability will come from visualizing this data in a way that reveals the "why" behind the AI's behavior. Optimization will be the ultimate outcome, empowering developers to refine their prompts and context to achieve better results, faster.

The platform will be a modular, multi-process system composed of three main components that work in concert:

1. **Desktop Client (The Hub):** The primary user-facing application built with .NET 9/Avalonia UI. This is the central command center where users will review session data, explore visualizations, and access analytical reports. Its cross-platform nature ensures a consistent experience for all developers, regardless of their operating system.  
2. **Local Proxy Service (The Collector):** A background ASP.NET Core service using YARP to intercept and capture API traffic. This service acts as a silent, local network monitor, capturing the raw, unaltered payloads sent to and from the AI assistant's backend. This provides the ground truth for what the AI was given and what it returned, which is essential for deep diagnostics.  
3. **VS Code Extension (The Instrument):** A lightweight TypeScript extension for deep IDE integration. This component provides the rich, real-time context that logs and network traffic alone cannot, such as the user's current code selection, active file, and other IDE-specific events, streaming this information directly to the Hub.

The core philosophy is **"Trust by Design,"** meaning V1.0 is exclusively a **local-first** application where no user data leaves the user's machine. This is a non-negotiable principle. It means no cloud accounts are required, the application is fully functional offline, and the user retains complete ownership and control over their data. All potentially sensitive data, including source code snippets and API keys found in traffic, will be encrypted at rest in a local ArangoDB database using robust AES-256 encryption.

## **Description**

### **Overview**

The Interaction Intelligence Platform empowers developers by demystifying the AI "black box" of modern coding assistants. In the current landscape, when an AI provides a suboptimal or incorrect suggestion, developers have limited recourse to understand why. This platform addresses that pain point by capturing, analyzing, and visualizing the complete context of interactions between a developer and an AI. It transforms raw, disparate sources of information—such as unstructured debug logs, raw API traffic, and real-time IDE events—into a unified, coherent, and actionable intelligence stream.

This helps developers improve their prompt engineering skills by seeing direct correlations between the quality of their input and the AI's output. It allows them to understand the AI's behavior in specific contexts and, ultimately, to optimize their workflow for greater efficiency and better outcomes. The platform provides concrete insights, for example, by revealing which files included as context were most influential or how the phrasing of a prompt impacted the AI's response latency and token count. It is a secure, private, and local-first environment designed for professional self-improvement.

### **Document Links**

* [Development Plan & Specification](./Interaction%20Intelligence%20Platform%20-%20Dev%20Plan.md)  
* [Interactive Project Plan](./Interaction%20Intelligance%20Platform.html)  
* [Project Status](./Interaction%20Intelligence%20Platform%20v1.0%20-%20Status.md)

## **Requirements**

### **Features**

The project will be delivered in a phased approach, ensuring that a stable, valuable core product is established before more complex analytical features are added. Phase 1 focuses entirely on building the foundational data capture pipeline and establishing user trust through robust security and privacy features. Phases 2 and 3 will build upon this foundation to deliver advanced analytics and deeper workflow integrations.

* **F-101:** Multi-Source Log Aggregation  
* **F-102:** "Deep Diagnostics Consent" Wizard  
* **F-103:** Automated & Guided Certificate Installation  
* **F-104:** "Safe Sessions" Vault (AES-256 Encryption)  
* **F-105:** Unified Thread View  
* **F-106:** Session Security UI  
* **F-107:** Basic Performance Metrics  
* **Phase 2 Features (F-201 to F-206):** Advanced Analytics & Tooling  
* **Phase 3 Features (F-301 to F-304):** Workflow Integration & Extensibility

### **Test cases**

* **Unit Testing:** The goal of \>90% code coverage is critical for ensuring the reliability of core components, particularly those that are security-sensitive or handle complex data transformations. The encryption service, all log parsing logic, and the state management for the consent flow will be subject to exhaustive unit tests using xUnit, Moq, and FluentAssertions to verify their correctness and robustness.  
* **Integration Testing:** Full data pipeline tests will be designed to validate the end-to-end flow of information through the system. A typical test will simulate a user action in VS Code, trigger an event from the extension, verify its reception at the SignalR hub, confirm the local proxy intercepts the corresponding API call, and finally assert that all related data is correctly parsed, encrypted, and stored as a single, correlated interaction in the ArangoDB database.  
* **UI Testing:** Automated UI tests, built with AvaloniaUI Test Automation, will focus on critical, user-facing workflows that are essential for trust and usability. This includes the multi-step "Deep Diagnostics Consent" wizard, the certificate installation process, and the session lock/unlock functionality, ensuring these security features work as expected and are clearly communicated to the user.

### **Logging**

* The application's primary function is to aggregate and parse logs from multiple, disparate sources. This involves a significant technical challenge in creating a unified event schema that can normalize data from various formats, including the verbose, unstructured text of debug logs, the structured JSON of API request/response bodies, and the custom event format streamed from the VS Code extension. This schema will be the foundation for all subsequent analysis and visualization.

### **Containerization: Docker**

* While the core application components are intended to run as native processes, the ArangoDB database will be managed via Docker for the development environment. This approach provides developers with a consistent, isolated, and easily reproducible database setup, eliminating the need for manual installation and system-wide configuration of the database, thereby simplifying the onboarding process for new contributors.

### **Containerization: Docker Compose**

* Not specified.

### **Swagger/OpenAPI**

* Not specified, as the primary service is a local proxy for data capture, not a public-facing API intended for consumption by other services.

### **Documentation**

* Detailed user-facing documentation is a key requirement, especially for security-critical features. The documentation will provide clear, step-by-step guides for the "Deep Diagnostics Consent" wizard and the certificate installation process, complete with platform-specific instructions and comprehensive troubleshooting guides. It will also include documentation on how to interpret the data presented in the application, such as the Unified Thread View and the performance metrics.

### **Acceptance Criteria**

* Each feature in Phase 1 (F-101 through F-107) has a detailed set of specific, measurable, and testable acceptance criteria defined in the main development plan document. These criteria will be used to verify that each feature has been implemented correctly and meets all functional and security requirements.

## **Language**

C\# and TypeScript

## **Language Version**

.NET 9+

## **Frameworks, Tools, Packages**

* **Desktop Client:** Avalonia UI. Chosen for its modern, cross-platform capabilities, allowing a single C\# codebase to target Windows, macOS, and Linux with a consistent, high-performance UI.  
* **Services & Orchestration:** .NET Aspire. Selected to simplify the complexity of managing a multi-process application, providing a unified framework for launching, debugging, and configuring the desktop client and background services.  
* **API Proxy Service:** ASP.NET Core, YARP (Yet Another Reverse Proxy). YARP is a highly efficient and extensible reverse proxy toolkit, making it the ideal choice for building a performant, local API interception service.  
* **Database:** ArangoDB (Multi-model NoSQL/Graph). Its native support for both document and graph models is critical. It allows chat interactions to be stored as documents while enabling the creation of a graph structure to analyze the complex relationships between prompts, code context, and AI responses.  
* **VS Code Extension:** TypeScript, SignalR Client. TypeScript is the standard for VS Code development. The SignalR client provides a robust, real-time communication channel back to the desktop application.  
* **Real-time Communication:** SignalR. Provides a more structured and resilient communication protocol than raw WebSockets, with built-in features for connection management and RPC-style method invocation.  
* **CI/CD:** GitHub Actions. Chosen for its seamless integration with GitHub repositories, enabling automated builds, testing, and packaging for all target platforms on every commit.  
* **Testing:** xUnit, FluentAssertions, Moq. A standard, robust, and widely-used testing stack in the .NET ecosystem, providing all necessary tools for comprehensive unit and integration testing.

## **Project Structure/Package System**

* **Windows:** An MSIX package will be created. This modern packaging format provides a clean, reliable installation and uninstallation experience, enhances security through containerization, and is the preferred format for distribution via the Microsoft Store.  
* **macOS:** A notarized .dmg file will be provided. Notarization by Apple is a mandatory security step that assures users the application has been checked for malicious components, which is essential for user trust on the macOS platform.  
* **Linux:** .deb and .rpm packages will be distributed via a dedicated apt and yum repository. This is the standard for Linux software distribution and allows users to easily install and receive updates using their native package managers.

## **GitHub**

### **Repo**

[https://github.com/nam20485/ghcp-intelligence-platform](https://www.google.com/search?q=https://github.com/nam20485/ghcp-intelligence-platform)

### **Branch**

*To be determined.*

## **Deliverables**

* A cross-platform desktop application (Windows, macOS, Linux), ensuring a consistent feature set and user experience across all major developer operating systems.  
* A VS Code Extension, responsible for capturing and streaming the deep, real-time IDE context that is unavailable through logs or network traffic alone.  
* Digitally signed installers for all three major operating systems, ensuring authenticity and a smooth, secure installation process for users.  
* Comprehensive unit, integration, and UI test suites, delivered as part of the codebase to guarantee the project's long-term quality, stability, and maintainability.