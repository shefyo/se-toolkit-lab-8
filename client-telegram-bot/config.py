"""Configuration loader for the bot."""

import os
from dotenv import load_dotenv
from pathlib import Path


def load_config() -> dict[str, str]:
    """Load configuration from environment variables."""
    env_path = Path(__file__).parent / ".env.secret"
    load_dotenv(env_path)

    return {
        "bot_token": os.getenv("BOT_TOKEN", ""),
        "nanobot_ws_url": os.getenv("NANOBOT_WS_URL", "ws://localhost:8765"),
    }
