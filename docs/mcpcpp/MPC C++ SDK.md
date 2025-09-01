# **MCP C++ SDK: Software Design & Implementation Plan**

This document provides a comprehensive software design, architecture, and step-by-step guide for developing the Model Context Protocol (MCP) C++ SDK.

## **1\. Architecture & Design**

### **1.1. Introduction & Goals**

The primary goal of this project is to create a high-quality, cross-platform, and easy-to-use C++ SDK for the Model Context Protocol (MCP). The SDK will provide a complete implementation of the protocol specification, enabling developers to build robust MCP-based applications (clients, servers, and tools) with minimal boilerplate and a clean, modern C++ interface.

The target audience for this SDK ranges from experienced C++ systems developers integrating MCP into high-performance infrastructure, to application developers who need a simple and reliable way to communicate with an MCP-compliant service without needing to become experts in the underlying RPC mechanisms. By providing a standardized, high-quality implementation, we aim to accelerate the adoption of MCP and foster a rich ecosystem of interoperable tools and services.

### **1.2. Architectural Principles**

The SDK's design is guided by the following core principles, which inform the technical decisions throughout the project:

* **Ease of Use:** The public API should be intuitive and abstract away the underlying complexities of gRPC and Protobuf. Developers should not need to be gRPC experts to use the SDK effectively.  
  * **How we'll achieve this:** We will provide a single client class, McpClient, as the primary entry point. Asynchronous complexity will be hidden, and a custom Result\<T, grpc::Status\> type will be used for return values, making error handling explicit and straightforward, eliminating the need for developers to manage grpc::ClientContext or parse grpc::Status objects manually in typical use cases.  
* **Extensibility:** The server-side architecture must be pluggable. Developers must be able to create and register new "tool providers" without modifying the core SDK or server code.  
  * **How we'll achieve this:** A lean abstract base class, IToolProvider, will define a simple contract for all tools. The ToolRegistry will allow for runtime registration of shared pointers to these tool implementations. This service locator pattern completely decouples the server's core dispatch logic from the concrete tool implementations.  
* **Performance:** The SDK should introduce minimal overhead on top of gRPC, ensuring low-latency communication suitable for high-performance applications.  
  * **How we'll achieve this:** The SDK will avoid unnecessary memory allocations or data copies in the critical request/response path. Client and server objects will be designed to be long-lived to amortize the cost of their creation. The core logic will be lean, focusing on dispatch and not on heavy computation.  
* **Robustness:** The SDK must be well-tested, thread-safe where necessary, and feature a clear, standardized error-handling mechanism.  
  * **How we'll achieve this:** A comprehensive test suite using Catch2 will validate the behavior of each component. Thread-safety will be handled by designing components like the ToolRegistry to be "write-once, read-many," which is inherently safe for concurrent requests without requiring complex locking.  
* **Portability:** The SDK must compile and run seamlessly on Windows, Linux, and macOS, with a consistent build process managed by CMake and vcpkg.  
  * **How we'll achieve this:** We will rely exclusively on platform-agnostic C++20 features and libraries managed by vcpkg. The entire build process will be defined in CMakeLists.txt and driven by CMakePresets.json, ensuring a single, consistent command can configure, build, and test the project on any supported platform.

### **1.3. High-Level Architecture**

The MCP ecosystem consists of three main components: the **Client SDK**, the **Server**, and one or more **Tool Providers**. Communication between the client and server is handled exclusively through a gRPC interface defined by the .proto files. A typical request flows through the system as follows: an application uses the McpClient to make a call; the SDK serializes the request and sends it over the network via gRPC; the McpServer receives the request, authenticates it, and uses the ToolRegistry to dispatch it to the correct IToolProvider; the provider executes its logic and returns a result, which flows back through the same path.

