# **Latency Budget & Optimization Plan**

Project: Advanced Agentic Memory System (NSF SBIR Phase I)  
Date: November 27, 2025

## **1\. Executive Summary**

This document analyzes the end-to-end latency of the proposed "Dynamic Hierarchical Memory" architecture. Our analysis identifies a critical risk in the sequential execution of memory and knowledge retrieval tools. We propose a parallelized "Optimistic Execution" strategy to reduce total response time from **5.8 seconds** (Baseline) to **2.4 seconds** (Optimized), ensuring a viable user experience for real-time agentic interactions.

## **2\. Baseline Latency (Sequential Execution)**

*Scenario: An agent receives a user query, calls tools one by one, and then synthesizes a response.*

| Step | Component | Operation | Est. Latency (ms) | Notes |
| :---- | :---- | :---- | :---- | :---- |
| 1 | Client | User sends request (Network) | 200 ms | Standard 4G/Wifi latency |
| 2 | **Agent Core** | **Reasoning (LLM)** to decide tool calls | **1,200 ms** | Cost of "Thinking" before acting |
| 3 | MCP Server | Dispatch search\_user\_memory (Mem0) | 50 ms | Overhead |
| 4 | **Mem0** | **Vector Search \+ Reranking** | **600 ms** | Includes embedding generation |
| 5 | Agent Core | Receive Memory \-\> Reasoning \-\> Call Knowledge | 800 ms | Context switch penalty |
| 6 | **GraphRAG** | **Knowledge Retrieval (Global/Local)** | **1,500 ms** | Complex graph traversal |
| 7 | Agent Core | Synthesis & Verification Check | 1,000 ms | Final context assembly |
| 8 | Client | Stream First Token (Network) | 450 ms | Time to First Token (TTFT) |
| **TOTAL** |  | **End-to-End Response Time** | **\~5,800 ms** | **Critical UX Risk** |

*Analysis: Nearly 6 seconds of "thinking" time is unacceptable for conversational interfaces. The bottleneck is the serial nature of Steps 2, 5, and 7\.*

## **3\. Optimized Latency (Parallel & Optimistic)**

*Scenario: The MCP Orchestrator handles parallel retrieval, and a smaller "Router" model bypasses the main agent for initial dispatch.*

| Step | Component | Operation | Est. Latency (ms) | Optimization Strategy |
| :---- | :---- | :---- | :---- | :---- |
| 1 | Client | User sends request | 200 ms | \- |
| 2 | **Edge Router** | **Intent Classification (SLM)** | **300 ms** | Use a specialized 7B model (local) instead of GPT-4 for routing. |
| 3 | **MCP Server** | **Parallel Execution** | **1,500 ms** | **Crucial Fix:** Launch search\_user\_memory AND query\_knowledge\_base simultaneously. Latency is capped by the slowest task (GraphRAG), not the sum. |
|  | *Async Task A* | *Mem0 Retrieval* | *(600 ms)* | *Hides behind GraphRAG* |
|  | *Async Task B* | *GraphRAG Retrieval* | *(1,500 ms)* | *The critical path* |
| 4 | Agent Core | **Verification & Synthesis** | **400 ms** | **Speculative Decoding:** Begin generating the answer structure *while* retrieval finishes. |
| 5 | Client | Stream First Token | 200 ms | Optimized WebSocket stream |
| **TOTAL** |  | **End-to-End Response Time** | **\~2,600 ms** | **Viable (\< 3s Goal)** |

## **4\. Technical Implementation Strategy**

### **A. The "Edge Router" Pattern**

Instead of sending the raw query to the main Agent (GPT-4o) to ask "What tools should I use?", we insert a lightweight, fine-tuned Small Language Model (SLM) at the API Gateway.

* **Model:** Llama-3-8B-Instruct (Quantized).  
* **Function:** Classifies query into "Memory Needed," "Knowledge Needed," or "Both."  
* **Benefit:** Reduces Step 2 latency by \~75%.

### **B. Asynchronous Orchestration (The MCP Layer)**

The MCP Server will not wait for the Agent to request tools sequentially.

* **Logic:** If the Edge Router flags "Complex Query," the MCP Server *immediately* fires both search\_user\_memory and query\_knowledge\_base concurrently using Python's asyncio.gather().  
* **Benefit:** overlapping IO-bound operations saves \~1.4 seconds per turn.

### **C. Optimistic UI Updates**

To manage the user's *perception* of latency:

* **Client-Side:** Display "Searching Memory..." and "Consulting Knowledge Graph..." status indicators immediately upon request (triggered by the Edge Router classification).  
* **Benefit:** Reduces the "frozen screen" anxiety even if the backend takes 2.6 seconds.

## **5\. De-Risking Metrics for Phase I**

*Success Criteria for the NSF Grant:*

1. **Metric:** Average Time to First Token (TTFT).  
2. **Target:** \< 3,000 ms for 95% of queries (P95).  
3. **Measurement:** Automated load testing using locust scripts simulating concurrent agent sessions.