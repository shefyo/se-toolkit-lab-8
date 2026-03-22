"""Intent router for natural language queries using LLM."""

from typing import Any
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.lms_client import LMSClient
from services.llm_client import LLMClient


# Tool definitions for the LLM
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "get_health",
            "description": "Check if the LMS backend is healthy and get the item count",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_labs",
            "description": "List all available labs with their names and descriptions",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_scores",
            "description": "Get pass rates for tasks within a specific lab",
            "parameters": {
                "type": "object",
                "properties": {
                    "lab": {
                        "type": "string",
                        "description": "The lab identifier (e.g., 'lab-04', 'lab-01')",
                    },
                },
                "required": ["lab"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_learners",
            "description": "Get list of all enrolled learners",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_timeline",
            "description": "Get submission timeline for a specific lab showing submissions per day",
            "parameters": {
                "type": "object",
                "properties": {
                    "lab": {
                        "type": "string",
                        "description": "The lab identifier (e.g., 'lab-04')",
                    },
                },
                "required": ["lab"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_groups",
            "description": "Get per-group performance metrics for a specific lab",
            "parameters": {
                "type": "object",
                "properties": {
                    "lab": {
                        "type": "string",
                        "description": "The lab identifier (e.g., 'lab-04')",
                    },
                },
                "required": ["lab"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_top_learners",
            "description": "Get top performing learners for a specific lab",
            "parameters": {
                "type": "object",
                "properties": {
                    "lab": {
                        "type": "string",
                        "description": "The lab identifier (e.g., 'lab-04')",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Number of top learners to return (default: 5)",
                        "default": 5,
                    },
                },
                "required": ["lab"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_completion_rate",
            "description": "Get the completion rate percentage for a specific lab",
            "parameters": {
                "type": "object",
                "properties": {
                    "lab": {
                        "type": "string",
                        "description": "The lab identifier (e.g., 'lab-04')",
                    },
                },
                "required": ["lab"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "sync_pipeline",
            "description": "Trigger the ETL pipeline to sync data from the source",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": [],
            },
        },
    },
]

SYSTEM_PROMPT = """You are an assistant for an LMS (Learning Management System) bot. 
Your job is to help users get information about labs, scores, learners, and system status.

You have access to tools that fetch data from the LMS backend. 
When a user asks a question, determine which tool(s) to call based on their intent.

Common intents:
- "Is the system working?" / "health check" → get_health
- "What labs are available?" / "show labs" → get_labs
- "Show scores for lab-X" / "pass rates" → get_scores (requires lab parameter)
- "Who are the top students?" → get_top_learners (requires lab parameter)
- "When did students submit?" → get_timeline (requires lab parameter)
- "How did groups perform?" → get_groups (requires lab parameter)
- "What's the completion rate?" → get_completion_rate (requires lab parameter)
- "Sync the data" → sync_pipeline

If the user's query is missing required parameters (like lab name), ask them to provide it.
Always be concise and helpful in your responses."""


async def route_intent(
    user_message: str,
    lms_client: LMSClient,
    llm_client: LLMClient,
) -> str:
    """Route a natural language message to the appropriate handler using LLM."""

    # First, ask the LLM which tool to use
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message},
    ]

    try:
        response = await llm_client.chat(messages, tools=TOOLS)
        message = response["choices"][0]["message"]

        # Check if LLM wants to call a tool
        if "tool_calls" in message and message["tool_calls"]:
            tool_call = message["tool_calls"][0]
            function_name = tool_call["function"]["name"]
            function_args = tool_call["function"]["arguments"]

            if isinstance(function_args, str):
                import json

                function_args = json.loads(function_args)

            # Execute the tool
            result = await execute_tool(function_name, function_args, lms_client)

            # Send result back to LLM for natural language response
            messages.append(message)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call["id"],
                    "content": str(result),
                }
            )

            final_response = await llm_client.chat(messages)
            return final_response["choices"][0]["message"]["content"]
        else:
            # No tool call - return the LLM's direct response
            return message.get(
                "content",
                "I'm not sure how to help with that. Try /help for available commands.",
            )

    except Exception as e:
        return f"⚠️ Error processing your request: {str(e)}"


async def execute_tool(
    function_name: str,
    arguments: dict[str, Any],
    lms_client: LMSClient,
) -> Any:
    """Execute a tool function and return the result."""

    tool_map = {
        "get_health": lambda: lms_client.health_check(),
        "get_labs": lambda: lms_client.get_items(),
        "get_scores": lambda: lms_client.get_pass_rates(arguments.get("lab", "")),
        "get_learners": lambda: lms_client.get_learners(),
        "get_timeline": lambda: lms_client.get_timeline(arguments.get("lab", "")),
        "get_groups": lambda: lms_client.get_groups(arguments.get("lab", "")),
        "get_top_learners": lambda: lms_client.get_top_learners(
            arguments.get("lab", ""), arguments.get("limit", 5)
        ),
        "get_completion_rate": lambda: lms_client.get_completion_rate(
            arguments.get("lab", "")
        ),
        "sync_pipeline": lambda: lms_client.sync_pipeline(),
    }

    if function_name not in tool_map:
        return f"Unknown tool: {function_name}"

    try:
        result = await tool_map[function_name]()
        return result
    except Exception as e:
        return f"Error executing {function_name}: {str(e)}"
