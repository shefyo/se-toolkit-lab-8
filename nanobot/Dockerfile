FROM ghcr.io/astral-sh/uv:python3.12-bookworm
WORKDIR /app
COPY --from=workspace . /app
WORKDIR /app/nanobot
RUN uv sync
RUN uv pip install -e /app/mcp
RUN uv pip install -e /app/nanobot-websocket-channel/nanobot-webchat
ENV PATH="/app/nanobot/.venv/bin:$PATH"
CMD ["uv", "run", "python", "/app/nanobot/entrypoint.py"]
