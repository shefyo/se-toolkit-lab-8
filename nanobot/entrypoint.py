"""Resolve runtime env vars into MCP server configs, then start the gateway."""

import json
import os
import sys
import tempfile

CONFIG = "/app/nanobot/config.json"
WORKSPACE = "/app/nanobot/workspace"

# Env vars to forward into every MCP server subprocess.
_FORWARD_VARS = ["NANOBOT_LMS_BACKEND_URL"]


def main() -> None:
    with open(CONFIG) as f:
        config = json.load(f)

    mcp_servers = config.get("tools", {}).get("mcp_servers", {})
    if mcp_servers:
        forward = {k: v for k in _FORWARD_VARS if (v := os.environ.get(k))}
        for srv in mcp_servers.values():
            env = srv.get("env", {})
            env.update(forward)
            srv["env"] = env

    with tempfile.NamedTemporaryFile(
        "w", suffix=".json", delete=False, dir="/tmp"
    ) as f:
        json.dump(config, f, indent=2)
        resolved = f.name

    os.execvp("nanobot", [
        "nanobot", "gateway",
        "--config", resolved,
        "--workspace", WORKSPACE,
    ])


if __name__ == "__main__":
    main()
