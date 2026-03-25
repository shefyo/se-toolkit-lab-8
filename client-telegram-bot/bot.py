#!/usr/bin/env python3
"""SE Toolkit Bot - Telegram bot for LMS interaction."""

from __future__ import annotations

import asyncio
import sys

from aiogram import Bot, Dispatcher
from aiogram.filters import Command

from config import load_config
from handlers.commands import MessageHandler, SessionHandlers, cmd_help, cmd_start
from services.nanobot_client import NanobotClient


async def run(config: dict[str, str]) -> None:
    bot_token = config.get("bot_token")
    if not bot_token:
        print("Error: BOT_TOKEN not set in client-telegram-bot/.env.secret")
        sys.exit(1)

    user_keys: dict[int, str] = {}
    nanobot_client = NanobotClient(ws_url=config["nanobot_ws_url"])
    session = SessionHandlers(user_keys)
    messages = MessageHandler(nanobot_client, user_keys)

    dp = Dispatcher()
    dp.message.register(cmd_start, Command("start"))
    dp.message.register(cmd_help, Command("help"))
    dp.message.register(session.cmd_login, Command("login"))
    dp.message.register(session.cmd_logout, Command("logout"))
    dp.message.register(messages.handle_message)
    dp.callback_query.register(messages.handle_callback)

    print("Starting bot...")
    await dp.start_polling(Bot(token=bot_token))


if __name__ == "__main__":
    asyncio.run(run(load_config()))
