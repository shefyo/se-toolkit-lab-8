# Client: `Telegram` bot

<h2>Table of contents</h2>

- [About the `Telegram` bot client](#about-the-telegram-bot-client)
- [Deploy the bot on the VM](#deploy-the-bot-on-the-vm)
  - [Configure the environment (REMOTE)](#configure-the-environment-remote)
  - [Start the bot](#start-the-bot)
    - [Start the bot via `uv run python`](#start-the-bot-via-uv-run-python)
    - [Start the bot via `uv run poe`](#start-the-bot-via-uv-run-poe)
    - [Start the bot via `Docker Compose`](#start-the-bot-via-docker-compose)
  - [Check the bot](#check-the-bot)
    - [Check the bot via `uv run python`](#check-the-bot-via-uv-run-python)
    - [Check the bot via `uv run poe`](#check-the-bot-via-uv-run-poe)
    - [Check the bot in `Telegram`](#check-the-bot-in-telegram)

## About the `Telegram` bot client

The `Telegram` bot client is a standalone [Python](./python.md#about-python) service built with `aiogram` that connects the [`Telegram`](./bot.md#about-telegram-bots) messaging interface to the [`Nanobot`](./nanobot.md#about-nanobot) AI agent.

The source code is in the [`client-telegram-bot/`](../client-telegram-bot/) directory.

Docs:

- [aiogram documentation](https://docs.aiogram.dev/en/latest/)

## Deploy the bot on the VM

1. [Connect to the VM as the user `admin` (LOCAL)](./vm-access.md#connect-to-the-vm-as-the-user-user-local).
2. [Install `uv` (REMOTE)](./python.md#install-uv).
3. [Set up the lab repository directory (REMOTE)](./lab.md#set-up-the-lab-repository-directory).
4. [Configure the environment (REMOTE)](#configure-the-environment-remote).
5. [Start the bot (REMOTE)](#start-the-bot).
6. [Check the bot (REMOTE)](#check-the-bot-via-uv-run-poe).
7. [Check the bot in `Telegram`](#check-the-bot-in-telegram).

### Configure the environment (REMOTE)

1. To open [`.env.docker.secret`](./dotenv-docker-secret.md#what-is-envdockersecret) for editing,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   nano .env.docker.secret
   ```

2. [Set the variables in `.env.docker.secret`](./environments.md#set-the-variable-to-value-in-the-env-file-at-file-path):

   - [`BOT_TOKEN`](./dotenv-docker-secret.md#bot_token)
   - [`LMS_API_BASE_URL`](./dotenv-docker-secret.md#lms_api_base_url)
   - [`LMS_API_KEY`](./dotenv-docker-secret.md#lms_api_key)
   - [`LLM_API_KEY`](./dotenv-docker-secret.md#llm_api_key)
   - [`LLM_API_BASE_URL`](./dotenv-docker-secret.md#llm_api_base_url)
   - [`LLM_API_MODEL`](./dotenv-docker-secret.md#llm_api_model)

3. Save and close the file.

### Start the bot

<!-- no toc -->
- Method 1: [Start the bot via `uv run python`](#start-the-bot-via-uv-run-python)
- Method 2: [Start the bot via `uv run poe`](#start-the-bot-via-uv-run-poe)
- Method 3: [Start the bot via `Docker Compose`](#start-the-bot-via-docker-compose)

#### Start the bot via `uv run python`

1. To start the bot,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   uv run --env-file .env.docker.secret python bot/bot.py
   ```

   See [`.env.docker.secret`](./dotenv-docker-secret.md).

#### Start the bot via `uv run poe`

1. To start the bot,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   uv run poe bot
   ```

   This loads the environment variables from [`.env.docker.secret`](./dotenv-docker-secret.md) automatically.

#### Start the bot via `Docker Compose`

1. To start the bot,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   docker compose up --env-file .env.docker.secret bot --build -d
   ```

### Check the bot

- Method 1: [Check the bot via `uv run python`](#check-the-bot-via-uv-run-python)
- Method 2: [Check the bot via `uv run poe`](#check-the-bot-via-uv-run-poe)
- Method 3: [Check the bot in `Telegram`](#check-the-bot-in-telegram)

#### Check the bot via `uv run python`

1. To check that the bot is working,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   uv run --env-file .env.docker.secret python bot/bot.py --test "/health"
   ```

   You should see a response from the bot.

#### Check the bot via `uv run poe`

1. To check that the bot is working,

   [run in the `VS Code Terminal`](./vs-code.md#run-a-command-in-the-vs-code-terminal):

   ```terminal
   uv run poe bot-test "/health"
   ```

   This loads the environment variables from [`.env.docker.secret`](./dotenv-docker-secret.md) automatically.

   You should see a response from the bot.

#### Check the bot in `Telegram`

1. Open `Telegram`.

2. Find your bot by [your bot username](./bot.md#your-bot-username).

3. Send `/health`.

   You should see a response from your bot.
