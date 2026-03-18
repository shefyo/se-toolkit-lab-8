# Backend Integration

Connect your bot to the LMS backend with real data commands. After this task, the bot fetches live data from your deployed backend and formats it for the user.

## What you will build

Working implementations of `/start`, `/help`, `/health`, and at least 2 data commands that call the LMS backend API. All verifiable via `--test` mode.

```terminal
$ python bot/bot.py --test "/health"
Backend is healthy. 42 items available.

$ python bot/bot.py --test "/labs"
Available labs:
- Lab 01 — Products, Architecture & Roles
- Lab 02 — Run, Fix, and Deploy
- Lab 03 — Backend API
...
```

## Available backend endpoints

Your LMS backend (running on `localhost:42002` via Caddy) provides these endpoints. All require `Authorization: Bearer YOUR_LMS_API_KEY`.

| Endpoint | What it returns |
|----------|----------------|
| `GET /items/` | Course structure (labs, tasks) |
| `GET /learners/` | Enrolled students |
| `GET /interactions/` | Submission logs |
| `GET /analytics/scores?lab=lab-01` | Score distribution (4 buckets) |
| `GET /analytics/pass-rates?lab=lab-01` | Per-task average scores |
| `GET /analytics/timeline?lab=lab-01` | Submissions per day |
| `GET /analytics/groups?lab=lab-01` | Per-group performance |
| `GET /analytics/top-learners?lab=lab-01&limit=5` | Top N learners |
| `GET /analytics/completion-rate?lab=lab-01` | Completion percentage |
| `POST /pipeline/sync` | Trigger ETL sync |

> [!TIP]
> Explore these endpoints in Swagger UI at `http://localhost:42002/docs` to understand the response format before implementing bot commands.

## Suggested data commands

Pick at least 2 from this list (or define your own):

| Command | Backend endpoint | What it shows |
|---------|-----------------|---------------|
| `/labs` | `GET /items/` | List of available labs |
| `/scores <lab>` | `GET /analytics/pass-rates?lab=` | Per-task pass rates |
| `/timeline <lab>` | `GET /analytics/timeline?lab=` | Submissions over time |
| `/groups <lab>` | `GET /analytics/groups?lab=` | Per-group performance |
| `/top [lab] [N]` | `GET /analytics/top-learners?lab=&limit=` | Top N learners |
| `/learners` | `GET /learners/` | Enrolled learner count/list |
| `/sync` | `POST /pipeline/sync` | Trigger ETL, show result |

## Error handling

When the backend is unreachable or returns an error, the bot must show a user-friendly message — not a Python traceback. Example:

```terminal
$ python bot/bot.py --test "/health"
Backend is not responding. Check that the services are running.
```

## Deliverables

### 1. `/start` command

Returns a welcome message with the bot's name or description. Must contain the word "welcome" or the bot's name (case-insensitive).

### 2. `/help` command

Lists all available commands with descriptions. Must include at least 4 `/command` entries.

### 3. `/health` command

Calls `GET /items/` on the backend. Reports healthy/unhealthy status. Hits the real backend on `localhost:42002`.

### 4. At least 2 data commands

Each calls a different backend endpoint and returns formatted data. The response must be non-empty when the database has data (ETL has been synced).

### 5. Error handling

When the backend is down, commands return a user-friendly error message — no `Traceback` in stderr.

## Acceptance criteria

- [ ] `--test "/start"` returns text containing "welcome" or the bot name (case-insensitive).
- [ ] `--test "/help"` output lists at least 4 commands (lines matching `/command`).
- [ ] `--test "/health"` returns a status indicator ("healthy", "ok", "available", or similar).
- [ ] First data command returns non-empty structured output (at least 2 lines).
- [ ] Second data command returns non-empty output.
- [ ] When backend is stopped, `--test "/health"` returns a user-friendly message with no `Traceback` in stderr.
- [ ] Changes follow the Git workflow (issue, branch, PR, review, merge).
