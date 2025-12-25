# **Prioritized Next Steps & Roadmap (v1.2 Expanded)**

With the core backend architecture complete, operational, and resilient, here is the prioritized roadmap for adding the core functionality.

### **Priority 1: Implement the IOpenAiClient (The "Brain")**

**Goal:** This is the most critical next step. We will replace the NotImplementedException in your OpenAiClient stub with a real, asynchronous HTTP call to the OpenRouter API. This is the implementation that plugs in the agent's "brain" and allows it to "think" (i.e., use an LLM as a reasoning engine) for the first time. The current architecture is designed to fail gracefully when this stub is hit; this implementation will complete that loop.

**Plan:**

1. **Inject Dependencies:** In your DotnetAgents/IntelAgent/OpenAiClient.cs file, inject IHttpClientFactory and IConfiguration.  
   * **Why IHttpClientFactory?** This is the modern .NET standard for managing HttpClient lifecycles. It provides performance benefits (by pooling handlers) and is the entry point for adding advanced resilience policies (like automatic retries via Polly) later.  
   * **Why IConfiguration?** This is to securely read the OpenRouter:ApiKey from your appsettings.json or, more securely, from user secrets.  
2. **Register HttpClient in AgentApi:** In DotnetAgents/DotnetAgents.Agent/Program.cs, we must register a *typed client*. This is a best practice that binds the IOpenAiClient interface to a concrete HttpClient configuration. This encapsulates the API's base address and authentication, keeping your OpenAiClient class clean.  
   // In Program.cs, where you register other services

   // This line registers IHttpClientFactory  
   builder.Services.AddHttpClient(); 

   // This registers a specific, typed client for your interface  
   builder.Services.AddHttpClient\<IOpenAiClient, OpenAiClient\>(client \=\>  
   {  
       // Set the base URL for all requests made by this client  
       client.BaseAddress \= new Uri("\[https://openrouter.ai/api/v1/\](https://openrouter.ai/api/v1/)");

       // Get the API key from configuration (user secrets or appsettings.json)  
       // Ensure "OpenRouter:ApiKey" is set in your app's configuration\!  
       var apiKey \= builder.Configuration\["OpenRouter:ApiKey"\];  
       if (string.IsNullOrEmpty(apiKey))  
       {  
           throw new InvalidOperationException("OpenRouter:ApiKey is not set in configuration.");  
       }

       // Add the Bearer token to every request  
       client.DefaultRequestHeaders.Authorization \=   
           new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);

       // OpenRouter also requires a custom Referer header  
       client.DefaultRequestHeaders.Add("HTTP-Referer", "\[https://github.com/intel-agency/DotnetAgents\](https://github.com/intel-agency/DotnetAgents)");  
   });

3. **Build Request & Response DTOs:** To send a request, we must serialize C\# objects to JSON. We need to create DTO (Data Transfer Object) records that precisely match the API's contract. We can add these as private records inside OpenAiClient.cs or in a new Models folder within the IntelAgent project.  
   // \--- Request DTOs \---  
   // We need to build these objects to send \*to\* OpenRouter

   // Represents the 'tool' object in the API request  
   private record ToolDefinition(string type, FunctionDefinition function);  
   private record FunctionDefinition(string name, string description, object parameters);

   // Represents the overall request payload  
   private record ChatRequest(  
       string model,   
       List\<Message\> messages,   
       List\<ToolDefinition\> tools  
   );

   // \--- Response DTOs \---  
   // We expect OpenRouter to send us objects matching this shape

   // The top-level response  
   private record ChatResponse(List\<Choice\> choices);

   // The first (and usually only) choice  
   private record Choice(ResponseMessage message);

   // The message containing the agent's thought and tool calls  
   private record ResponseMessage(string? content, List\<ToolCallResponse\>? tool\_calls);

   // A single tool call from the API  
   private record ToolCallResponse(string id, string type, FunctionCall function);  
   private record FunctionCall(string name, string arguments);

