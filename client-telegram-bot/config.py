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
        "lms_api_url": os.getenv("LMS_API_BASE_URL", "http://localhost:42002"),
        "lms_api_key": os.getenv("LMS_API_KEY", ""),
        "llm_api_key": os.getenv("LLM_API_KEY", ""),
        "llm_api_base_url": os.getenv("LLM_API_BASE_URL", "http://localhost:42005/v1"),
        "llm_api_model": os.getenv("LLM_API_MODEL", "coder-model"),
    }
