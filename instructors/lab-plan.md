# Lab plan — Add Observability with VictoriaLogs and VictoriaTraces

**Topic:** structured logging, distributed tracing, and AI-assisted observability
**Date:** 2026-03-24

## Main goals

- Show students that unstructured text logs are nearly useless for debugging multi-service systems — structured logging makes the difference.
- Teach the two complementary views of a running system: logs tell you what happened at each service, traces tell you how a request flowed across services.
- Demonstrate that an AI agent becomes much more useful when it can access operational data — not just application data — through MCP tools.

## Learning outcomes

By the end of this lab, students should be able to:

- [Understand] Explain how structured logs and distributed traces provide complementary views of a multi-service system — logs capture events, traces capture request flow.
- [Apply] Add structured JSON logging at key points across multiple services so that both successful and failed requests produce a defined sequence of queryable events.
- [Apply] Implement MCP tools that query the VictoriaLogs API and return meaningful summaries to the nanobot agent.
- [Apply] Implement MCP tools that query the VictoriaTraces API and return trace information to the nanobot agent.
- [Analyze] Verify that the AI agent can combine log and trace data to answer natural-language questions about system health under normal and failure conditions.

In simple words:

> 1. I can explain the difference between logs and traces and when to use each.
> 2. I can add structured logging across services so that every request produces a queryable trail of events.
> 3. I can build MCP tools that let the AI agent search and summarize logs.
> 4. I can build MCP tools that let the AI agent look up and interpret traces.
> 5. I can verify that the agent answers "what went wrong?" correctly when something breaks.

## Lab story

The LMS has been running on your VM for weeks — backend, nanobot, Flutter web app, Caddy, PostgreSQL.
The team recently added VictoriaLogs, VictoriaTraces, and an OpenTelemetry Collector to the Docker Compose stack.
The backend is already instrumented with the OpenTelemetry SDK — traces flow into VictoriaTraces and logs are collected by VictoriaLogs — but the logs are still unstructured text, and nobody on the team knows how to use any of it.
When something goes wrong, nobody knows how to find the relevant traces or query the logs effectively.
Your team lead wants you to fix the logging, then wire both systems into the AI agent so anyone can ask about system health in plain language.

A senior engineer explains the assignment:

> 1. Add structured JSON logging across the backend and nanobot so every request — successful or failed — produces a defined sequence of queryable events.
> 2. Extend the nanobot agent with MCP tools that query VictoriaLogs, so users can ask about errors and request history.
> 3. Extend the nanobot agent with MCP tools that query VictoriaTraces, so users can ask about request flow and performance.

## Required tasks

### Task 1 — Add Structured Logging

**Purpose:**

Structured logs with consistent fields turn free-text search into precise, filterable queries — and make every other observability tool (traces, agent, alerting) more useful.

**Summary:**

Students start by opening the VictoriaLogs web UI (vmui) and looking at the current logs.
They see unstructured text: Uvicorn startup messages, raw request lines, Python tracebacks.
They try to query for "all errors from the backend" and discover that without structured fields, this requires fragile text matching.