4. **Implement GetCompletionAsync:** Now, we replace the NotImplementedException in OpenAiClient.cs with the full implementation.  
   * **Constructor:** Update the constructor to accept the HttpClient (which is provided by IHttpClientFactory) and IConfiguration (to get the model name).  
     private readonly HttpClient \_httpClient;  
     private readonly string \_modelName;

     public OpenAiClient(HttpClient httpClient, IConfiguration configuration)  
     {  
         \_httpClient \= httpClient;  
         \_modelName \= configuration\["OpenRouter:ModelName"\] ?? "openai/gpt-4o"; // Get model from config  
     }

   * **Method Implementation:**  
     public async Task\<LlmResponse\> GetCompletionAsync(List\<Message\> history, List\<string\> toolSchemas)  
     {  
         // 1\. Map our internal tool schemas to the API's expected DTO  
         var tools \= toolSchemas.Select(schemaJson \=\>   
         {  
             // We must deserialize the schema string into a generic object  
             var schemaObject \= System.Text.Json.JsonSerializer.Deserialize\<object\>(schemaJson);  
             // Extract name and description (this is a bit brittle, relies on schema format)  
             var doc \= System.Text.Json.JsonDocument.Parse(schemaJson);  
             var name \= doc.RootElement.GetProperty("properties").EnumerateObject().First().Name;   
             var description \= doc.RootElement.GetProperty("description").GetString() ?? "A tool";

             return new ToolDefinition("function", new FunctionDefinition(name, description, schemaObject));  
         }).ToList();

         // 2\. Build the final request payload  
         var request \= new ChatRequest(\_modelName, history, tools);

         // 3\. Send the request  
         var httpResponse \= await \_httpClient.PostAsJsonAsync("chat/completions", request);

         httpResponse.EnsureSuccessStatusCode(); // Throws if the API returns a non-200 status

         // 4\. Deserialize the response  
         var chatResponse \= await httpResponse.Content.ReadFromJsonAsync\<ChatResponse\>();

         var responseMessage \= chatResponse?.choices.FirstOrDefault()?.message;  
         if (responseMessage \== null)  
         {  
             throw new InvalidOperationException("Invalid response from LLM API.");  
         }

         // 5\. Map the API DTOs back to our internal LlmResponse record  
         var toolCalls \= new List\<ToolCall\>();  
         if (responseMessage.tool\_calls \!= null)  
         {  
             foreach (var apiToolCall in responseMessage.tool\_calls)  
             {  
                 toolCalls.Add(new ToolCall(  
                     apiToolCall.function.name,   
                     apiToolCall.function.arguments  
                 ));  
             }  
         }

         return new LlmResponse(responseMessage.content ?? "", toolCalls);  
     }

