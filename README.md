# Lab 8 — The Agent is the Interface

[Sync your fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork#syncing-a-fork-branch-from-the-command-line) regularly — the lab gets updated.

## Product brief

> Your team has been running the LMS backend for weeks. Everyone queries data through the React dashboard or Swagger UI. Your team lead wants a new kind of interface: an AI agent that anyone can talk to in natural language. Instead of clicking through dashboards, users just ask questions — "which lab has the lowest pass rate?", "any errors in the last hour?" — and the agent figures out which API calls to make.
>
> Set it up from scratch. Wire it into the system. Then extend it with observability tools so it can answer questions about system health too.

> [!IMPORTANT]
> Do this lab on your VM, ideally through `VS Code` Remote-SSH. Do not install or run `nanobot` on your main machine.

## What you will learn

By the end of this lab, you should be able to say:

> 1. I can explain what makes an AI agent different from a regular client like a web app or a bot.
>    It is not just a self-hosted chat window: it has tools, skills, memory, and can act proactively.
> 2. I set up nanobot from scratch — created the project, installed the framework, connected it to the Qwen API, wired it into Docker Compose, and talked to it.
> 3. I saw what a bare agent does without tools (hallucinates) vs. with MCP tools (answers correctly) — and I understand why.
> 4. I built MCP tools that let the agent query logs and traces, turning observability data into a conversational interface.
> 5. I used the agent to find and fix a real bug without manually grepping logs.
> 6. I configured a cron job so the agent proactively reports system health.

## Architecture

High level: you start with a normal web system, then add an AI agent as a new interface to that same system.

```
Before:
browser -> caddy -> LMS backend -> postgres
                   -> observability stack

After:
browser / telegram (optional) -> nanobot agent -> LMS tools -> LMS backend
                                -> observability tools -> logs / traces
                                -> LLM
```

Task 2 pulls the WebSocket channel and browser client from the separate [`nanobot-websocket-channel`](https://github.com/inno-se-toolkit/nanobot-websocket-channel) repository. The browser UI stays generic and is protected by a student-chosen `NANOBOT_ACCESS_KEY`.

### What you start with

- **LMS app**: the React dashboard, FastAPI backend, and PostgreSQL database.
- **Platform services**: Caddy routes requests, and `qwen-code-api` gives your agent access to the LLM.
- **Observability stack**: OpenTelemetry, VictoriaLogs, and VictoriaTraces already collect system telemetry.

### What you add

- **Nanobot agent**: a new interface to the LMS that can reason, use tools, and answer in natural language.
- **Web chat access**: a WebSocket channel plus Flutter web client at `/flutter`, protected by `NANOBOT_ACCESS_KEY`.
- **New agent abilities**: LMS MCP tools first, then observability tools, then a scheduled health-check job.

## Tasks

### Prerequisites

1. Complete the [lab setup](./lab/setup/setup-simple.md#lab-setup)

> **Note**: First time in this course? Do the [full setup](./lab/setup/setup-full.md#lab-setup) instead.

### Required

1. [Set Up the Agent](./lab/tasks/required/task-1.md) — install nanobot, configure Qwen API, add MCP tools, write skill prompt
2. [Deploy and Connect a Web Client](./lab/tasks/required/task-2.md) — Dockerize nanobot, add WebSocket channel + Flutter chat UI
3. [Give the Agent New Eyes](./lab/tasks/required/task-3.md) — explore observability data, write log/trace MCP tools
4. [Diagnose and Fix a Bug](./lab/tasks/required/task-4.md) — use the agent to investigate a real production issue
5. [Make the Agent Proactive](./lab/tasks/required/task-5.md) — multi-step skills, cron health checks

### Optional

1. [Add a Telegram Bot Client](./lab/tasks/optional/task-1.md) — same agent, different interface
