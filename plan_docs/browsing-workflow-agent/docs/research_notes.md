# Research & Analysis: Agentic Workflow Techniques

## 1. Competitive Landscape & Techniques

### A. Large Action Models (LAMs)
* **Concept:** Similar to how LLMs predict the next word, LAMs predict the next interface action (click, scroll, type) based on a UI screenshot or DOM dump.
* **Key Players:** Adept (ACT-1), Rabbit R1, MultiOn.
* **Relevance:** We are building a "micro-LAM" using "In-Context Learning" by feeding past actions into Agno.

### B. DOM-Based Heuristics (RPA 2.0)
* **Concept:** Using strict selectors (XPath/CSS) but adding AI to "heal" them when they break.
* **Relevance:** We need semantic DOM (e.g., "The button labeled 'Next'") rather than brittle XPaths.

## 2. Implementation Complexity Analysis

### Complexity Area 1: The "Watcher" (High)
* **Problem:** Browsers are noisy. 
* **Solution:** We filter for "Commit" events: Clicks, 'Enter' keys, Form Submissions. We ignore pure mouse movement.
* **Tech:** Chrome DevTools Protocol (CDP) is the only reliable way.

### Complexity Area 2: Context Window Limits (Medium)
* **Problem:** A 10-minute session generates massive HTML logs.
* **Solution:** **Distillation.** Record the "Accessibility Tree" instead of raw HTML.

### Complexity Area 3: Auth & Anti-Bot (High)
* **Problem:** LinkedIn/UserInterviews have strict anti-bot measures.
* **Solution:**
    * **Learning:** Local Chrome (safe).
    * **Execution:** **NanoBrowser** (Stealth) is critical here.
