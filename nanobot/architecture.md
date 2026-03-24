# Nanobot architecture

This directory contains the nanobot gateway deployment for the LMS — an AI assistant that connects to chat channels and answers questions using LLM reasoning and LMS backend data.

## Upstream dependency

The framework comes from the `nanobot-ai` PyPI package (source: `../nanobot` in the parent monorepo at `inno-se-toolkit/nanobot`). We consume it as a pip dependency, not a fork. All customization is done through the **channel plugin** system.

## Directory layout

```
nanobot/
├── nanobot_common/          # Shared library (LMS client, models, formatters)
│   ├── __init__.py
│   ├── lms_client.py        # HTTP client for the LMS backend API
│   ├── models.py            # Pydantic models for LMS API responses
│   └── formatters.py        # Pure formatting functions
├── nanobot_webchat/         # WebSocket channel plugin for chat clients
│   └── __init__.py          # WebChatChannel (BaseChannel subclass)
├── workspace/
│   └── skills/lms/SKILL.md  # Teaches the nanobot agent how to call LMS API via curl
├── config.json              # Gateway config (webchat channel only)
├── pyproject.toml           # Dependencies + entry point registration
├── Dockerfile               # Multi-stage build
└── architecture.md          # This file
```

## How clients connect

Both the Flutter web app and the Telegram bot connect to the **same nanobot instance** over WebSocket. The nanobot gateway exposes a single webchat channel on port 8765.

```
Flutter app        →  WebSocket (ws://nanobot:8765)  →  nanobot agent
Telegram bot       →  WebSocket (ws://nanobot:8765)  →  nanobot agent
```

The Telegram bot (`client-telegram-bot/`) is a standalone aiogram service. It handles slash commands directly via the LMS backend API and forwards free-text messages to nanobot over WebSocket.

## Docker services

| Service | Image source | Purpose |
|---------|-------------|---------|
| `nanobot` | `./nanobot` | AI agent gateway with webchat WebSocket (port 8765) |
| `client-telegram-bot` | `./client-telegram-bot` | Telegram bot — slash commands + WebSocket forwarding |

Caddy reverse-proxies the nanobot instance: `/utils/nanobot*` → port 18790, `/ws/chat` → port 8765.

## WebSocket protocol

Clients connect to `ws://nanobot:8765` and exchange JSON messages:

- **Send**: `{"content": "user message"}`
- **Receive**: `{"content": "agent response"}`

Each WebSocket connection gets its own chat session (UUID-based). The agent processes the message, may call tools (curl, exec, read_file), and returns a single response.

## Message flow

### Free text (agent-routed)

```
User sends text in Telegram
  → aiogram receives via long polling
  → bot opens WebSocket to nanobot (ws://nanobot:8765)
  → sends {"content": text}
  → nanobot agent reasons with LLM, may call tools
  → agent produces response
  → bot receives {"content": response} over WebSocket
  → bot.send_message(chat_id, response)
```

### Slash commands (direct, no LLM)

```
User sends /scores lab-04
  → aiogram Command("scores") handler fires
  → handler calls LMSClient.get_pass_rates("lab-04") via httpx
  → handler formats result and calls message.answer(text)
```

No agent involvement. Sub-second response. Commands: `/start`, `/help`, `/health`, `/labs`, `/scores <lab>`.

## Environment variables

### nanobot service

| Variable | Purpose |
|----------|---------|
| `NANOBOT_LMS_API_KEY` | Backend auth for agent's curl-based LMS skill |
| `NANOBOT_LMS_BACKEND_URL` | Backend URL for agent's curl-based LMS skill |
| `NANOBOT_PROVIDERS__CUSTOM__API_KEY` | LLM API key |
| `NANOBOT_PROVIDERS__CUSTOM__API_BASE` | LLM API base URL |

### client-telegram-bot service

| Variable | Purpose |
|----------|---------|
| `BOT_TOKEN` | Telegram bot token |
| `LMS_API_KEY` | Backend auth for direct slash commands |
| `LMS_API_BASE_URL` | Backend URL for direct slash commands |
| `NANOBOT_WS_URL` | Nanobot WebSocket URL (`ws://nanobot:8765`) |

## Debugging checklist

1. **Bot not receiving messages**: Check `docker compose logs client-telegram-bot`. Look for `Starting bot...`. If missing, the token is wrong or aiogram failed to import.

2. **`TelegramConflictError`**: Two processes are polling the same bot token. Stop orphan containers with the same token.

3. **Free text returns "Could not reach the AI agent"**: The nanobot service is down or unreachable. Check `docker compose logs nanobot` and verify the webchat channel started on port 8765.

4. **Slash commands return "LMS client not configured"**: `LMS_API_BASE_URL` or `LMS_API_KEY` env vars are missing from the client-telegram-bot service.

5. **Slow responses to free text**: The nanobot agent runs tool calls (curl, exec, read_file) before answering. This is normal — the agent may take 10-60s for complex queries. Slash commands bypass this entirely.

6. **`setuptools` build error ("Multiple top-level packages")**: The `[tool.setuptools.packages.find]` section in `pyproject.toml` must explicitly include all packages (`nanobot_common`, `nanobot_webchat`).
