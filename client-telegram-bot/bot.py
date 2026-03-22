#!/usr/bin/env python3
"""SE Toolkit Bot - Telegram bot for LMS interaction."""

import asyncio
import sys
import argparse
from typing import Any

from config import load_config
from handlers.commands import (
    handle_start,
    handle_help,
    handle_health,
    handle_labs,
    handle_scores,
)
from handlers.intent_router import route_intent
from services.lms_client import LMSClient
from services.llm_client import LLMClient


# Command handler mapping
COMMAND_HANDLERS = {
    "/start": handle_start,
    "/help": handle_help,
    "/health": handle_health,
    "/labs": handle_labs,
    "/scores": handle_scores,
}


def parse_command(message: str) -> tuple[str, list[str]]:
    """Parse a command message into command and arguments."""
    parts = message.strip().split()
    if not parts:
        return "", []
    command = parts[0].lower()
    args = parts[1:]
    return command, args


async def process_command(message: str, context: dict[str, Any]) -> str:
    """Process a command or natural language message."""
    command, args = parse_command(message)
    
    # Check if it's a known slash command
    if command in COMMAND_HANDLERS:
        return await COMMAND_HANDLERS[command](args, context)
    
    # If it looks like a command but isn't recognized
    if command.startswith("/"):
        return f"❓ Unknown command: {command}. Type /help to see available commands."
    
    # Otherwise, treat as natural language - route via LLM
    llm_client = context.get("llm_client")
    if llm_client:
        return await route_intent(message, context["lms_client"], llm_client)
    
    return f"❓ I didn't understand that. Type /help to see available commands."


async def run_test_mode(command: str, config: dict[str, str]) -> None:
    """Run the bot in test mode - process a single command and print result."""
    # Create service clients
    lms_client = LMSClient(
        base_url=config["lms_api_url"],
        api_key=config["lms_api_key"],
    )
    llm_client = LLMClient(
        api_key=config["llm_api_key"],
        base_url=config["llm_api_base_url"],
        model=config["llm_api_model"],
    )
    
    # Build context
    context: dict[str, Any] = {
        "lms_client": lms_client,
        "llm_client": llm_client,
        "bot_name": "SE Toolkit Bot",
    }
    
    # Process the command
    result = await process_command(command, context)
    print(result)


async def run_telegram_mode(config: dict[str, str]) -> None:
    """Run the bot in Telegram mode."""
    try:
        from aiogram import Bot, Dispatcher, types
        from aiogram.filters import Command
    except ImportError:
        print("Error: aiogram not installed. Run: uv sync")
        sys.exit(1)
    
    bot_token = config.get("bot_token")
    if not bot_token:
        print("Error: BOT_TOKEN not set in client-telegram-bot/.env.secret")
        sys.exit(1)
    
    # Create service clients
    lms_client = LMSClient(
        base_url=config["lms_api_url"],
        api_key=config["lms_api_key"],
    )
    llm_client = LLMClient(
        api_key=config["llm_api_key"],
        base_url=config["llm_api_base_url"],
        model=config["llm_api_model"],
    )
    
    # Build context
    context: dict[str, Any] = {
        "lms_client": lms_client,
        "llm_client": llm_client,
        "bot_name": "SE Toolkit Bot",
    }
    
    # Create dispatcher
    dp = Dispatcher()
    
    # Register command handlers
    @dp.message(Command("start"))
    async def cmd_start(message: types.Message):
        response = await handle_start([], context)
        await message.answer(response)
    
    @dp.message(Command("help"))
    async def cmd_help(message: types.Message):
        response = await handle_help([], context)
        await message.answer(response)
    
    @dp.message(Command("health"))
    async def cmd_health(message: types.Message):
        response = await handle_health([], context)
        await message.answer(response)
    
    @dp.message(Command("labs"))
    async def cmd_labs(message: types.Message):
        response = await handle_labs([], context)
        await message.answer(response)
    
    @dp.message(Command("scores"))
    async def cmd_scores(message: types.Message):
        args = message.text.split()[1:] if message.text else []
        response = await handle_scores(args, context)
        await message.answer(response)
    
    # Handle all other messages (natural language)
    @dp.message()
    async def handle_message(message: types.Message):
        if message.text:
            response = await route_intent(message.text, lms_client, llm_client)
            await message.answer(response)
    
    # Run the bot
    print(f"Starting bot...")
    await dp.start_polling(Bot(token=bot_token))


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(description="SE Toolkit Bot")
    parser.add_argument(
        "--test",
        type=str,
        metavar="COMMAND",
        help="Run in test mode with the given command",
    )
    args = parser.parse_args()
    
    # Load configuration
    config = load_config()
    
    if args.test:
        # Test mode - process single command and exit
        asyncio.run(run_test_mode(args.test, config))
    else:
        # Telegram mode - run the bot
        asyncio.run(run_telegram_mode(config))


if __name__ == "__main__":
    main()
