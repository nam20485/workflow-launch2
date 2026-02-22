# **ImperativeUI: Enhanced Development Plan**

This document provides a comprehensive, multi-phase development plan for the ImperativeUI application. It incorporates the architectural decisions made, outlines the core technologies, and defines user stories for key features.

## **1\. Motivation & Guiding Principles**

ImperativeUI is born from the need to bridge the gap between declarative data models and dynamic, user-friendly interfaces. The primary motivation is to create a tool that can automatically generate an appropriate UI for editing any given set of variables, specified in a simple JSON format. This addresses a common pain point for developers and technical users who frequently work with configuration files, API payloads, or simple data models. The goal is to eliminate the tedious, error-prone, and repetitive work of building manual UIs for these tasks, accelerating workflows for internal tools, rapid prototyping, and simple data entry applications.

The project is guided by three core principles:

1. **Modularity:** The system must be composed of independent, swappable components. The Specifier \-\> Generator \-\> Viewer pattern is central to this, ensuring the logic that defines the UI is entirely separate from the technology that renders it. This architectural purity is paramount, as it allows for future evolution. For example, the AI-based Generator could be replaced with a different model or a more advanced rules engine, or the native Avalonia Viewer could be swapped for an HTML-based one for a web version, all without requiring a complete application rewrite. This enhances testability, maintainability, and long-term viability.  
2. **Performance:** As a desktop application, the user experience must be fluid and responsive. UI generation must be fast, even for complex configurations, and the final rendered interface should have a low memory and CPU footprint. This ensures the application is a lightweight utility that can run alongside other demanding development tools without degrading system performance. All potentially long-running operations, such as file I/O and AI generation, must be handled asynchronously to keep the UI from freezing.  
3. **Native User Experience:** The application must feel completely at home on the user's operating system. This means adhering to platform conventions for look, feel, and behavior, including proper windowing, context menus, and accessibility features. A native experience fosters trust and usability, making the application feel like a professional, integrated tool rather than a disjointed web page embedded in a native frame.

## **2\. Architectural Decisions**

Our collaborative analysis led to a key architectural decision: **to render the dynamic UI using native Avalonia controls**. This choice was made after a careful evaluation of the trade-offs between different rendering technologies.

We evaluated three primary options:

1. **WebView \+ Web Frameworks:** This approach offered maximum styling flexibility by leveraging the entire web ecosystem (HTML, CSS, JS). However, it was ultimately rejected due to the significant complexity of creating a reliable and secure two-way data binding bridge between C\# and JavaScript. Furthermore, the performance overhead of running an entire browser instance and the potential for a disjointed, non-native user experience were considered major drawbacks.  
2. **Dynamic XAML Generation:** This option involved generating Avalonia's XAML markup as a string and parsing it at runtime. While it offered a declarative approach, it was dismissed due to the performance penalty associated with runtime XAML parsing, which can introduce noticeable UI loading delays. It also presented minor security concerns and made the debugging process more opaque compared to working with C\# objects directly.  
3. **Native Avalonia Control Renderer:** This chosen approach involves programmatically creating instances of native controls (TextBox, Slider, etc.) and adding them to the visual tree. It was selected for its **optimal performance, simplicity, type-safe and reliable data binding, and a seamless native user experience**. The perceived limitation in styling flexibility is effectively mitigated by leveraging Avalonia's powerful theming systems. By using the default **Fluent UI** theme or community-driven alternatives like **Material Design**, we can achieve a polished, professional, and consistent look and feel across all target platforms, making this the most robust and well-rounded solution for our goals.

## **3\. Core Technologies**

