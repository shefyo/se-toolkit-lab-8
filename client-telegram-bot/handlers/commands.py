"""Command handlers for slash commands."""

from typing import Any


async def handle_start(args: list[str], context: dict[str, Any]) -> str:
    """Handle /start command - welcome message."""
    bot_name = context.get("bot_name", "SE Toolkit Bot")
    return (
        f"👋 Welcome to {bot_name}!\n\n"
        f"I'm your LMS assistant. I can help you:\n"
        f"• Check system health with /health\n"
        f"• Browse available labs with /labs\n"
        f"• View scores with /scores <lab>\n"
        f"• Ask questions in plain language!\n\n"
        f"Type /help to see all available commands."
    )


async def handle_help(args: list[str], context: dict[str, Any]) -> str:
    """Handle /help command - list all commands."""
    return (
        "📚 Available commands:\n\n"
        "• /start - Welcome message\n"
        "• /help - Show this help message\n"
        "• /health - Check backend system status\n"
        "• /labs - List all available labs\n"
        "• /scores <lab> - View pass rates for a specific lab\n\n"
        "You can also ask questions in plain language, like:\n"
        "• 'What labs are available?'\n"
        "• 'Show me the scores for lab-04'\n"
        "• 'Is the backend working?'"
    )


async def handle_health(args: list[str], context: dict[str, Any]) -> str:
    """Handle /health command - check backend status."""
    lms_client = context.get("lms_client")
    if not lms_client:
        return "⚠️ LMS client not configured"

    result = await lms_client.health_check()

    if result["status"] == "healthy":
        return f"✅ Backend is healthy. {result['item_count']} items available."
    else:
        error_msg = result.get("error", "Unknown error")
        return f"❌ Backend error: {error_msg}"


async def handle_labs(args: list[str], context: dict[str, Any]) -> str:
    """Handle /labs command - list available labs."""
    lms_client = context.get("lms_client")
    if not lms_client:
        return "⚠️ LMS client not configured"

    try:
        items = await lms_client.get_items()

        # Group items by lab - items with type "lab" are labs themselves
        labs = []
        for item in items:
            if item.get("type") == "lab":
                labs.append(
                    {
                        "id": item.get("id", ""),
                        "title": item.get("title", "Unknown Lab"),
                    }
                )

        if not labs:
            return "📭 No labs available."

        response = "📚 Available labs:\n\n"
        for lab in sorted(labs, key=lambda x: x["id"]):
            response += f"• {lab['title']}\n"

        return response.strip()
    except Exception as e:
        return f"❌ Error fetching labs: {str(e)}"


async def handle_scores(args: list[str], context: dict[str, Any]) -> str:
    """Handle /scores command - show pass rates for a lab."""
    lms_client = context.get("lms_client")
    if not lms_client:
        return "⚠️ LMS client not configured"

    if not args:
        return "❌ Please specify a lab. Usage: /scores <lab>\nExample: /scores lab-04"

    lab = args[0]

    try:
        pass_rates = await lms_client.get_pass_rates(lab)

        if not pass_rates:
            return f"📭 No scores found for {lab}. Check the lab name."

        response = f"📊 Pass rates for {lab}:\n\n"
        for rate in pass_rates:
            task_name = rate.get("task", "Unknown")
            pass_rate = rate.get("avg_score", 0)
            attempts = rate.get("attempts", 0)
            response += f"• {task_name}: {pass_rate:.1f}% ({attempts} attempts)\n"

        return response.strip()
    except Exception as e:
        error_str = str(e)
        if "404" in error_str or "not found" in error_str.lower():
            return f"❌ Lab '{lab}' not found. Check the lab name."
        return f"❌ Error fetching scores: {error_str}"