1. **Client SDK (sdk/)**: A C++ library that provides the McpClient. This is the public-facing API that application developers will link against. It handles connection management, request serialization, and response parsing.  
2. **gRPC Layer (protos/)**: The communication backbone. The .proto files define the service contract, including all RPC methods and message structures. The Protobuf compiler and gRPC plugin generate the C++ client stubs and server service interfaces from these files.  
3. **Server (server/)**: A reference implementation that hosts the gRPC service. Its primary role is to receive requests, authenticate them, and dispatch them to the appropriate Tool Provider via the ToolRegistry.  
4. **Tool Provider Framework (sdk/)**: The core of the extensible architecture. It consists of the IToolProvider interface and the ToolRegistry. Custom logic (e.g., connecting to a database, calling another API) is implemented within concrete provider classes.

### **1.4. Detailed Component Design**

* **McpClient**:  
  * **Responsibility:** To provide a simple, blocking API for interacting with the MCP server. It will manage the grpc::Channel and grpc::ClientContext for each call, handling deadlines and metadata for authentication. For streaming RPCs, it will return a wrapper object that allows for easy iteration over incoming messages.  
  * **Implementation Details:** The constructor will take the server address (e.g., "localhost:50051") and credentials. Methods like QueryKnowledgeBase will be exposed directly. Internally, these methods will create a grpc::ClientContext, add the authentication token, call the gRPC stub, and wrap the response in the custom Result type.  
* **McpServiceImpl**:  
  * **Responsibility:** To implement the server-side logic of the gRPC service. It will hold a ToolRegistry instance. Upon receiving a request, it will first pass it through a security interceptor, then use the registry to find the correct IToolProvider and delegate the Execute call.  
  * **Implementation Details:** This class will be a concrete implementation of the mcp::v1::McpService::Service interface generated by gRPC. It will be instantiated within the server's main function and will be injected with a fully populated ToolRegistry via its constructor.  
* **IToolProvider Interface**:  
  * **Responsibility:** To define the contract for all tools. The use of google::protobuf::Any is a critical design choice that decouples the server from the specific message types of the tools, enabling true pluggability.  
  * **Implementation Details:** This will be a simple abstract class with a pure virtual method: virtual grpc::Status Execute(const google::protobuf::Any& request, google::protobuf::Any& response) \= 0;. Concrete providers will implement this, unpack the Any request into their specific Protobuf message type, perform their logic, and pack their response back into the Any response parameter.  
* **ToolRegistry**:  
  * **Responsibility:** To act as a service locator for IToolProvider instances. It will be populated at server startup. The implementation will use a std::unordered\_map\<std::string, std::shared\_ptr\<IToolProvider\>\> for efficient lookups. It will be designed to be populated once and then read from concurrently, making complex thread-locking unnecessary in the common case.  
  * **Implementation Details:** The class will expose methods like RegisterProvider(const std::string& name, std::shared\_ptr\<IToolProvider\> provider) and FindProvider(const std::string& name). The server will call RegisterProvider for each tool it wants to expose during its initialization sequence.

### **1.5. Cross-Cutting Concerns**

* **Security Architecture**:  
  * Security will be implemented using a custom gRPC **Server Interceptor**. This interceptor will be invoked before the actual service method. This approach is superior to checking auth in each method as it centralizes the logic and ensures no service method can be accidentally left unsecured.  
  * It will inspect the grpc::ServerContext for authentication metadata (e.g., an x-api-key header).  
  * The interceptor will validate the token/key against a configurable store. If validation fails, it will immediately return an UNAUTHENTICATED gRPC status, preventing the request from ever reaching the service logic.  
* **Error Handling Strategy**:  
  * A standardized set of gRPC status codes will be used.  
    * INVALID\_ARGUMENT: For malformed requests, including when a google::protobuf::Any cannot be unpacked into the expected type.  
    * NOT\_FOUND: When a requested tool is not in the registry.  
    * UNAUTHENTICATED: For failed security checks from the interceptor.  
    * INTERNAL: For unexpected server-side errors or exceptions within a provider.  
  * The McpClient will translate these gRPC status codes into a user-friendly custom Result\<T, grpc::Status\> object. This allows calling code to use simple if (result.has\_value()) checks while still having access to the detailed grpc::Status (with its error code and message) in the failure case.

