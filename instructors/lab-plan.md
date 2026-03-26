# Lab plan — The Agent is the Interface

**Topic:** AI agents as a new type of client interface for existing services
**Date:** 2026-03-26

## Main goals

- Teach students that an AI agent is a new type of client — like a web app or a Telegram bot, but one that reasons, chains API calls, and answers in natural language.
- Have students set up an agent (nanobot) from scratch: add it as a submodule, configure it, connect it to an LLM, wire it into the system, and experience the difference between a bare agent and one equipped with tools.
- Demonstrate that observability data (logs, traces) becomes accessible to non-technical users when the agent can query it — turning infrastructure into a conversational interface.

<!-- sometimes, you can use a debugger. other times - no -->
<!-- fix a bug in a problematic endpoint (e.g. model field mismatch) -->
<!-- optional task - improve formatting of messages in clients -->
<!-- if not enough memory - use swap -->

## Learning outcomes

By the end of this lab, students should be able to:

- [Understand] Explain how an AI agent differs from a traditional client (web app, bot) — it reasons about which API calls to make rather than following hardcoded logic.
- [Apply] Set up an AI agent from scratch: add it as a submodule, configure the LLM provider, wire it into Docker Compose, and connect it to an existing backend via MCP tools.
- [Apply] Write MCP tools and skill prompts that give the agent structured access to services it couldn't use before.
- [Analyze] Compare a bare agent (no tools) with an equipped agent (MCP tools + skills) and explain why structured tool access matters.
- [Analyze] Use the agent to investigate a real bug by chaining log and trace queries in natural language.
- [Create] Configure an agent with a skill prompt, a cron job, and a multi-step task that chains multiple tools to produce a periodic health report.

In simple words:

> 1. I can explain what makes an AI agent different from a regular client like a web app or a bot.
> 2. I set up nanobot from scratch — added it as a submodule, connected it to the Qwen API, wired it into Docker Compose, and talked to it.
> 3. I saw what a bare agent does without tools (hallucinates) vs. with MCP tools (answers correctly) — and I understand why.
> 4. I built MCP tools that let the agent query logs and traces, turning observability data into a conversational interface.
> 5. I used the agent to find and fix a real bug without manually grepping logs.
> 6. I configured a cron job so the agent proactively reports system health.

## Lab story

The LMS has been running on your VM for weeks — backend, Caddy, React dashboard, PostgreSQL.
In the previous lab you built a Telegram bot that talks to the backend using hardcoded slash commands and an LLM tool-calling loop you wrote yourself.

Your team lead has heard about a new approach: instead of writing a custom client for every interface, you deploy an AI agent that sits between users and the backend.
The agent receives natural language, reasons about which API calls to make, and returns structured responses.
Any chat interface — Telegram, a web app, a terminal — just connects to the agent via WebSocket.

A senior engineer explains the assignment:

> 1. Add the nanobot agent to the system. Set it up from scratch — configure the LLM, connect it to the backend via MCP tools, and deploy it alongside the existing services.
> 2. Once it works, give it new capabilities: wire it into the observability stack (VictoriaLogs and VictoriaTraces) so anyone can ask about system health in plain language.
> 3. Use the agent to investigate a real production issue — prove that this approach works for debugging, not just data queries.
> 4. Make the agent proactive: configure a scheduled health check so it reports problems before users notice.

## What students start with

The main branch contains the base LMS system:

- **backend/** — FastAPI REST API (items, learners, interactions, analytics, ETL pipeline)
- **postgres** — PostgreSQL database
- **caddy/** — reverse proxy serving the React dashboard and backend API
- **client-web-react/** — React dashboard SPA
- **qwen-code-api** — submodule, already wired as a Docker Compose service (LLM access)
- Observability stack pre-configured in Docker Compose: VictoriaLogs, VictoriaTraces, OpenTelemetry Collector

Students do **not** start with nanobot, MCP server, Telegram bot, or Flutter client. They add these themselves.

## Required tasks

### Task 1 — Set Up the Agent

**Purpose:**

Students experience the full setup of an AI agent from scratch.
By the end, they have a working agent they can chat with — and they understand every piece of the wiring because they built it.

**Summary:**

#### Part A — Add nanobot and connect to Qwen API

Students add the nanobot repository as a git submodule.
They create a minimal `config.json` that connects the agent to the Qwen Code API (already running as a Docker Compose service).
They write a Dockerfile for the nanobot service and add it to `docker-compose.yml`.
They add a Caddy route for the WebSocket endpoint (`/ws/chat`).

After deploying, students connect to the agent via a simple WebSocket client (e.g., `websocat ws://localhost:42002/ws/chat`) and have a conversation.
The agent can answer general questions using the LLM, but it knows nothing about the LMS.

#### Part B — Give the agent LMS tools

Students add the MCP server package (`mcp/mcp_lms/`) that exposes the backend API as typed tools.
They register the MCP server in the nanobot config and write a skill prompt (`workspace/skills/lms/SKILL.md`) that teaches the agent when and how to use each tool.

After redeploying, students ask the same questions as in Part A — "what labs are available?", "which lab has the lowest pass rate?" — and see the agent call the right API endpoints and return real data.

Students compare the two experiences: bare agent (Part A) vs. equipped agent (Part B).

#### Part C — Add a chat client

Students add the Flutter web client as a submodule (or implement a minimal chat UI).
They wire it into Docker Compose and Caddy so it's served at `/flutter`.
They open it in a browser, log in with their API key, and chat with the agent through a proper UI.

**Acceptance criteria:**

- Nanobot is added as a git submodule and runs as a Docker Compose service.
- The agent connects to the Qwen Code API and responds to general questions.
- MCP tools are registered and the agent can query backend data (items, analytics, pass rates).
- A skill prompt exists that guides the agent's tool usage.
- A chat client (Flutter or minimal web UI) is accessible at `/flutter` and communicates with the agent via WebSocket.
- The student can demonstrate the difference between asking the bare agent vs. the equipped agent the same question.

---

### Task 2 — Give the Agent New Eyes (Observability)

**Purpose:**

The agent can already query application data. Now students extend it with operational data — logs and traces.
This demonstrates the pattern: take any service API, wrap it as MCP tools, write a skill prompt, and the agent gains a new capability.

**Summary:**

#### Part A — Add structured logging

Students run `docker compose logs backend` and see unstructured text: Uvicorn startup messages, raw request lines, Python tracebacks.
They try to find "all errors from the backend" and discover it requires fragile text matching.

Students configure structured JSON logging across the backend and nanobot services.
They set up a JSON log formatter so every entry has consistent fields: `level`, `event`, and `service`.

Students add log statements so that a single user request produces a defined sequence of events across services.
The task specifies the expected log sequence for two scenarios: a successful request and a failed request (database down).

**Expected log sequence — happy path** (e.g., user asks "what labs are available?"):

| #   | service | event                 | key fields                                |
| --- | ------- | --------------------- | ----------------------------------------- |
| 1   | nanobot | `ws_message_received` | `chat_id`                                 |
| 2   | nanobot | `tool_call`           | `tool`                                    |
| 3   | backend | `request_started`     | `method`, `path`                          |
| 4   | backend | `auth_success`        |                                           |
| 5   | backend | `db_query`            | `table`, `operation`                      |
| 6   | backend | `request_completed`   | `method`, `path`, `status`, `duration_ms` |
| 7   | nanobot | `tool_result`         | `tool`, `success`                         |
| 8   | nanobot | `ws_message_sent`     | `chat_id`                                 |

**Expected log sequence — error path** (database is down):

| #   | service | event                 | key fields                                     |
| --- | ------- | --------------------- | ---------------------------------------------- |
| 1   | nanobot | `ws_message_received` | `chat_id`                                      |
| 2   | nanobot | `tool_call`           | `tool`                                         |
| 3   | backend | `request_started`     | `method`, `path`                               |
| 4   | backend | `auth_success`        |                                                |
| 5   | backend | `db_query`            | `level: "error"`, `table`, `error`             |
| 6   | backend | `request_completed`   | `method`, `path`, `status: 500`, `duration_ms` |
| 7   | nanobot | `tool_result`         | `tool`, `success: false`                       |
| 8   | nanobot | `ws_message_sent`     | `chat_id`                                      |

After redeploying, students trigger both scenarios and verify the full sequences appear in `docker compose logs`.

#### Part B — Add observability MCP tools

Students implement MCP tools that query VictoriaLogs and VictoriaTraces:
- At least two log tools (search by keyword/time range, count errors per service)
- At least two trace tools (list recent traces, fetch a trace by ID)

Each tool handles the HTTP call, parses the response, and returns a structured result.

Students write an observability skill that tells the agent *when* to use each tool — e.g., "when the user asks about errors, search logs first; if you find a trace ID, fetch the full trace."

After redeploying, students ask the agent "any errors in the last hour?" and "show me the trace for that request" — and get real answers.

**Acceptance criteria:**

- Both services emit JSON-structured log entries with at least `level`, `event`, and `service` fields.
- A successful request produces the happy-path log sequence.
- A failed request produces the error-path log sequence.
- At least two MCP tools for querying VictoriaLogs are registered.
- At least two MCP tools for querying VictoriaTraces are registered.
- An observability skill exists and is loaded by the agent.
- The agent answers "any errors in the last hour?" correctly under both normal and failure conditions.

---

### Task 3 — Diagnose and Fix a Bug Using the Agent

**Purpose:**

Everything students built in Tasks 1–2 is now the tool they use to solve a real problem.
This task proves that an AI agent isn't just a novelty — it's how you debug a multi-service system when you can't attach a debugger.

**Summary:**

The instructor deploys a version of the backend with a planted bug (e.g., a model field mismatch that causes a specific endpoint to return 500 errors intermittently).
Students are not told what the bug is or where it is — only that "users are reporting errors."

Students ask the agent to investigate — querying step by step: "show me recent errors," then "get that trace," then "what service failed."
Based on the agent's responses, students piece together the root cause, fix the bug, redeploy, and verify the fix by asking the agent again.

Students document the investigation: the questions they asked, the agent's responses, the root cause, and the fix.
They also note the friction of manually driving each step.

**Acceptance criteria:**

- The student uses the agent to identify the affected endpoint and error type without prior knowledge of the bug.
- The student fixes the bug in the code and redeploys.
- After the fix, the agent confirms no errors when asked.
- The student documents the investigation steps, root cause, and fix.

---

### Task 4 — Make the Agent Proactive

**Purpose:**

In Task 3, students drove the investigation manually — one question at a time.
A skill that chains multiple tools turns the agent from a single-query helper into an autonomous investigator.
A cron job makes the agent proactive instead of reactive.

**Summary:**

#### Part A — Multi-step skill

Students enhance the observability skill from Task 2 to guide multi-step investigations.
The skill instructs the agent that when asked "what went wrong?", it should first search logs for recent errors, extract a trace ID, then fetch the full trace to show the request flow.
Students also add guidance for summarizing results concisely.

Students verify by triggering a failure and asking the agent to investigate — the agent should chain log and trace tools autonomously and produce a coherent summary in a single response.

#### Part B — Cron health check

Students configure a cron job in `cron/jobs.json` that runs a periodic health check.
The job uses the `agent_turn` payload kind — it sends a message like "Check for errors in the last 15 minutes and report a summary" to the agent on a schedule (e.g., every 15 minutes).
The agent receives this as a regular message, reasons using the observability skill, calls MCP tools, and delivers the result to the webchat channel.

Students verify the cron job fires by setting a short interval (e.g., every 2 minutes), waiting for a cycle, and checking that the agent produced a health report in the Flutter web app.

**Acceptance criteria:**

- The skill guides the agent to chain log and trace tools for multi-step investigations.
- The agent produces a coherent summary when asked "what went wrong?" after a failure.
- A cron job is configured in `cron/jobs.json` that triggers a periodic health check via `agent_turn`.
- The cron job fires on schedule and the agent delivers a health report to the webchat channel.
- When errors exist, the health report includes information from both log and trace tools.

---

## Optional task

### Task 1 — Add a Telegram Bot Client

**Purpose:**

The Flutter web client connects to the agent via WebSocket. A Telegram bot is another client that connects the same way — demonstrating that the agent is the interface, not any particular frontend.

**Summary:**

Students add the Telegram bot client as a submodule or implement one from scratch.
The bot connects to nanobot via WebSocket and relays messages between Telegram users and the agent.
Slash commands (`/start`, `/help`, `/health`, `/labs`) are handled directly; free-text messages go through the agent.

Students wire the bot into Docker Compose, configure the bot token, and deploy.
They compare the experience: same agent, same tools, same answers — different client.

**Acceptance criteria:**

- The Telegram bot runs as a Docker Compose service.
- Slash commands work without the agent (direct backend calls).
- Free-text messages are routed to the agent and responses appear in Telegram.
- The same observability queries work from both Telegram and the Flutter web app.

## Setup changes needed

The `setup-simple.md` needs the following adjustments for this lab:

- **Step 1.3:** Stop Lab **7** services (not Lab 6).
- **Step 1.4:** Only base services come up: backend, postgres, caddy, client-web-react, qwen-code-api, pgadmin. No nanobot, no telegram bot, no flutter.
- **Step 1.9:** Qwen Code API is now a compose service — students just set `QWEN_CODE_API_KEY` in `.env.docker.secret`. No separate clone/deploy needed.
- **Step 1.10:** Remove "Get a Telegram bot token" from setup — it moves to the optional task.
- **Step 1.11:** Coding agent section stays.
- **New note:** Explain that students will add more services (nanobot, chat clients) during the tasks — the setup only launches the base system.