* **Language:** C\# \- Chosen for its strong typing, performance, and mature ecosystem, making it ideal for building reliable and maintainable desktop applications.  
* **Framework:** .NET (latest stable version, e.g., .NET 10\) \- Provides the modern, cross-platform foundation for the entire application.  
* **UI Framework:** Avalonia \- Selected for its true cross-platform capabilities, allowing a single C\# codebase to produce native applications for Windows, macOS, and Linux. Its adherence to modern UI patterns and the MVVM paradigm makes it a powerful choice.  
* **Default Theme:** Fluent UI for Avalonia \- This will be used to ensure a modern, clean, and professional aesthetic that feels native on Windows and looks great on other platforms.  
* **Architectural Pattern:** Model-View-ViewModel (MVVM) \- Enforces a strict separation of concerns between the UI (View) and the application logic and state (ViewModel), which is critical for testability and maintainability.  
* **MVVM Toolkit:** CommunityToolkit.Mvvm \- This library will be used to accelerate MVVM development by using source generators to reduce boilerplate code for observable properties and commands, a modern .NET best practice.  
* **AI Integration (Future):** A standard HttpClient for making REST API calls to a Large Language Model (LLM) endpoint. The architecture is designed to be model-agnostic.

## **4\. Phased Development Plan**

### **Phase 1: Foundation & Intermediate Representation**

This phase focuses on establishing the project structure and the critical "language" that the Generator and Viewer will use to communicate. A well-designed intermediate representation is the key to the entire architecture's success.

* **Task 1.1: Project Scaffolding.**  
  * Create a new solution containing three projects to enforce modularity:  
    * ImperativeUI.Core: A .NET class library for shared models, interfaces, and the UI schema definitions. It will have no dependencies on UI frameworks.  
    * ImperativeUI.Generator: A .NET class library containing the logic for generating the intermediate UI schema.  
    * ImperativeUI.Desktop: The main Avalonia application project, containing all Views, ViewModels, and the native renderer.  
* **Task 1.2: Design the UI JSON Schema.**  
  * In ImperativeUI.Core, define a set of C\# record types that model the intermediate UI representation. This schema will be the canonical "contract" between the generator and the viewer. It will be versioned to allow for future additions without breaking backward compatibility.  
  * **Initial Schema Example with More Detail:**  
    // In UiSchema.cs  
    public record UiSchema(string Title, List\<ControlModel\> Controls);

    public record ControlModel(  
        string ControlType,  
        string VariableName,  
        string Label,  
        string? Description \= null, // For tooltips  
        object? DefaultValue \= null,  
        List\<ValidationRule\>? Validation \= null  
    );  
    // Plus specific records for different control types to carry unique properties  
    public record TextBoxModel(...) : ControlModel(...);  
    public record SliderModel(double MinValue, double MaxValue, ...) : ControlModel(...);

* **Task 1.3: Define Initial Control Types.**  
  * The schema will initially support label, textbox, numeric, slider, checkbox, and dropdown. Each will have a corresponding C\# record to hold its specific properties.

### **Phase 2: The Generator Module**

This module's purpose is to translate the input configuration into the intermediate UI JSON defined in Phase 1\. We will start with a simple, predictable implementation to facilitate development and testing of the renderer.

* **Task 2.1: Define the Generator Interface.**  
  * In ImperativeUI.Generator, create the IGeneratorService interface. This abstraction is crucial for decoupling the application from the specific generator implementation.  
    // In IGeneratorService.cs  
    public interface IGeneratorService {  
        Task\<UiSchema\> GenerateUIAsync(string inputJsonConfig);  
    }

* **Task 2.2: Create a Stub (Rule-Based) Implementation.**  
  * To enable parallel development of the Viewer, create a simple StubGeneratorService. This class will implement IGeneratorService using a deterministic set of if/else or switch statements. It will map input variable types (e.g., "string", "integer", "boolean") to the appropriate intermediate JSON control objects. This stub will serve as the baseline implementation and a valuable test harness for the renderer.

### **Phase 3: The Native Avalonia Viewer & Renderer**

This phase builds the user-facing application and the logic to render the native UI from the intermediate representation.

* **Task 3.1: Implement the Main ViewModel.**  
  * In ImperativeUI.Desktop, the MainViewModel will manage the application state using the CommunityToolkit.Mvvm.  
  * It will contain an ObservableCollection\<Control\> property to hold the dynamically generated controls for the View, and a Dictionary\<string, object\> to store the actual form data, which will serve as the binding source.  