## **2\. Feature Roadmap & Priorities**

This section breaks down all features required for a complete protocol implementation, grouped by development priority.

| Priority | Feature | Description | Related Plan Phase |
| :---- | :---- | :---- | :---- |
| **P0: Core** | **gRPC Service & Messages** | All .proto files are defined and compiled. | **Phase 0** (Complete) |
| **P0: Core** | **High-Level Client API (McpClient)** | The primary, user-friendly client class that manages channels and contexts. | **Phase 1** |
| **P0: Core** | **Tool Provider Framework** | The IToolProvider abstract interface and the ToolRegistry for service location. | **Phase 1** |
| **P0: Core** | **Server Dispatch Logic** | McpServiceImpl that implements the gRPC service and routes requests to the registry. | **Phase 2** |
| **P0: Core** | **End-to-End Integration Tests** | Core tests ensuring the client, server, and a mock provider can communicate successfully for a single unary RPC call. | **Phase 2** |
| **P1: Essential** | **Knowledge Provider Interface** | A concrete IToolProvider example for knowledge base queries. | **Phase 2/3 (Examples)** |
| **P1: Essential** | **Memory Provider Interface** | A concrete IToolProvider example for conversational memory. | **Phase 2/3 (Examples)** |
| **P1: Essential** | **Grounding Provider Interface** | A concrete IToolProvider example for grounding checks. | **Phase 2/3 (Examples)** |
| **P1: Essential** | **Authentication Layer** | A gRPC interceptor for API key/token validation. | **Phase 2** |
| **P1: Essential** | **Standardized Error Handling** | Client-side and server-side implementation of defined error codes using the Result type. | **Phase 1 & 2** |
| **P1: Essential** | **API Documentation (Doxygen)** | Generation of the core API reference for all public classes in the sdk/ library. | **Phase 3** |
| **P1: Essential** | **Core Usage Examples** | Working, documented examples for a basic client and a server with a registered mock tool. | **Phase 3** |
| **P2: Enhancement** | **Streaming/SSE Support** | Implementation and testing of server-side streaming RPCs for long-running tasks. | **Phase 2 (Stretch)** |
| **P2: Enhancement** | **Advanced Usage Guides** | Tutorials on topics like advanced error handling, security configuration, and performance tuning. | **Phase 3** |
| **P2: Enhancement** | **Packaging for Distribution** | Creating a clean package for consumption via vcpkg or FetchContent. | **Post-v1.0** |

## **3\. Phased Implementation Plan**

### **Phase 0: Project Validation & Environment Setup**

**Goal:** Validate the existing mcpcpp project structure and ensure the build environment is correctly configured with all necessary dependencies to support the full development lifecycle.

* **Step 0.1: Validate Existing Project Structure & Build System**  
  * **Action:** Review the existing repository layout (sdk/, server/, tests/, protos/, etc.) and the root CMakeLists.txt.  
  * **Verification:** The current separation of concerns is excellent and will be used as the foundation. The CMakePresets.json will be the sole method for configuration and building. Confirm that a clean configure and build (cmake \--preset=default && cmake \--build \--preset=default) completes without errors.  
* **Step 0.2: Verify Dependency Management**  
  * **Action:** Inspect the vcpkg.json manifest file to ensure grpc, protobuf, and catch2 are listed as dependencies.  
  * **Verification:** Confirm the root CMakeLists.txt correctly points to the vcpkg toolchain file (-DCMAKE\_TOOLCHAIN\_FILE=\[path/to/vcpkg\]/scripts/buildsystems/vcpkg.cmake) in its presets.  
* **Step 0.3: Verify Proto Compilation**  
  * **Action:** Confirm that the existing CMake scripts correctly invoke find\_package(Protobuf) and protobuf\_generate to compile the .proto files.  
  * **Verification:** Ensure the generated C++ headers and sources (.pb.h, .pb.cc, .grpc.pb.h, .grpc.pb.cc) are correctly linked as a library (mcp\_protos) to the sdk and server targets.

