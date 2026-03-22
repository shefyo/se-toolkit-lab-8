"""LMS API client for fetching data from the backend."""

import httpx
from typing import Any


class LMSClient:
    """Client for the LMS backend API."""

    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self._headers = {"Authorization": f"Bearer {api_key}"}

    def _get_client(self) -> httpx.AsyncClient:
        """Create an async HTTP client with auth headers."""
        return httpx.AsyncClient(headers=self._headers, timeout=10.0)

    async def health_check(self) -> dict[str, Any]:
        """Check if the backend is healthy and get item count."""
        async with self._get_client() as client:
            try:
                response = await client.get(f"{self.base_url}/items/")
                response.raise_for_status()
                items = response.json()
                return {
                    "status": "healthy",
                    "item_count": len(items) if isinstance(items, list) else "unknown",
                }
            except httpx.ConnectError as e:
                return {"status": "unhealthy", "error": f"connection refused ({self.base_url}). Check that the services are running."}
            except httpx.HTTPStatusError as e:
                return {"status": "unhealthy", "error": f"HTTP {e.response.status_code} {e.response.reason_phrase}. The backend service may be down."}
            except Exception as e:
                return {"status": "unhealthy", "error": str(e)}

    async def get_items(self) -> list[dict[str, Any]]:
        """Get all items (labs and tasks) from the backend."""
        async with self._get_client() as client:
            response = await client.get(f"{self.base_url}/items/")
            response.raise_for_status()
            return response.json()

    async def get_learners(self) -> list[dict[str, Any]]:
        """Get all enrolled learners."""
        async with self._get_client() as client:
            response = await client.get(f"{self.base_url}/learners/")
            response.raise_for_status()
            return response.json()

    async def get_pass_rates(self, lab: str) -> list[dict[str, Any]]:
        """Get pass rates for a specific lab."""
        async with self._get_client() as client:
            response = await client.get(
                f"{self.base_url}/analytics/pass-rates",
                params={"lab": lab},
            )
            response.raise_for_status()
            return response.json()

    async def get_scores(self, lab: str) -> list[dict[str, Any]]:
        """Get score distribution for a specific lab."""
        async with self._get_client() as client:
            response = await client.get(
                f"{self.base_url}/analytics/scores",
                params={"lab": lab},
            )
            response.raise_for_status()
            return response.json()

    async def get_timeline(self, lab: str) -> list[dict[str, Any]]:
        """Get submission timeline for a specific lab."""
        async with self._get_client() as client:
            response = await client.get(
                f"{self.base_url}/analytics/timeline",
                params={"lab": lab},
            )
            response.raise_for_status()
            return response.json()

    async def get_groups(self, lab: str) -> list[dict[str, Any]]:
        """Get per-group performance for a specific lab."""
        async with self._get_client() as client:
            response = await client.get(
                f"{self.base_url}/analytics/groups",
                params={"lab": lab},
            )
            response.raise_for_status()
            return response.json()

    async def get_top_learners(self, lab: str, limit: int = 5) -> list[dict[str, Any]]:
        """Get top learners for a specific lab."""
        async with self._get_client() as client:
            response = await client.get(
                f"{self.base_url}/analytics/top-learners",
                params={"lab": lab, "limit": limit},
            )
            response.raise_for_status()
            return response.json()

    async def get_completion_rate(self, lab: str) -> dict[str, Any]:
        """Get completion rate for a specific lab."""
        async with self._get_client() as client:
            response = await client.get(
                f"{self.base_url}/analytics/completion-rate",
                params={"lab": lab},
            )
            response.raise_for_status()
            return response.json()

    async def sync_pipeline(self) -> dict[str, Any]:
        """Trigger ETL pipeline sync."""
        async with self._get_client() as client:
            response = await client.post(f"{self.base_url}/pipeline/sync")
            response.raise_for_status()
            return response.json()