* **Task 3.2: Implement the Dynamic Control Renderer.**  
  * Create a DynamicControlRenderer service. Its primary method will accept a UiSchema object and a target Avalonia Panel.  
  * The renderer will iterate through the controls array in the schema. For each entry, it will use a switch statement on the controlType to instantiate the corresponding native Avalonia control (e.g., new TextBox(), new CheckBox()).  
  * **Crucially, it will programmatically create a two-way binding** between the control's value property (e.g., TextBox.TextProperty, CheckBox.IsCheckedProperty) and the corresponding entry in the ViewModel's data dictionary, using the variableName from the schema as the key. This ensures that changes in the UI update the data model and vice-versa.  
* **Task 3.3: Build the Main View.**  
  * The MainView.axaml will be simple and declarative. It will contain a button to trigger the file loading process (bound to a command in the ViewModel) and a Panel (such as a StackPanel inside a ScrollViewer) that serves as the container for the dynamically rendered controls.

### **Phase 4: AI Integration**

This phase replaces the stub generator with a true AI-powered implementation, unlocking more intelligent and context-aware UI generation.

* **Task 4.1: Implement the LLM Generator Service.**  
  * Create a new class, LlmGeneratorService, that implements IGeneratorService. This class can be swapped in via dependency injection.  
  * This class will construct a detailed prompt for the LLM. The prompt engineering is critical here: it will include the user's input JSON config and, most importantly, the **JSON schema definition and few-shot examples** of the target intermediate representation to guide the model's output.  
  * It will make an asynchronous API call to the LLM and receive a string response.  
* **Task 4.2: Implement Response Validation.**  
  * The LLM's string response will be deserialized into the C\# UiSchema objects. This deserialization step serves as the primary, strict validation. If it fails, it means the LLM did not adhere to the requested schema.  
  * Implement a retry mechanism to handle validation failures. If deserialization fails, the application can make a subsequent call to the LLM, including the original prompt plus the error message, asking it to correct its previous output.

## **5\. User Stories**

### **Epic: Core UI Generation**

* As a user,  
  I want to select a JSON configuration file from my computer using a native file dialog,  
  So that I can provide the application with the variables I need a UI for.  
* As a user,  
  I want the application to automatically generate a set of UI controls that logically match the variables and types in my configuration file,  
  So that I can easily view and edit their values without any manual UI setup.  
* As a developer,  
  I want the UI generation logic to be based on an intermediate, declarative representation,  
  So that the system is modular, easily testable, and the rendering logic is decoupled from the initial generation step.

### **Epic: Data Interaction**

* As a user,  
  I want the generated UI controls to be populated with the initial values provided in my configuration file,  
  So that I can see the current state of my data without having to re-enter it.  
* As a user,  
  I want to modify the values in the UI controls (e.g., type in a textbox, move a slider, check a box),  
  So that I can intuitively change the configuration data.  
* As a developer,  
  I want to be able to easily retrieve the complete, updated data state from all UI controls as a single data object,  
  So that I can implement features to save the modified configuration or use it in other parts of the application.

### **Epic: AI-Powered Generation**

* As a developer,  
  I want to replace the simple rule-based generator with one that uses a Large Language Model,  
  So that the mapping from input configuration to UI can be more intelligent and flexible, potentially inferring better control types from variable names and context.  
* As a developer,  
  I want the LLM's output to be strictly validated against a C\# schema before rendering,  
  So that I can ensure the AI is producing safe, predictable, and reliable UI definitions and prevent rendering errors or unexpected behavior.

### **Epic: Usability & Error Handling**

* As a user,  
  I want to see a clear, user-friendly error message if I select a file that is not valid JSON,  
  So that I understand what went wrong and can correct it.  
* As a user,  
  I want to see a loading indicator or a busy state in the UI while a new interface is being generated,  
  So that I know the application is working and hasn't frozen.