*(Note: The tool schema parsing above is simplified. A more robust implementation would define a common C\# object for tool schemas.)*

### **Priority 2: Implement Real-Time Chat (The "Voice")**

**Goal:** Connect your Blazor frontend to the agent's "think \-\> act" loop for real-time streaming of logs and messages. This is the key to creating an interactive user experience, as previewed in your Python guide \[cite: Python Agent System: Architecture & Tooling Guide (V7)\]. This turns the agent from an opaque backend process into an assistant you can "watch" as it works.

**Plan:**

1. **Add SignalR Package:** Add the Microsoft.AspNetCore.SignalR package to your DotnetAgents.AgentApi project.  
2. **Create AgentHub.cs:** Create a new folder DotnetAgents/DotnetAgents.Agent/Hubs and add the file AgentHub.cs. This hub will be the real-time "front door," replacing the REST API for starting tasks.  
   using Microsoft.AspNetCore.SignalR;  
   using System.Threading.Tasks;  
   using DotnetAgents.AgentApi.Services; // Or wherever AgentWorkerService is

   namespace DotnetAgents.AgentApi.Hubs  
   {  
       public class AgentHub : Hub  
       {  
           // We can inject services directly into Hub methods  
           public async Task StartTask(string goal, AgentDbContext db)  
           {  
               // Create the task in the DB, just like the POST endpoint did  
               var task \= new AgentTask  
               {  
                   Id \= Guid.NewGuid(),  
                   Goal \= goal,  
                   Status \= Status.Queued,  
                   CreatedByUserId \= Context.ConnectionId // Use ConnectionId as a user ID  
               };  
               db.AgentTasks.Add(task);  
               await db.SaveChangesAsync();

               // Confirm task creation to the \*calling\* client  
               await Clients.Caller.SendAsync("TaskAccepted", task.Id);  
           }

           // We can also add methods for interruption  
           public async Task CancelTask(Guid taskId)  
           {  
               // (Future Implementation: This would find the CancellationTokenSource for the task)  
               await Clients.Caller.SendAsync("TaskCancellationAcknowledged", taskId);  
           }  
       }  
   }

3. **Update Program.cs:**  
   * Register SignalR services: builder.Services.AddSignalR();  
   * Map the Hub endpoint: app.MapHub\<AgentHub\>("/agentHub");  
   * *(Optional)* You can now remove the POST /api/tasks endpoint, as the SignalR hub replaces its functionality.  
4. Refactor for Real-Time Logging (The "Decoupled" Way):  
   Instead of injecting IHubContext directly into the Agent (which would tightly couple the "brain" to the "voice"), we should use an abstraction.  
   * **a. Create New Interface in DotnetAgents.Core:**  
     // In DotnetAgents.Core/Interfaces/IAgentLogger.cs  
     public interface IAgentLogger  
     {  
         Task LogAsync(Guid taskId, string message);  
         Task TaskStartedAsync(Guid taskId);  
         Task TaskCompletedAsync(Guid taskId, string finalMessage);  
         Task TaskFailedAsync(Guid taskId, string error);  
     }

   * **b. Create SignalR Implementation in AgentApi:**  
     // In DotnetAgents.AgentApi/Services/SignalRAgentLogger.cs  
     public class SignalRAgentLogger : IAgentLogger  
     {  
         private readonly IHubContext\<AgentHub\> \_hubContext;

         public SignalRAgentLogger(IHubContext\<AgentHub\> hubContext)  
         {  
             \_hubContext \= hubContext;  
         }

         // Find all clients associated with a task (needs more logic)  
         // For now, send to all.  
         private IClientProxy GetClientsForTask(Guid taskId) \=\> \_hubContext.Clients.All;

         public Task LogAsync(Guid taskId, string message)  
             \=\> GetClientsForTask(taskId).SendAsync("ReceiveStatusUpdate", taskId, message);

         public Task TaskStartedAsync(Guid taskId)  
             \=\> GetClientsForTask(taskId).SendAsync("TaskStarted", taskId);

         public Task TaskCompletedAsync(Guid taskId, string finalMessage)  
             \=\> GetClientsForTask(taskId).SendAsync("TaskCompleted", taskId, finalMessage);

         public Task TaskFailedAsync(Guid taskId, string error)  
             \=\> GetClientsForTask(taskId).SendAsync("TaskFailed", taskId, error);  
     }

   * **c. Register the Logger in Program.cs:**  
     builder.Services.AddSingleton\<IAgentLogger, SignalRAgentLogger\>();

   * **d. Inject IAgentLogger into Agent.cs and AgentWorkerService.cs:**  
     * The AgentWorkerService will now call \_logger.TaskStartedAsync() and \_logger.TaskFailedAsync().  
     * The Agent class will inject IAgentLogger and call \_logger.LogAsync(task.Id, "Thinking...") and \_logger.LogAsync(task.Id, $"Executing tool: {toolCall.ToolName}") inside its Think \-\> Act loop.

### **Priority 3: Implement WebSearchTool (The "Ears")**

**Goal:** Replace the WebSearchTool's mock data \[cite: C\# Lone Agent Implementation Guide\] with a real API call. This makes the agent's tools truly functional and gives it access to external, real-time information for the first time.

**Plan:**

1. **Dependencies & Config:** The tool already correctly injects IHttpClientFactory and IConfiguration. We just need to ensure your appsettings.json has the GoogleSearch:ApiKey and GoogleSearch:CxId values filled in.  
2. **Create Response DTOs:** Just like with the OpenAiClient, we need to create records to deserialize the Google Search response.  
   // Private records inside WebSearchTool.cs  
   private record GoogleSearchResponse(List\<SearchResultItem\> items);  
   private record SearchResultItem(string title, string link, string snippet);

3. **Implement ExecuteAsync:** Replace the entire ExecuteAsync method with the following:  
   public async Task\<string\> ExecuteAsync(string jsonArguments)  
   {  
       var args \= JsonSerializer.Deserialize\<SearchArgs\>(jsonArguments);  
       if (args \== null || string.IsNullOrWhiteSpace(args.query))  
       {  
           return "Error: Invalid arguments for web\_search tool.";  
       }

       var apiKey \= \_config\["GoogleSearch:ApiKey"\];  
       var cxId \= \_config\["GoogleSearch:CxId"\];  
       if (string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(cxId))  
       {  
           return "Error: WebSearchTool is not configured. Missing ApiKey or CxId.";  
       }

       var client \= \_httpClientFactory.CreateClient("GoogleSearch");  
       var url \= $"\[https://www.googleapis.com/customsearch/v1?key=\](https://www.googleapis.com/customsearch/v1?key=){apiKey}\&cx={cxId}\&q={Uri.EscapeDataString(args.query)}";

       try  
       {  
           var response \= await client.GetFromJsonAsync\<GoogleSearchResponse\>(url);

           if (response \== null || response.items \== null || response.items.Count \== 0\)  
           {  
               return "No search results found.";  
           }

           // Format the real results into the string output  
           var formattedResults \= response.items.Select(item \=\>   
               $"Title: {item.title}\\nSnippet: {item.snippet}\\nSource: {item.link}"  
           );

           return "Search results:\\n" \+ string.Join("\\n---\\n", formattedResults);  
       }  
       catch (Exception ex)  
       {  
           return $"Error during web search: {ex.Message}";  
       }  
   }

### **Priority 4: Advanced Architectural Expansion**

This section outlines new, long-term features that are not in the original guide but are now possible because of the strong foundation you have built.

#### **Feature 1: Multi-Agent Orchestration (Agent Swarms)**

**Goal:** Evolve from a single worker (IIntelAgent) to an agent that can orchestrate *other* agents. This is the core concept of "agent swarms" and is a direct parallel to the "Orchestrator Agent" in your Python guide \[cite: Python Agent System: Architecture & Tooling Guide (V7)\].

**Plan:**

1. **Create a "Manager" Agent:** Create a new ManagerAgent class that also implements IIntelAgent.  
2. **Create a "Delegate" Tool:** Create a new tool called DelegateTaskTool that implements ITool.  
   * This tool's ExecuteAsync method will not run code, but will instead **create a new AgentTask in the database**.  
   * ExecuteAsync(goal: "write code for button") \-\> INSERT INTO "AgentTasks" (Goal="write code...", Status="Queued").  
3. **Update IntelAgent Project:**  
   * Create a "specialist" agent, e.g., DeveloperAgent, that implements IIntelAgent and is given the FileSystemTool and ShellCommandTool.  
   * Create the ManagerAgent, which is *only* given the DelegateTaskTool and WebSearchTool.  
4. **Dynamic Agent Profiles:**  
   * In appsettings.json, define "profiles":  
     "AgentProfiles": {  
       "Manager": {  
         "SystemPrompt": "You are a manager. Your job is to break down complex goals and delegate them to specialists.",  
         "Tools": \["DelegateTaskTool", "web\_search"\]  
       },  
       "Developer": {  
         "SystemPrompt": "You are a developer. Your job is to write and test code.",  
         "Tools": \["file\_system", "shell\_command"\]  
       }  
     }

   * Add a Profile string to your AgentTask model.  
   * The /api/tasks endpoint (or AgentHub) will now take a profile parameter (defaulting to "Manager").  
   * The AgentWorkerService will read the task's Profile, inject the IConfiguration, and pass both to the Agent class.  
   * The Agent's constructor will then read this profile to select its system prompt and tell the IToolDispatcher which tools to activate for this specific task.

#### **Feature 2: Full RAG & Vector Memory**

**Goal:** Give your agent long-term, semantic memory by connecting it to a real vector database.

**Plan:**

1. **Add Vector DB to AppHost:** In AppHost.cs, add a container for a vector database (e.g., Qdrant, Weaviate).  
   var qdrant \= builder.AddContainer("qdrant", "qdrant/qdrant:latest")  
                       .WithHttpEndpoint(port: 6333, targetPort: 6333);

2. **Inject into AgentApi:** Add .WithReference(qdrant) to your apiService definition.  
3. **Create RagTool:**  
   * Create a new RagTool.cs that implements ITool.  
   * It will have two functions: StoreMemory(text) and RecallMemories(query).  
   * Inject an HttpClient (configured for Qdrant) and an IOpenAiClient (to generate embeddings).  
   * StoreMemory: Takes text, calls the IOpenAiClient embedding endpoint, and POSTs the resulting vector to Qdrant.  
   * RecallMemories: Takes a query, gets its vector, and queries Qdrant for the most similar results, which are then formatted as a string.  
4. **Register the Tool:** Add builder.Services.AddSingleton\<ITool, RagTool\>(); to Program.cs. Your agent can now use rag.StoreMemory and rag.RecallMemories just like any other tool.

#### **Feature 3: Human-in-the-Loop (HITL) & Interactive Tools**

**Goal:** Create a tool that can pause the agent's execution and ask the human user for clarification or approval via the SignalR chat.

**Plan:**

1. **Create HumanInputTool:**  
   * This tool's constructor will inject the IAgentLogger (from Priority 2\) and a new singleton service, IHumanInputService.  
   * ExecuteAsync(string prompt) will call \_agentLogger.LogAsync(taskId, $"PAUSED: {prompt}") to show the question in the UI.  
   * It will then call await \_humanInputService.WaitForInputAsync(taskId).  
2. **Create IHumanInputService:**  
   * This service will hold a ConcurrentDictionary\<Guid, TaskCompletionSource\<string\>\>.  
   * WaitForInputAsync(taskId): Creates a new TaskCompletionSource, stores it in the dictionary, and returns its Task. The HumanInputTool will now await this task, effectively pausing the *entire agent loop*.  
   * ReceiveInputAsync(taskId, string message): This method is called by the AgentHub. It finds the TaskCompletionSource in the dictionary and calls TrySetResult(message). This completes the task, un-pausing the agent, which now has the human's answer.  
3. **Update AgentHub:**  
   * Inject the IHumanInputService.  
   * Add a new method: public Task SendInputToAgent(Guid taskId, string message) \=\> \_inputService.ReceiveInputAsync(taskId, message);.  
   * The Blazor frontend can now call this method when the user replies to the agent's question.

#### **Feature 4: Event-Driven Worker (Message Queue)**

**Goal:** Evolve the AgentWorkerService from a "pull-based" (polling) model to a "push-based" (event-driven) model for elite scalability and reduced database load.

**Plan:**

1. **Add RabbitMQ to AppHost:** In AppHost.cs, add the RabbitMQ container:  
   var rabbitMq \= builder.AddRabbitMQ("rabbitmq");

2. **Update AgentApi:**  
   * Inject the RabbitMQ connection (.WithReference(rabbitMq)).  
   * **In AgentHub (or the API endpoint):** Instead of just saving to the DB, also *publish a message* to a RabbitMQ queue (e.g., "tasks.new") containing the AgentTask.Id.  
   * **Refactor AgentWorkerService:**  
     * Remove the entire while loop and all polling logic.  
     * In ExecuteAsync, register a *consumer* on the "tasks.new" queue.  
     * The event handler for the consumer (consumer.Received) will become the new entry point for the worker logic (create scope, get task from DB by ID, execute agent).  
   * This completely eliminates database polling. The worker now sits idle until a new task is *pushed* to it by the message bus, which is a far more efficient and scalable pattern.