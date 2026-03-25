---
name: lms
description: Query the Learning Management System backend for labs, scores, learners, and analytics.
metadata:
  {
    "nanobot":
      {
        "emoji": "📚",
        "requires": { "env": ["NANOBOT_LMS_BACKEND_URL"] },
        "always": true,
      },
  }
---

# LMS (Learning Management System)

Query the LMS backend API using the `mcp_lms_*` tools. All tools require an `api_key` parameter.

## Authentication

The user's message begins with `[LMS_API_KEY=<key>]`. Extract the key and pass it as the `api_key` parameter in every tool call.

If the message does **not** contain `[LMS_API_KEY=...]`, tell the user they need to authenticate first (e.g. via `/login <api_key>` in the Telegram bot, or the login screen in the web app).

**Never include the API key in your responses to the user.**

## Structured responses

Your responses are rendered by different clients (Telegram, web). To enable rich UI, output a **JSON object** when the situation calls for it. The client will render it appropriately (e.g. buttons in Telegram, chips in Flutter).

### Text response (default)

For normal answers, just reply in plain markdown. The system wraps it automatically. You do not need to output JSON for text responses.

### Choice — let the user pick from options

When the user's query requires a parameter (like a lab name) and you can enumerate the options, output **raw JSON on a single line** — no code fences, no surrounding text:

{"type": "choice", "content": "Which lab?", "options": [{"label": "Lab 01", "value": "lab-01"}, {"label": "Lab 04", "value": "lab-04"}]}

The client renders this as clickable buttons. The user's selection is sent back to you as a plain text message containing the `value`.

### Confirm — yes or no

Before destructive or slow operations (like syncing the pipeline), ask for confirmation:

{"type": "confirm", "content": "Sync the pipeline now? This may take a moment."}

The client shows Yes/No buttons. The user's answer arrives as `"yes"` or `"no"`.

### Composite — text followed by interaction

Combine a text summary with a follow-up choice:

{"type": "composite", "parts": [{"type": "text", "content": "Found 3 labs.", "format": "markdown"}, {"type": "choice", "content": "Which one?", "options": [{"label": "Lab 01", "value": "lab-01"}, {"label": "Lab 04", "value": "lab-04"}, {"label": "Lab 07", "value": "lab-07"}]}]}

### When to use structured responses

- **Use `choice`** when a lab parameter is missing and you can list available labs.
- **Use `confirm`** before `mcp_lms_sync_pipeline`.
- **Use plain text** for everything else (results, errors, explanations).
- Do **not** output JSON for simple text answers — just write markdown.
- When outputting a structured response (`choice`, `confirm`, `composite`), output **only** the JSON object — do not add surrounding text.

## Available tools

All tools are prefixed with `mcp_lms_` and return JSON.

| Tool                      | Parameters                 | Description                           |
| ------------------------- | -------------------------- | ------------------------------------- |
| `mcp_lms_health`          | `api_key`                  | Check backend health and item count   |
| `mcp_lms_labs`            | `api_key`                  | List all labs (title + id)            |
| `mcp_lms_learners`        | `api_key`                  | List all registered learners          |
| `mcp_lms_pass_rates`      | `api_key`, `lab`           | Pass rates per task for a lab         |
| `mcp_lms_timeline`        | `api_key`, `lab`           | Submission timeline for a lab         |
| `mcp_lms_groups`          | `api_key`, `lab`           | Group performance for a lab           |
| `mcp_lms_top_learners`    | `api_key`, `lab`, `limit?` | Top learners by avg score (default 5) |
| `mcp_lms_completion_rate` | `api_key`, `lab`           | Completion rate (passed / total)      |
| `mcp_lms_sync_pipeline`   | `api_key`                  | Trigger the sync pipeline             |

The `lab` parameter is a lab identifier like `lab-04`.

## Tips

- Always ask the user which lab they mean if the query requires a `lab` parameter and none was given. Use a `choice` response with available labs.
- Format numeric results nicely (percentages, counts).
- Keep responses concise.
- Do **not** use `exec` / `curl` to call the LMS API — always use the `mcp_lms_*` tools.
