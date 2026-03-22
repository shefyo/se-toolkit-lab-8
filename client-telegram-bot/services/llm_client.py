"""LLM client for natural language intent routing."""

import httpx
from typing import Any


class LLMClient:
    """Client for the LLM API (Qwen Code API)."""

    def __init__(self, api_key: str, base_url: str, model: str):
        self.api_key = api_key
        self.base_url = base_url.rstrip("/")
        self.model = model
        self._headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

    def _get_client(self) -> httpx.AsyncClient:
        """Create an async HTTP client with auth headers."""
        return httpx.AsyncClient(headers=self._headers, timeout=30.0)

    async def chat(self, messages: list[dict[str, str]], tools: list[dict[str, Any]] | None = None) -> dict[str, Any]:
        """Send a chat completion request to the LLM."""
        async with self._get_client() as client:
            payload: dict[str, Any] = {
                "model": self.model,
                "messages": messages,
            }
            if tools:
                payload["tools"] = tools
                payload["tool_choice"] = "auto"
            
            response = await client.post(
                f"{self.base_url}/chat/completions",
                json=payload,
            )
            response.raise_for_status()
            return response.json()

    async def complete(self, prompt: str, system_prompt: str = "") -> str:
        """Send a simple completion request and return the text response."""
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        response = await self.chat(messages)
        return response["choices"][0]["message"]["content"]
