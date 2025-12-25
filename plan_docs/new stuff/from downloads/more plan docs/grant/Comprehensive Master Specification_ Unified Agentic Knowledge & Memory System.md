# **Comprehensive Master Specification: Unified Agentic Knowlege & Memory System**

Version: 3.0 (The Union of Theory, Architecture, and Implementation)  
Date: November 28, 2025  
Tech Stack: .NET Aspire (Orchestrator) \+ Python (AI Microservice) \+ Memgraph (Unified Data Store)

## **Part 1: Theoretical Foundation (The "Why")**

### **1.1 The Limitations of Current AI**

Current Large Language Models (LLMs) suffer from three critical failure modes that prevent them from acting as reliable autonomous agents:

1. **Amnesia:** They are stateless. RAG helps with *facts*, but it doesn't remember *user context* (preferences, past decisions, state).  
2. **Hallucination:** They generate plausible but false information when their training data is ambiguous.  
3. **Static Knowledge:** Standard RAG indexes are read-only. An agent cannot "learn" a new fact during a conversation and use it 5 minutes later without a full index rebuild.

### **1.2 The "Two Brains" Solution**

To solve this, we architect a system with two distinct cognitive faculties, mimicking human cognition:

#### **Brain A: The Semantic Core (GraphRAG)**

* **Role:** The "Long-Term Semantic Memory."  
* **Function:** Deep, structured domain expertise. It answers "What is known about this topic in the world?"  
* **Mechanism:** A Knowledge Graph where nodes are entities (People, Projects, Concepts) and edges are relationships.  
* **Query Capabilities:**  
  * *Global Search:* Summarizes broad themes (e.g., "What are the compliance risks in our dataset?").  
  * *Local Search:* Traverses relationships (e.g., "Who worked on Project Alpha and what is their clearance level?").

#### **Brain B: The Episodic Memory (Mem0)**

* **Role:** The "Short-Term & Episodic Memory."  
* **Function:** Personalized, evolving context. It answers "What do I know about *this user*?"  
* **Mechanism:** A Hybrid Store (Vector \+ Graph) that records interactions, preferences, and user state.  
* **Dynamic Nature:** Unlike the Semantic Core, this brain updates in *real-time* after every interaction.

## **Part 2: System Architecture (The "What")**

We utilize a **Polyglot Microservices Architecture** orchestrated by **.NET Aspire**. This allows us to use the enterprise-standard .NET ecosystem for the main application while leveraging the Python-native AI libraries for the core intelligence.

### **2.1 The Component Diagram**

