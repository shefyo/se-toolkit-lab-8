#!/usr/bin/env python3
"""SE Toolkit Bot - Telegram bot for LMS interaction."""

import asyncio
import sys
import argparse

from config import load_config
from handlers.intent_router import route_intent
from services.nanobot_client import NanobotClient


HELP_TEXT = (
    "📚 Available commands:\n\n"
    "• /start - Welcome message\n"
    "• /help - Show this help message\n"
    "• /login <api_key> - Set your LMS API key\n"
    "• /logout - Remove your LMS API key\n\n"
    "You can also ask questions in plain language, like:\n"
    "• 'Is the backend healthy?'\n"
    "• 'What labs are available?'\n"
    "• 'Show me the scores for lab-04'"
)

WELCOME_TEXT = (
    "👋 Welcome to SE Toolkit Bot!\n\n"
    "I'm your LMS assistant. To get started, set your API key:\n"
    "  /login <your-api-key>\n\n"
    "Then ask me anything in plain language,\n"
    "or type /help to see available commands."
)

# user_id -> api_key
_user_keys: dict[int, str] = {}


async def run_test_mode(command: str, config: dict[str, str]) -> None:
    """Run the bot in test mode - process a single command and print result."""
    nanobot_client = NanobotClient(ws_url=config["nanobot_ws_url"])
    response = await route_intent(command, nanobot_client)
    # In test mode, just print the content
    print(response.get("content", response))


async def run_telegram_mode(config: dict[str, str]) -> None:
    """Run the bot in Telegram mode."""
    try:
        from aiogram import Bot, Dispatcher, types
        from aiogram.filters import Command
    except ImportError:
        print("Error: aiogram not installed. Run: uv sync")
        sys.exit(1)

    from handlers.renderer import render

    bot_token = config.get("bot_token")
    if not bot_token:
        print("Error: BOT_TOKEN not set in client-telegram-bot/.env.secret")
        sys.exit(1)

    nanobot_client = NanobotClient(ws_url=config["nanobot_ws_url"])
    dp = Dispatcher()

    @dp.message(Command("start"))
    async def cmd_start(message: types.Message):
        await message.answer(WELCOME_TEXT)

    @dp.message(Command("help"))
    async def cmd_help(message: types.Message):
        await message.answer(HELP_TEXT)

    @dp.message(Command("login"))
    async def cmd_login(message: types.Message):
        args = message.text.split()[1:] if message.text else []
        if not args:
            await message.answer("Usage: /login <api_key>")
            return
        _user_keys[message.from_user.id] = args[0]
        await message.answer("✅ API key saved. You can now ask questions.")

    @dp.message(Command("logout"))
    async def cmd_logout(message: types.Message):
        _user_keys.pop(message.from_user.id, None)
        await message.answer("🔓 API key removed.")

    @dp.message()
    async def handle_message(message: types.Message):
        if message.text:
            api_key = _user_keys.get(message.from_user.id, "")
            if not api_key:
                await message.answer("🔑 Please set your API key first: /login <api_key>")
                return
            response = await route_intent(message.text, nanobot_client, api_key=api_key)
            await render(message, response)

    @dp.callback_query()
    async def handle_callback(callback: types.CallbackQuery):
        await callback.answer()
        api_key = _user_keys.get(callback.from_user.id, "")
        if not api_key:
            await callback.message.answer("🔑 Please set your API key first: /login <api_key>")
            return
        response = await route_intent(callback.data, nanobot_client, api_key=api_key)
        await render(callback.message, response)

    print("Starting bot...")
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
    config = load_config()

    if args.test:
        asyncio.run(run_test_mode(args.test, config))
    else:
        asyncio.run(run_telegram_mode(config))


if __name__ == "__main__":
    main()