Students then configure structured JSON logging across the backend and nanobot services.
They set up a JSON log formatter (via Python's logging or a library like `structlog`) so every entry has consistent fields: `level`, `event`, and `service`.

Next, students add log statements so that a single user request produces a defined sequence of events across services.
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

Students also add an `auth_failure` event (with `level: "warning"`) for requests with an invalid API key.

Students figure out where in the code each log statement belongs — in the webchat channel (`nanobot_webchat`), the MCP tool server (`lms_mcp`), and the backend (middleware, routes, DB layer).
After redeploying, they trigger both scenarios and verify the full sequences appear in VictoriaLogs.

**Acceptance criteria:**

- Both services emit JSON-structured log entries with at least `level`, `event`, and `service` fields.
- A successful request produces the happy-path log sequence, queryable in VictoriaLogs.
- A failed request (database down) produces the error-path log sequence, with `level: "error"` on the DB query event.
- A request with an invalid API key produces an `auth_failure` event with `level: "warning"`.
- The student documents a before/after comparison with an example query for each.

---

### Task 2 — Add Log Query Tools to the Nanobot Agent

**Purpose:**

Connecting the AI agent to VictoriaLogs lets users ask about errors, request history, and system health in natural language instead of writing LogsQL by hand.

**Summary:**

Students add MCP tools to the nanobot's MCP server that query the VictoriaLogs HTTP API.
They implement at least two tools: one that searches logs by keyword and time range (returning recent matching entries), and one that counts errors per service over a time window (returning a summary).
Each tool constructs a LogsQL query, sends it to the VictoriaLogs query endpoint, parses the JSON response, and returns a structured result.

Students write a skill prompt section that teaches the agent when to use the log tools.
For example: "any errors in the last hour?" should trigger the log search tool, "which service has the most errors?" should trigger the error count tool.
The prompt should guide the agent to summarize results concisely rather than dumping raw log entries.

After redeploying the nanobot, students verify the tools work under both normal and failure conditions.
They ask the agent about errors when the system is healthy (expecting "no errors found" or similar) and after triggering a failure (expecting a summary mentioning the affected service and error).

**Acceptance criteria:**

- At least two MCP tools for querying VictoriaLogs are registered in the MCP server.
- The skill prompt documents the log tools and guides the agent on when to use each.
- The agent answers "any errors in the last hour?" correctly under normal conditions.
- The agent answers "any errors in the last hour?" correctly after a failure, mentioning the affected service.
- The MCP server starts without errors after the changes.

---

### Task 3 — Add Trace Query Tools to the Nanobot Agent

**Purpose:**

Connecting the AI agent to VictoriaTraces lets users ask about request flow and performance without navigating the trace UI.

**Summary:**

Students add MCP tools to the nanobot's MCP server that query the VictoriaTraces HTTP API (Jaeger-compatible query endpoints).
They implement at least two tools: one that lists recent traces for a service (with duration and status), and one that fetches a specific trace by ID (returning the span hierarchy).
Each tool queries the VictoriaTraces API, parses the response, and returns a structured summary.

Students write a skill prompt section that teaches the agent when to use the trace tools.
For example: "is the backend slow?" should look at recent trace durations, "show me trace abc123" should fetch the full trace.
The prompt should guide the agent to combine log and trace tools when appropriate — e.g., find error logs, extract a trace ID, then fetch the full trace to show the request flow.

After redeploying the nanobot, students verify the tools work by asking the agent trace-related questions through the Flutter web app.
They also test a cross-tool scenario: trigger a failure, ask the agent what went wrong, and verify it uses both log and trace tools to provide a complete answer.

**Acceptance criteria:**

- At least two MCP tools for querying VictoriaTraces are registered in the MCP server.
- The skill prompt documents the trace tools and guides the agent on when to use each.
- The agent answers a question about recent request performance by calling the trace tools.
- The agent can fetch and summarize a specific trace by ID.
- The MCP server starts without errors after the changes.

---

## Optional task

### Task 1 — Set Up Error Alerting

**Purpose:**

Detecting problems before users report them is the difference between proactive and reactive operations.

**Summary:**

Students configure an alerting pipeline that fires when the error rate crosses a threshold.
They add vmalert (part of the VictoriaMetrics stack) as a Docker Compose service with a LogsQL-based alerting rule — for example, trigger when more than five log entries matching `level: "error"` appear within a 5-minute window.

Fired alerts are visible in the vmalert UI and queryable via its API.
Students add an MCP tool to the nanobot agent that checks vmalert's `/api/v1/alerts` endpoint and reports active alerts.
This way, a user can ask the agent "are there any active alerts?" and get a real answer — closing the loop between observability and the AI assistant.

To verify, students trigger the alert by stopping PostgreSQL and sending several requests, then confirm the alert appears in the vmalert UI and the nanobot agent reports it when asked.

**Acceptance criteria:**

- vmalert is running as a Docker Compose service with at least one LogsQL-based alerting rule.
- The alert fires when the error threshold is exceeded within the configured time window.
- An MCP tool reports active alerts from the vmalert API to the nanobot agent.
- The alerting rule and threshold are configurable without code changes.
