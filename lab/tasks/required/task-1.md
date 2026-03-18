# Plan and Scaffold

Use your coding agent to create a development plan and project skeleton for the Telegram bot. This is the foundation — you will implement the actual features in Tasks 2–3.

## What you will build

A `bot/` directory inside your repo containing the scaffolded project: entry point, handler layer, configuration, dependencies, and a `--test` mode for offline verification.

```
se-toolkit-lab-7/
├── bot/                    ← NEW
│   ├── bot.py              ← entry point
│   ├── handlers/           ← command handlers (separated from Telegram transport)
│   ├── services/           ← API client, LLM client
│   ├── config.py           ← environment variable loading
│   ├── requirements.txt    ← bot dependencies
│   └── PLAN.md             ← development plan
├── backend/                ← existing
├── frontend/               ← existing
└── docker-compose.yml      ← existing
```

The entry point must support a `--test` flag for offline command verification:

```terminal
python bot/bot.py --test "/start"
```

This prints the bot's response to stdout and exits — no Telegram connection needed. The autochecker uses this to verify your bot's behavior.

## How to approach this task

1. Give the prioritized requirements (below) to your coding agent.
2. Ask it to produce a development plan.
3. Ask it to scaffold the project structure.
4. Verify the scaffold works: `python bot/bot.py --test "/start"` should print something and exit 0.

## Prioritized requirements

Give these to your coding agent as context:

**P0 — Must have (Tasks 1–2):**
- Testable handler layer — handlers callable without Telegram
- CLI test mode: `python bot/bot.py --test "/command"` prints response to stdout
- `/start` — welcome message
- `/help` — lists available commands
- `/health` — calls backend, reports status
- At least 2 data commands fetching real data from the LMS backend

**P1 — Should have (Task 3):**
- Natural language intent routing — plain text messages interpreted by LLM
- Inline keyboard buttons for common commands
- Graceful error handling

**P2 — Nice to have:**
- Multi-step reasoning (chaining API calls)
- Response caching
- Conversation context

## Test mode specification

The `--test` flag is how the autochecker verifies your bot without Telegram:

```terminal
# Slash commands
python bot/bot.py --test "/start"
python bot/bot.py --test "/help"
python bot/bot.py --test "/health"

# Natural language (Task 3)
python bot/bot.py --test "what labs are available"
```

**Behavior:**
- Prints the bot's response text to **stdout**
- Reads configuration from `.env.agent.secret` (backend URL, API keys)
- Exits with code **0** on success, non-zero on error
- Does **not** connect to Telegram (no `BOT_TOKEN` required in test mode)

## Deliverables

### 1. Development plan (`bot/PLAN.md`)

A plan produced with your coding agent's help. Should describe the approach for all three tasks (scaffold, backend integration, intent routing). At least 100 words.

### 2. Bot entry point (`bot/bot.py`)

The main entry file. Must support `--test` mode. In this task, handlers can return placeholder text — real implementation comes in Task 2.

### 3. Handler module (`bot/handlers/` or `bot/handlers.py`)

Handlers separated from the Telegram transport layer. The `--test` mode calls handlers directly without Telegram.

### 4. Dependencies (`bot/requirements.txt`)

Bot-specific Python dependencies. Must install without errors.

### 5. Bot token in env example (`.env.agent.example`)

Add `BOT_TOKEN` to the existing `.env.agent.example` file.

## Acceptance criteria

- [ ] `bot/PLAN.md` exists and has at least 100 words.
- [ ] `.env.agent.example` contains `BOT_TOKEN`.
- [ ] `bot/requirements.txt` exists and installs without errors.
- [ ] Handler module exists separately from the bot entry point.
- [ ] `python bot/bot.py --test "/start"` exits with code 0 and prints non-empty output.
- [ ] Changes follow the Git workflow (issue, branch, PR, review, merge).
