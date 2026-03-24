---
name: lms
description: Query the Learning Management System backend for labs, scores, learners, and analytics.
metadata: {"nanobot":{"emoji":"📚","requires":{"bins":["curl"],"env":["NANOBOT_LMS_BACKEND_URL"]},"always":true}}
---

# LMS (Learning Management System)

Query the LMS backend API. All endpoints require a Bearer token.

Base URL: `$NANOBOT_LMS_BACKEND_URL`

## Authentication

The user's message begins with `[LMS_API_KEY=<key>]`. Extract the key and use it as the Bearer token in all curl commands.

If the message does **not** contain `[LMS_API_KEY=...]`, tell the user they need to authenticate first (e.g. via `/login <api_key>` in the Telegram bot, or the login screen in the web app).

**Never include the API key in your responses to the user.**

## Structured responses

Your responses are rendered by different clients (Telegram, web). To enable rich UI, output a **JSON object** when the situation calls for it. The client will render it appropriately (e.g. buttons in Telegram, chips in Flutter).

### Text response (default)

For normal answers, just reply in plain markdown. The system wraps it automatically. You do not need to output JSON for text responses.

### Choice — let the user pick from options

When the user's query requires a parameter (like a lab name) and you can enumerate the options, output:

```json
{"type": "choice", "content": "Which lab?", "options": [{"label": "Lab 01", "value": "lab-01"}, {"label": "Lab 04", "value": "lab-04"}]}
```

The client renders this as clickable buttons. The user's selection is sent back to you as a plain text message containing the `value`.

### Confirm — yes or no

Before destructive or slow operations (like syncing the pipeline), ask for confirmation:

```json
{"type": "confirm", "content": "Sync the pipeline now? This may take a moment."}
```

The client shows Yes/No buttons. The user's answer arrives as `"yes"` or `"no"`.

### Composite — text followed by interaction

Combine a text summary with a follow-up choice:

```json
{"type": "composite", "parts": [{"type": "text", "content": "Found 3 labs.", "format": "markdown"}, {"type": "choice", "content": "Which one?", "options": [{"label": "Lab 01", "value": "lab-01"}, {"label": "Lab 04", "value": "lab-04"}, {"label": "Lab 07", "value": "lab-07"}]}]}
```

### When to use structured responses

- **Use `choice`** when a lab parameter is missing and you can list available labs.
- **Use `confirm`** before `sync_pipeline`.
- **Use plain text** for everything else (results, errors, explanations).
- Do **not** output JSON for simple text answers — just write markdown.

## API endpoints

### Health check

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/items/" | head -c 500
```

If the response is a JSON array, the backend is healthy. Count the items to report the item count.

### List labs

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/items/"
```

Filter results where `"type": "lab"`. Show their `title` and `id`.

### Pass rates for a lab

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/analytics/pass-rates?lab=LAB_ID"
```

Replace `LAB_ID` with the lab identifier (e.g., `lab-04`).

### List learners

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/learners/"
```

### Submission timeline

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/analytics/timeline?lab=LAB_ID"
```

### Group performance

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/analytics/groups?lab=LAB_ID"
```

### Top learners

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/analytics/top-learners?lab=LAB_ID&limit=5"
```

### Completion rate

```bash
curl -s -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/analytics/completion-rate?lab=LAB_ID"
```

### Sync pipeline

```bash
curl -s -X POST -H "Authorization: Bearer <key>" "$NANOBOT_LMS_BACKEND_URL/pipeline/sync"
```

## Tips

- Always ask the user which lab they mean if the query requires a `lab` parameter and none was given. Use a `choice` response with available labs.
- Format numeric results nicely (percentages, counts).
- Keep responses concise.
