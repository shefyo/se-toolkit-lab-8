import httpx
import json
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("observability")

# Порты из Docker Compose стека
VLOGS_URL = "http://localhost:9428/select/logsql/query"
VTRACES_URL = "http://localhost:10428/jaeger/api/traces"

@mcp.tool()
async def logs_search(query: str, limit: int = 15):
    """
    Search logs using LogsQL. 
    Example query: '_stream:{service="backend"} AND level:error'
    """
    async with httpx.AsyncClient() as client:
        params = {"query": query, "limit": limit}
        response = await client.get(VLOGS_URL, params=params)
        return response.text

@mcp.tool()
async def traces_list(service: str = "backend", limit: int = 5):
    """List recent traces to identify failing request IDs."""
    async with httpx.AsyncClient() as client:
        params = {"service": service, "limit": limit}
        response = await client.get(VTRACES_URL, params=params)
        return response.json()

@mcp.tool()
async def traces_get(trace_id: str):
    """Get full span hierarchy for a specific trace_id found in logs."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{VTRACES_URL}/{trace_id}")
        return response.json()