### **Phase 1: Core SDK Library Implementation (sdk/)**

**Goal:** Build the high-level, easy-to-use C++ library that developers will interact with.

* **Step 1.1: Implement the High-Level Client (McpClient)**  
  * **Action:** Create and implement the McpClient class in a new header (sdk/include/mcp\_client.h) and source file.  
  * **Details:** Encapsulate the grpc::Channel and a std::unique\_ptr to the gRPC stub. Provide simple public methods that wrap RPC calls. For example: Result\<QueryKnowledgeBaseResponse, grpc::Status\> QueryKnowledgeBase(const QueryKnowledgeBaseRequest& req);. This method will handle context creation, deadline setting, and status checking internally.  
* **Step 1.2: Design the Extensible Tool Provider Framework**  
  * **Action:** Create the IToolProvider abstract base class (sdk/include/i\_tool\_provider.h) and the ToolRegistry class (sdk/include/tool\_registry.h).  
  * **Details:** The IToolProvider interface is the key to the extensible design. The ToolRegistry will provide a thread-safe (via its write-once, read-many design) mechanism for registering and retrieving these providers by name.

### **Phase 2: Server Logic & Testing (server/, tests/)**

**Goal:** Implement the server's business logic and ensure system reliability through comprehensive testing.

* **Step 2.1: Implement the MCP Service Logic**  
  * **Action:** Create the McpServiceImpl class inheriting from the generated gRPC service interface.  
  * **Details:** The service will hold the ToolRegistry and implement the dispatch logic for all RPC methods. For example, its QueryKnowledgeBase method will look up the "knowledge" provider in the registry and call its Execute method.  
* **Step 2.2: Implement Authentication & Error Handling**  
  * **Action:** Create the gRPC server interceptor for authentication. Implement the standardized error code logic within the McpServiceImpl methods, returning appropriate grpc::Status objects on failure.  
  * **Details:** This involves creating a factory class that produces interceptor instances, which are then added to the grpc::ServerBuilder during server setup.  
* **Step 2.3: Write Unit Tests with Catch2**  
  * **Action:** Create unit tests for key components. Test the ToolRegistry's ability to register and retrieve providers. Test the logic of the security interceptor in isolation by mocking its dependencies.  
  * **Details:** Use Catch2's TEST\_CASE and REQUIRE macros. For example, test that registry.FindProvider("nonexistent") returns a null pointer.  
* **Step 2.4: Write Integration Tests**  
  * **Action:** Create end-to-end tests following the "Arrange-Act-Assert" pattern.  
  * **Details:** The test setup will use grpc::ServerBuilder to start a real gRPC server on a local port (e.g., localhost:0 to pick any available port). A mock tool provider will be registered. The test will then use the McpClient to call the in-process server and assert that the response is correct. This is the most critical step for ensuring the entire system works together.

### **Phase 3: Documentation (docs/) & Examples (examples/)**

**Goal:** Create comprehensive, user-friendly documentation to fulfill the primary objective of ease of use.

* **Step 3.1: Configure Doxygen**  
  * **Action:** Create a Doxyfile in the docs/ directory and configure it to read the headers in sdk/include. Integrate it with CMake to create a doc build target that runs Doxygen.  
  * **Verification:** Running cmake \--build \--preset=default \--target doc should generate a docs/html directory with the API reference.  
* **Step 3.2: Add API Documentation Comments**  
  * **Action:** Add Doxygen-style comments (using /// or /\*\* ... \*/) to all public classes, methods, and parameters in the SDK headers.  
  * **Details:** Explain what each class does, what each method's parameters are, what it returns, and any pre-conditions or exceptions.  
* **Step 3.3: Write Usage Guides and Implement Examples**  
  * **Action:** Create Markdown tutorials in docs/guides/ for: (1) "Getting Started", (2) "Building a Simple Client", and (3) "Building a Server with Custom Tools".  
  * **Action:** Implement the full, compilable, and well-commented source code for these tutorials in the examples/ directory. These examples are a crucial part of the documentation and must be kept up-to-date and working.