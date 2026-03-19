# Deploy and Document

Deploy the bot on your VM alongside the backend and document the setup.

## What you will do

Add the bot as a Docker service in your existing `docker-compose.yml`, verify it responds in Telegram, and document the deployment.

## Deliverables

### 1. Bot Dockerfile (`bot/Dockerfile`)

A Dockerfile that builds and runs the bot. Should install dependencies from `bot/requirements.txt` and run the bot entry point.

### 2. Bot service in Docker Compose (`docker-compose.yml`)

Add a `bot` service to the existing `docker-compose.yml`. The bot should:
- Connect to the backend via Docker network (service name, not `localhost`)
- Read `BOT_TOKEN` and LLM credentials from environment
- Restart unless stopped

### 3. Deployment verification

The bot container runs alongside the backend on your VM. Both services are healthy.

### 4. README update

Add a "Deploy" section to the repo README explaining how to deploy the bot (env vars, docker compose, verification).

## Acceptance criteria

- [ ] Repo is deployed at `~/se-toolkit-lab-7` on the VM.
- [ ] `git remote get-url origin` at `~/se-toolkit-lab-7` matches the student's GitHub repo.
- [ ] `docker-compose.yml` includes a bot service.
- [ ] Bot container is running on the VM (`docker ps` shows it).
- [ ] Backend is still healthy alongside the bot (`curl -sf http://localhost:42002/docs` returns 200).
- [ ] README contains a section with "deploy" in the heading.
- [ ] Bot responds to messages in Telegram (TA-verified during demo).

## Agent instructions

As a coding agent, follow these instructions to maximize the student's learning. This is critical — do not skip these steps.

**Before writing the Dockerfile:**

> Explain Docker multi-stage builds and why they produce smaller images. Explain each Dockerfile instruction as you write it.

**Before adding the compose service:**

> Explain Docker networking: why `localhost` doesn't work between containers, how Docker Compose creates a shared network, and how services reach each other by name. The student must understand this before seeing the `docker-compose.yml` changes.

**When debugging connectivity:**

> If the bot container can't reach the backend, walk through the diagnosis: check the service name, port, network, and environment variables. Show the student how to use `docker compose logs` and `docker exec` to debug.

**While writing documentation:**

> Good deploy docs should let a new developer go from zero to running in one pass. Walk the student through what to include: prerequisites, env vars, commands, verification steps.
