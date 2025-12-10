# **Advanced Technical Concepts: MAGE & Living Graph**

Purpose: Internal "Study Guide" for the Principal Investigator.  
Context: These concepts underpin the "Curator Agent" and "Living Graph" innovations in the NSF proposal.

## **1\. MAGE (Memgraph Advanced Graph Analytics)**

*What it is:* A library of graph algorithms that run *inside* the database, making them incredibly fast.

### **Key Algorithm A: PageRank (Centrality)**

* **The Concept:** Originally used by Google to rank websites. It measures "importance" by counting connections.  
* **In Our System:** We use it to measure the "truthfulness" of a memory.  
  * *High PageRank Node:* A fact that is connected to many other facts (e.g., "User is a Developer" is linked to "Uses Python," "Knows .NET," "Has GitHub"). This is likely true.  
  * *Low PageRank Node:* An orphan fact with no connections (e.g., "User likes purple elephants"). This is likely a hallucination or irrelevant noise.  
* **The "Curator" Logic:** "Delete any memory node with a PageRank score \< 0.05 that is older than 24 hours."

### **Key Algorithm B: Louvain (Community Detection)**

* **The Concept:** Algorithms that find "cliques" or clusters in a network.  
* **In Our System:** We use it to organize memory into "Contexts."  
  * *Example:* The algorithm might find a cluster of nodes related to "Project Alpha," "Budget," "Deadline," and "Manager." It automatically labels this cluster "Community 1."  
* **The Benefit:** When the user asks about "Project Alpha," we don't just search keywords; we retrieve the entire "Community 1" cluster, providing rich context the user didn't explicitly ask for.

## **2\. The "Living Knowledge Graph" (Hot/Cold Architecture)**

*What it is:* A strategy to make a static database feel "alive" and capable of learning.

### **The Problem with Standard GraphRAG**

Standard GraphRAG is **Read-Only**. Building the graph takes hours (indexing). You can't just "add one fact" easily; you usually have to rebuild the whole index. This is bad for a conversational agent that learns in real-time.

### **Our Solution: The Hot/Cold Layering**

We propose a **Lambda Architecture** for graphs:

#### **Layer 1: The "Cold" Store (The Encyclopedia)**

* **Technology:** Microsoft GraphRAG (Parquet files) or Neo4j (Static Database).  
* **Content:** The core domain knowledge (manuals, textbooks, compliance rules).  
* **Update Frequency:** Weekly or Monthly (Batch Process).  
* **Trust Level:** 100% Verified.

#### **Layer 2: The "Hot" Store (The Notepad)**

* **Technology:** Memgraph (In-Memory Graph) or Redis.  
* **Content:** New facts learned *right now* during the conversation.  
* **Update Frequency:** Real-time (Milliseconds).  
* **Trust Level:** Provisional (Needs verification).

#### **The "Fusion" Process (The Innovation)**

The **Curator Agent** runs a nightly job:

1. It looks at the "Hot Store."  
2. It runs **Grounding** (Verification) on the new facts.  
3. If a fact is verified, it "promotes" it to the "Cold Store" (updating the permanent graph).  
4. If a fact is rejected, it is deleted.

*Why NSF loves this:* It solves the "Stale Data" problem in AI without risking "Data Poisoning."