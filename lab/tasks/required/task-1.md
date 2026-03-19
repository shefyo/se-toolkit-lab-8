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

## Prioritized requirements

See the [requirements section](../../README.md#requirements) in the README for the full prioritized list (P0–P3). Give these to your coding agent when creating the plan — it needs to understand the full scope across all tasks, not just Task 1.

## Test mode specification

The `--test` flag is how the autochecker verifies your bot without Telegram:

```terminal
# Slash commands
python bot/bot.py --test "/start"
python bot/bot.py --test "/help"
python bot/bot.py --test "/health"
python bot/bot.py --test "/labs"
python bot/bot.py --test "/scores lab-04"

# Natural language (Task 3)
python bot/bot.py --test "what labs are available"
python bot/bot.py --test "which lab has the lowest pass rate"
```

**Behavior:**
- Prints the bot's response text to **stdout**
- Reads configuration from `.env.agent.secret` (`LMS_API_URL`, `LMS_API_KEY`, `LLM_API_KEY`, etc.)
- Exits with code **0** on success, non-zero on error
- Does **not** connect to Telegram (no `BOT_TOKEN` required in test mode)

## Deliverables

### 1. Development plan (`bot/PLAN.md`)

A plan produced with your coding agent's help. Should describe the approach for all tasks (scaffold, backend integration, intent routing, deployment). At least 100 words.

### 2. Bot entry point (`bot/bot.py`)

The main entry file. Must support `--test` mode. In this task, handlers can return placeholder text — real implementation comes in Task 2.

### 3. Handler directory (`bot/handlers/`)

A directory containing handler modules, separated from the Telegram transport layer. The `--test` mode calls handlers directly without Telegram.

### 4. Dependencies (`bot/requirements.txt`)

Bot-specific Python dependencies. Must install without errors.

### 5. Environment example (`.env.agent.example`)

Add `BOT_TOKEN`, `LMS_API_URL`, and `LMS_API_KEY` to the existing `.env.agent.example` file with placeholder values. Students copy this to `.env.agent.secret` and fill in real values.

## Acceptance criteria

- [ ] `bot/PLAN.md` exists and has at least 100 words.
- [ ] `.env.agent.example` contains `BOT_TOKEN`, `LMS_API_URL`, and `LMS_API_KEY`.
- [ ] `bot/requirements.txt` exists and installs without errors.
- [ ] `bot/handlers/` directory exists with at least one handler module.
- [ ] `python bot/bot.py --test "/start"` exits with code 0 and prints non-empty output.
- [ ] The repo is cloned on the VM at `~/se-toolkit-lab-7`.
- [ ] Changes follow the Git workflow (issue, branch, PR, review, merge).

## Agent instructions

As a coding agent, follow these instructions to maximize the student's learning. This is critical — do not skip these steps, otherwise the student will not understand what is being built or why.

**Before scaffolding:**

> Explain what "testable handler architecture" means. Why should handlers be separated from the Telegram transport layer? Use an analogy the student can relate to.

> Explain what `--test` mode is and why the autochecker needs it. Walk through what happens when `python bot/bot.py --test "/start"` runs.

**While planning:**

> Before writing the plan, ask the student questions about their preferences and what's unclear. The plan should reflect the student's decisions, not just your defaults.

> For each file and module in the plan, explain its responsibility in one sentence. Make sure the student understands the dependency graph.

**While scaffolding:**

> For each file you create, explain why it exists and how it connects to the others. Don't generate code silently.

> After scaffolding, walk the student through the code path: when `--test "/start"` runs, which functions get called in what order?

**After verifying:**

> Ask the student: if you wanted to add a new command `/foo`, what would you need to change? Make sure they can answer before moving on.