graph TD  
    User\[User / Client App\] \--\> EdgeRouter\[Edge Router (Intent Classifier)\]  
    EdgeRouter \--\> Orchestrator\[ASP.NET Core "MCP Server"\]  
      
    subgraph "The .NET Aspire Host"  
        Orchestrator  
          
        subgraph "AI Microservices"  
            Orchestrator \<--\>|HTTP/JSON| PythonService\[Python Knowledge Service\]  
            Orchestrator \<--\>|HTTP/JSON| Mem0Client\[C\# Memory Client\]  
        end  
          
        subgraph "Data Persistence"  
            PythonService \--\> Memgraph\[Memgraph DB (Knowledge Graph)\]  
            Mem0Client \--\> Memgraph\[Memgraph DB (User Memory)\]  
        end  
    end  
      
    subgraph "Background Workers"  
        Curator\[Curator Agent (Python)\] \-.-\>|Async MAGE Algos| Memgraph  
    end

### **2.2 Component Definitions**

#### **1\. The MCP Server (ASP.NET Core API)**

* **Role:** The central brain and interface. It implements the **Model Context Protocol (MCP)** to standardize communication with the AI Agent.  
* **Responsibilities:**  
  * **Routing:** Decides which tools to call based on the Edge Router's classification.  
  * **Orchestration:** Executes parallel calls to Memory and Knowledge services.  
  * **Verification:** Runs the "Grounding Check" before returning the final answer.

#### **2\. The Knowledge Service (Python/FastAPI)**

* **Role:** A lightweight wrapper around the Microsoft GraphRAG library.  
* **Why Python?** GraphRAG is Python-native. Porting it to C\# is infeasible.  
* **Deployment:** Runs as a Docker container managed by .NET Aspire.

#### **3\. The Memory Service (Mem0 Integration)**

* **Role:** Manages user-specific memory.  
* **Implementation:** A C\# HttpClient that communicates with the Mem0 platform (or a self-hosted Mem0 instance backed by Memgraph).

#### **4\. The Curator Agent (Background Worker)**

* **Role:** The "Immune System" for data integrity.  
* **Mechanism:** Runs **MAGE (Memgraph Advanced Graph Analytics)** algorithms like *PageRank* and *Community Detection* to identify and prune "hallucinated" memories (nodes with low centrality).

## **Part 3: Detailed Development Plan (The "How")**

### **Phase 1: The "Lite" Prototype (Foundation)**

**Objective:** Prove the core "Two Brains" logic using a simple local setup.

#### **Step 1: Set up the Data Layer (Memgraph)**

1. Install Docker Desktop.  
2. Run Memgraph with MAGE:  
   docker run \-p 7687:7687 \-p 7444:7444 \--name memgraph-mage memgraph/memgraph-mage

#### **Step 2: Build the Python Knowledge Service**

1. Create a folder GraphRagService.  
2. Create requirements.txt: fastapi, uvicorn, graphrag, neo4j (or memgraph driver).  
3. Create main.py:  
   from fastapi import FastAPI, HTTPException  
   from pydantic import BaseModel  
   \# Import your GraphRAG logic here

   app \= FastAPI()

   class QueryRequest(BaseModel):  
       query: str  
       method: str \= "global"

   @app.post("/query")  
   async def query\_knowledge(req: QueryRequest):  
       \# Placeholder for actual GraphRAG call  
       return {"result": f"Executed {req.method} search for '{req.query}'"}

4. Create Dockerfile:  
   FROM python:3.11-slim  
   WORKDIR /app  
   COPY . .  
   RUN pip install \-r requirements.txt  
   CMD \["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"\]

#### **Step 3: Build the .NET Orchestrator (MCP Server)**

1. Create a new **.NET Aspire Starter App**.  
2. In AppHost/Program.cs, add the Python service:  
   var pythonService \= builder.AddDockerfile("graphrag", "../GraphRagService")  
                              .WithHttpEndpoint(port: 8001, targetPort: 8001);

   var apiService \= builder.AddProject\<Projects.MyAgent\_ApiService\>("apiservice")  
                           .WithReference(pythonService);

3. In ApiService, create OrchestrationService.cs to call the Python endpoint.

### **Phase 2: The "Smart" Features (De-Risking)**

**Objective:** Implement the advanced features that make this "Research," not just "Engineering."

#### **Step 4: The Edge Router**

* **Goal:** Sub-300ms intent classification.  
* **Action:** In ApiService, implement a simple logic layer (can be Regex initially, then SLM) to classify queries:  
  * *If query contains "I", "my", "we" \-\> Call Memory.*  
  * *If query contains technical jargon \-\> Call Knowledge.*  
  * *Else \-\> Call Both.*

#### **Step 5: The Curator (MAGE Integration)**

* **Goal:** Data hygiene.  
* **Action:** Create a Python script curator.py that connects to Memgraph and runs:  
  \# Pseudo-code for MAGE PageRank  
  memgraph.execute\_query("CALL pagerank.get() YIELD node, rank SET node.rank \= rank")  
  memgraph.execute\_query("MATCH (n) WHERE n.rank \< 0.01 DELETE n")

### **Phase 3: Future Innovation (The "Secret Sauce")**

**Objective:** The visionary features for the NSF Proposal.

#### **1\. The Living Knowledge Graph**

* **Concept:** A "Hot/Cold" architecture where new facts are written to a temporary "Hot" graph in Memgraph.  
* **Process:** The Curator Agent validates these "Hot" facts against the "Cold" (verified) graph. If verified, they are merged.

#### **2\. Explainable AI (XAI)**

* **Concept:** A "Meta-Cognitive" UI feature.  
* **Implementation:** Add a "Why?" button to the frontend. When clicked, it sends the trace ID to the API, which returns the *reasoning path* (e.g., "I answered X because I found Fact Y in the Knowledge Graph and Preference Z in your Memory").

## **Part 4: Final Deliverables List**

By the end of this project, you will have:

1. **A .NET Aspire Application** (The Enterprise Shell).  
2. **A Python Microservice** (The AI Brain).  
3. **A Memgraph Database** (The Unified Memory Store).  
4. **The "Curator" Algorithm** (The Research Core).  
5. **The "Edge Router"** (The Performance Core).