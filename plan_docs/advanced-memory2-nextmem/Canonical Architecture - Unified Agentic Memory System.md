# **Canonical Architecture: Unified Agentic Knowledge & Memory System**

Version: 1.0 (Definitive)  
Date: November 27, 2025  
Tech Stack: .NET Aspire (Orchestrator) \+ Python (AI Services) \+ Neo4j/Qdrant (Data)

## **1\. Executive Summary**

This document defines the architecture for a "2nd Generation" AI Agentic System. Unlike stateless RAG systems, this architecture provides **Long-Horizon Memory** and **Deep Domain Knowledge** by integrating two distinct cognitive engines under a unified orchestration layer.

The system solves three critical failure modes of current AI:

1. **Amnesia:** Solved via **Mem0** (User/Episodic Memory).  
2. **Hallucination:** Solved via **GraphRAG** (Structured Knowledge) and a **Verification Layer**.  
3. **Latency:** Solved via **Optimistic Execution** and **Edge Routing**.

## **2\. Logical Architecture: The "Two Brains"**

The system is conceptualized as two distinct cognitive processes:

### **Brain A: The Semantic Core (GraphRAG)**

* **Function:** Deep, structured domain expertise. Static and fact-based.  
* **Analogy:** The "Textbook" or "Standard Operating Procedure."  
* **Data Structure:** Knowledge Graph (Neo4j). Nodes \= Entities, Edges \= Relationships.  
* **Query Mode:**  
  * *Global Search:* "What are the themes in these documents?"  
  * *Local Search:* "How does Entity A relate to Entity B?"

### **Brain B: The Episodic Memory (Mem0)**

* **Function:** Personalized, evolving context. Dynamic and user-specific.  
* **Analogy:** The "Journal" or "Patient History."  
* **Data Structure:** Hybrid (Vector \+ Graph). Stores interactions, preferences, and state.  
* **Query Mode:** "What did we discuss last week regarding X?"

## **3\. Implementation Architecture: The Polyglot Stack**

Because the best AI libraries are in Python but the target enterprise environment is .NET, we utilize a **Polyglot Microservices Architecture** orchestrated by **.NET Aspire**.

### **Component Diagram**

\[Client/Agent\] \--\> \[Edge Router (SLM)\]  
|  
v  
\[.NET Aspire AppHost\]  
|  
\+-----------------+-----------------+  
| | |  
\[API Service (C\#)\] \<--\> \[GraphRAG Service (Python)\]  
| |  
| \+--\> \[Neo4j / Parquet\]  
|  
\+--\> \[Mem0 Service (C\# Client)\]  
|  
\+--\> \[Mem0 Platform / Qdrant\]

### **3.1. The Orchestrator (.NET Aspire)**

* **Role:** The central nervous system. Manages service discovery, environment variables, and container lifecycles.  
* **Responsibility:** Spins up the C\# API and the Python GraphRAG container side-by-side.

### **3.2. The API Gateway (ASP.NET Core)**

* **Role:** The primary interface for the AI Agent.  
* **Key Component:** OrchestrationService.cs  
  * Receives the high-level tool call (get\_comprehensive\_answer).  
  * Executes the **Parallel Retrieval** logic (calling GraphRAG and Mem0 simultaneously).  
  * Performs the **Verification/Grounding** check on the result.

### **3.3. The Knowledge Service (Python/FastAPI)**

* **Role:** Wraps the Python-native Microsoft GraphRAG library.  
* **Why Python?** GraphRAG has no .NET equivalent.  
* **Deployment:** Docker Container.  
* **Endpoint:** POST /query (Accepts JSON, runs graphrag.query, returns JSON).

### **3.4. The De-Risking Components**

* **Edge Router:** A lightweight model (Quantized Llama-3) sitting before the main API to classify intent ("Memory" vs "Knowledge" vs "Both") in \<300ms.  
* **Curator Agent:** An asynchronous background worker that monitors the Knowledge Graph for "poisoning" (hallucinations) using entropy metrics.

## **4\. Data Flow: The "Optimistic Execution" Loop**

To mitigate latency, the system follows this specific execution path:

1. **Request:** User sends query: "Based on my last project, how does the new compliance rule affect me?"  
2. **Routing:** Edge Router classifies as Hybrid (Needs Memory \+ Knowledge).  
3. **Dispatch:** C\# Orchestrator fires two parallel requests:  
   * Task A: Call Mem0 API for "last project."  
   * Task B: Call Python Service for "compliance rule" (GraphRAG).  
4. **Synthesis:** Orchestrator receives both payloads.  
   * *Context:* "User's last project was Project Alpha (Financial)."  
   * *Knowledge:* "New rule restricts Financial API usage."  
5. **Generation:** LLM synthesizes answer: "Since Project Alpha is financial, the new rule restricts you..."  
6. **Verification:** Grounding Provider checks the citation against the source text.  
7. **Response:** Verified answer streamed to user.

## **5\. Development Roadmap (Phase I)**

### **Milestone 1: The "Lite" Prototype**

* **Goal:** Prove the algorithm without the full cloud stack.  
* **Stack:** Python-only (FastAPI).  
* **Data:** File-based GraphRAG (Parquet), Local Qdrant for Mem0.  
* **Deliverable:** A script that successfully answers a hybrid question.

### **Milestone 2: The .NET Integration**

* **Goal:** Bring the prototype into the enterprise stack.  
* **Stack:** .NET Aspire \+ Docker.  
* **Action:** Containerize the Python script from Milestone 1; build the C\# HttpClient to talk to it.

### **Milestone 3: The "Curator"**

* **Goal:** Data integrity.  
* **Action:** Implement the entropy-check algorithm to flag "weird" new memories.