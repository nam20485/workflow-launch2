# Agent Creation and Refinement Process

This document outlines the process for creating a new Claude agent using the provided template. The process is designed to be iterative, with a focus on feedback and refinement.

## 0. Documentation

Review and familiarize yourself with the following official Claude Code sub-agent documentation before starting the agent creation process:
[Sub-Agents Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)

If you need any clarification or more information about CClaude Code, please refer to the official documentation:
[Claude Code Documentation](https://docs.claude.com/en/docs/claude-code/)

## 1. Initial Agent Creation

1.  **Copy the template:** Make a copy of the `template-agent.md` file in the `.claude/agents/` directory and rename it to `[new-agent-name].md`.
2.  **Fill out the template:**
    *   **`name`**: A unique, lowercase, hyphenated name for the agent (e.g., `code-reviewer`).
    *   **`description`**: A brief, one-sentence description of the agent's primary function. This is used by the orchestrator to delegate tasks.
    *   **`version`**: The version of the agent, following semantic versioning (e.g., `1.0.0`).
    *   **`tools`**: A comma-separated list of tools the agent is allowed to use. If left blank, the agent will inherit all available tools.
    *   **`model`**: The model the agent should use (e.g., `sonnet`, `opus`, `haiku`). Use `inherit` to use the same model as the main conversation.
    *   **`[AGENT_ROLE]`**: A clear and concise title for the agent's role (e.g., `Senior Code Reviewer`).
    *   **`Persona`**: A description of the agent's personality and tone.
    *   **`Responsibilities`**: A bulleted list of the agent's key responsibilities.
    *   **`Workflow`**: A numbered list describing the step-by-step process the agent should follow to complete a task. Include a `Finally` step to summarize the work done.
    *   **`Rules`**: A bulleted list of constraints and rules the agent must follow.
    *   **`Best Practices`**: A bulleted list of guidelines and principles the agent should adhere to. Be specific and provide examples.

## 2. Initial Review and Refinement

Once the initial agent definition is complete, the following iterative feedback and refinement process should be followed at least once:

1.  **Ask for feedback:** Use the `ask_gemini` tool to request a review of the newly created agent file. The prompt should be something like: `Please review the following agent definition and provide feedback on its clarity, completeness, and effectiveness. Suggest improvements to the role, responsibilities, workflow, and best practices.`
2.  **Apply feedback:** Use a separate `ask_gemini` instance with `changeMode=True` to apply the suggested feedback to the agent file.

## 3. Self-Correction and Further Refinement

After the initial review cycle, perform a self-correction review of the agent definition. If you identify any areas for improvement, you can repeat the feedback and refinement cycle:

1.  **Generate your own feedback:** Based on your review, formulate specific feedback for improvement.
2.  **Ask for another review:** Use the `ask_gemini` tool again, but this time, provide your own feedback as part of the prompt.
3.  **Apply feedback:** Use another `ask_gemini` instance with `changeMode=True` to apply the new feedback.

## 4. Testing

Before finalizing the agent, it's important to test it to ensure it behaves as expected. This can be done by:

1.  **Invoking the agent directly:** Use a prompt to explicitly invoke the agent and ask it to perform a task that falls within its responsibilities.
2.  **Testing the workflow:** Verify that the agent follows the defined workflow and produces the expected output.
3.  **Testing the rules:** Ensure that the agent adheres to the defined rules and constraints.

## 5. Sharing and Versioning

Once the agent has been tested and refined, it can be shared with other users. 

*   **Versioning:** Increment the `version` number in the agent's frontmatter whenever you make changes to the agent. This will help you keep track of changes and ensure that other users are aware of the updates.
*   **Sharing:** Project-level agents (located in the `.claude/agents/` directory) are automatically shared with other users who have access to the project. User-level agents (located in the `~/.claude/agents/` directory) are are available tob

## 6. Finalization

Once you are satisfied with the agent definition, it is ready to be used. The iterative process of feedback and refinement can be repeated as many times as necessary to create a high-quality, effective agent. Once 
