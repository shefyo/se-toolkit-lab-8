"""WebChat channel plugin for nanobot — exposes a WebSocket server for web clients."""

from __future__ import annotations

import asyncio
import json
import uuid
from typing import Any
from urllib.parse import parse_qs, urlparse

import websockets
from loguru import logger
from pydantic import Field

from nanobot.bus.events import OutboundMessage
from nanobot.bus.queue import MessageBus
from nanobot.channels.base import BaseChannel
from nanobot.config.schema import Base


class WebChatConfig(Base):
    """WebChat channel configuration."""

    enabled: bool = False
    host: str = "0.0.0.0"
    port: int = 8765
    allow_from: list[str] = Field(default_factory=lambda: ["*"])


class WebChatChannel(BaseChannel):
    """WebSocket-based web chat channel.

    Each WebSocket connection is treated as an independent chat session.
    Protocol (JSON):
        Client -> Server:  {"content": "hello"}
        Server -> Client:  {"content": "response text"}

    Clients may pass an LMS API key via query parameter:
        ws://host:port?api_key=SECRET
    The key is prepended to every message so the agent can use it.
    """

    name = "webchat"
    display_name = "WebChat"

    @classmethod
    def default_config(cls) -> dict[str, Any]:
        return WebChatConfig().model_dump(by_alias=True)

    def __init__(self, config: Any, bus: MessageBus):
        if isinstance(config, dict):
            config = WebChatConfig.model_validate(config)
        super().__init__(config, bus)
        self.config: WebChatConfig = config
        # chat_id -> websocket connection
        self._connections: dict[str, websockets.WebSocketServerProtocol] = {}
        # chat_id -> api_key (if provided via query param)
        self._api_keys: dict[str, str] = {}
        self._server: websockets.WebSocketServer | None = None

    async def start(self) -> None:
        """Start the WebSocket server."""
        self._running = True
        logger.info("WebChat starting on {}:{}", self.config.host, self.config.port)
        self._server = await websockets.serve(
            self._handle_ws,
            self.config.host,
            self.config.port,
        )
        # Block until stopped
        while self._running:
            await asyncio.sleep(1)

    async def stop(self) -> None:
        """Stop the WebSocket server."""
        self._running = False
        if self._server:
            self._server.close()
            await self._server.wait_closed()
            self._server = None
        self._connections.clear()
        self._api_keys.clear()

    async def send(self, msg: OutboundMessage) -> None:
        """Send a message back to the client via its WebSocket.

        If the agent's content is valid JSON with a ``type`` field it is
        forwarded as-is (structured message).  Otherwise the content is
        wrapped in ``{"type": "text", "content": ..., "format": "markdown"}``.
        """
        ws = self._connections.get(msg.chat_id)
        if ws is None:
            logger.warning("WebChat: no connection for chat_id={}", msg.chat_id)
            return
        try:
            # Detect structured JSON from the agent
            payload: dict[str, Any] | None = None
            try:
                candidate = json.loads(msg.content)
                if isinstance(candidate, dict) and "type" in candidate:
                    payload = candidate
            except (json.JSONDecodeError, TypeError):
                pass

            if payload is None:
                payload = {
                    "type": "text",
                    "content": msg.content,
                    "format": "markdown",
                }

            await ws.send(json.dumps(payload))
        except websockets.ConnectionClosed:
            logger.info("WebChat: connection closed for chat_id={}", msg.chat_id)
            self._connections.pop(msg.chat_id, None)
            self._api_keys.pop(msg.chat_id, None)

    async def _handle_ws(self, ws: websockets.WebSocketServerProtocol) -> None:
        """Handle a single WebSocket connection lifecycle."""
        chat_id = str(uuid.uuid4())
        self._connections[chat_id] = ws
        sender_id = chat_id  # anonymous web user

        # Read api_key from query string (e.g. ws://host:port?api_key=SECRET)
        path: str = getattr(ws, "path", "") or ""  # pyright: ignore[reportUnknownArgumentType]
        qs = parse_qs(urlparse(path).query)
        api_key: str = qs.get("api_key", [""])[0]
        if api_key:
            self._api_keys[chat_id] = api_key

        logger.info(
            "WebChat: new connection chat_id={} auth={}", chat_id, bool(api_key)
        )

        try:
            async for raw in ws:
                try:
                    data = json.loads(raw)
                    content = data.get("content", "").strip()
                except (json.JSONDecodeError, AttributeError):
                    content = str(raw).strip()

                if not content:
                    continue

                # Inject per-session API key so the agent can use it
                key = self._api_keys.get(chat_id)
                if key:
                    content = f"[LMS_API_KEY={key}]\n{content}"

                await self._handle_message(
                    sender_id=sender_id,
                    chat_id=chat_id,
                    content=content,
                )
        except websockets.ConnectionClosed:
            pass
        finally:
            self._connections.pop(chat_id, None)
            self._api_keys.pop(chat_id, None)
            logger.info("WebChat: disconnected chat_id={}", chat_id)
