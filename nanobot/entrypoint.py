import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONFIG_IN = ROOT / "config.json"
CONFIG_OUT = ROOT / "config.resolved.json"

def set_path(obj, path, value):
    cur = obj
    for key in path[:-1]:
        if key not in cur or not isinstance(cur[key], dict):
            cur[key] = {}
        cur = cur[key]
    cur[path[-1]] = value

with CONFIG_IN.open() as f:
    cfg = json.load(f)

workspace = cfg.get("agents", {}).get("defaults", {}).get("workspace", "./workspace")

if os.environ.get("LLM_API_KEY"):
    set_path(cfg, ["providers", "custom", "apiKey"], os.environ["LLM_API_KEY"])
if os.environ.get("LLM_API_BASE_URL"):
    set_path(cfg, ["providers", "custom", "apiBase"], os.environ["LLM_API_BASE_URL"])
if os.environ.get("LLM_API_MODEL"):
    set_path(cfg, ["agents", "defaults", "model"], os.environ["LLM_API_MODEL"])

channels = cfg.setdefault("channels", {})
webchat = channels.setdefault("webchat", {})
webchat["enabled"] = True
webchat["allow_from"] = ["*"]
if os.environ.get("NANOBOT_WEBCHAT_HOST"):
    webchat["host"] = os.environ["NANOBOT_WEBCHAT_HOST"]
if os.environ.get("NANOBOT_WEBCHAT_CONTAINER_PORT"):
    webchat["port"] = int(os.environ["NANOBOT_WEBCHAT_CONTAINER_PORT"])
if os.environ.get("NANOBOT_ACCESS_KEY"):
    webchat["access_key"] = os.environ["NANOBOT_ACCESS_KEY"]

mcp = cfg.setdefault("tools", {}).setdefault("mcpServers", {}).setdefault("lms", {})
mcp["command"] = "python"
mcp["args"] = ["-m", "mcp_lms"]
env = mcp.setdefault("env", {})
if os.environ.get("NANOBOT_LMS_BACKEND_URL"):
    env["NANOBOT_LMS_BACKEND_URL"] = os.environ["NANOBOT_LMS_BACKEND_URL"]
if os.environ.get("NANOBOT_LMS_API_KEY"):
    env["NANOBOT_LMS_API_KEY"] = os.environ["NANOBOT_LMS_API_KEY"]

with CONFIG_OUT.open("w") as f:
    json.dump(cfg, f, indent=2)

os.execv(sys.executable, [
    sys.executable,
    "-m",
    "nanobot",
    "gateway",
    "--config",
    str(CONFIG_OUT),
    "--workspace",
    workspace,
])
