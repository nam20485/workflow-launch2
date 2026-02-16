from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from agno.agent import Agent
from agno.models.openai import OpenAIChat

# ==========================================
# PHASE 2: THE BRAIN (Agno Models)
# Defining the structure of what we are building
# ==========================================

class ActionStep(BaseModel):
    """A single atomic action in the workflow"""
    step_id: int
    action_type: str = Field(..., description="click, type, navigate, wait")
    
    # The Semantic Selector is Key. It's not just "#btn", it's description based.
    semantic_target: str = Field(..., description="Description of element, e.g., 'The Submit Application button'")
    selector_xpath: Optional[str] = Field(None, description="Recorded XPath, used as fallback")
    
    value: Optional[str] = Field(None, description="Value to type, or variable placeholder like {{email}}")
    reasoning: str = Field(..., description="Why is this step happening?")

class WorkflowMode(BaseModel):
    """The compiled executable mode"""
    name: str = Field(..., description="Name of the workflow, e.g., 'LinkedIn Easy Apply'")
    description: str
    detected_variables: List[str] = Field(..., description="Variables requiring user input, e.g., ['username', 'cv_path']")
    steps: List[ActionStep]

# ==========================================
# THE COMPILER AGENT
# ==========================================

compiler_instructions = """
You are the Architect. You receive raw browser event logs.
Your goal is to abstract these logs into a robust 'WorkflowMode'.

RULES:
1. Ignore noise. If a user clicks a field 3 times, it's just one 'focus' action.
2. Identify PII. If user types 'john@gmail.com', replace it with '{{user_email}}' and add 'user_email' to detected_variables.
3. Generate 'semantic_target' descriptions. Do not just rely on IDs. Describe the button's purpose (e.g., 'The primary call to action button').
"""

compiler_agent = Agent(
    model=OpenAIChat(id="gpt-4-turbo"),
    description="Converts raw CDP logs into Agno Workflow Modes.",
    instructions=compiler_instructions,
    response_model=WorkflowMode,
)

# Example Usage Mock
raw_log_sample = [
    {"type": "click", "tag": "BUTTON", "text": "Easy Apply", "path": "/html/body/div[3]/button"},
    {"type": "input", "tag": "INPUT", "value": "MyName", "id": "name-field"},
]

def compile_session(logs: List[Dict]):
    print("🧠 Agno is analyzing session logs...")
    # Mocking the AI response for demonstration
    mode = WorkflowMode(
        name="Job Application Flow",
        description="Applies to a job using Easy Apply",
        detected_variables=["candidate_name"],
        steps=[
            ActionStep(step_id=1, action_type="click", semantic_target="Easy Apply Button", selector_xpath="/html/body/div[3]/button", reasoning="Start application"),
            ActionStep(step_id=2, action_type="type", semantic_target="Name Input Field", value="{{candidate_name}}", reasoning="Fill personal info")
        ]
    )
    return mode.model_dump_json(indent=2)

if __name__ == "__main__":
    print(compile_session(raw_log_sample))
