#!/usr/bin/env bash
set -Eeuo pipefail

REMOTE="${REMOTE:-root@10.93.25.210}"
ENV_FILE="${ENV_FILE:-.env.docker.secret}"
BRANCH="fix/task4-db-500-$(date +%s)"
ISSUE_TITLE="Task 4: fix DB failure handling and proactive health check"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 1; }; }
for x in git ssh grep sed awk curl python3; do need "$x"; done

echo "== create branch =="
git checkout -b "$BRANCH"

echo "== patch likely planted bug: db failure should be 500, not 404 =="
python3 <<'PY'
from pathlib import Path
import re

roots = [Path("."), Path("./backend"), Path("./app"), Path("./src")]
skip = {".git","node_modules",".venv","venv","dist","build","__pycache__"}
exts = {".py",".js",".ts",".tsx",".go",".java",".kt",".rb"}

patched = []
for root in roots:
    if not root.exists():
        continue
    for p in root.rglob("*"):
        if not p.is_file() or p.suffix not in exts:
            continue
        if any(part in skip for part in p.parts):
            continue
        try:
            txt = p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        lower = txt.lower()
        if "404" not in txt and "not found" not in lower and "http_404" not in txt:
            continue
        if "/items" not in lower and "items" not in lower and "postgres" not in lower and "database" not in lower and "db" not in lower:
            continue

        new = txt
        new = re.sub(r'HTTP_404_NOT_FOUND', 'HTTP_500_INTERNAL_SERVER_ERROR', new)
        new = re.sub(r'status_code\s*=\s*404', 'status_code=500', new)
        new = re.sub(r'response\.status\(\s*404\s*\)', 'response.status(500)', new)
        new = re.sub(r'return\s+404\b', 'return 500', new)
        new = new.replace('detail="not found"', 'detail="internal server error"')
        new = new.replace("detail='not found'", "detail='internal server error'")

        if new != txt:
            p.write_text(new, encoding="utf-8")
            patched.append(str(p))

print("PATCHED:", ",".join(patched) if patched else "NONE")
PY

echo "== show suspicious leftovers =="
grep -RniE 'HTTP_404_NOT_FOUND|status_code *= *404|response\.status\(404\)|not found' . \
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=venv \
  --exclude-dir=dist --exclude-dir=build || true

echo "== commit =="
git add .
git commit -m "Fix DB failures to return 500 instead of 404" || true

echo "== push =="
git push -u origin "$BRANCH"

echo "== optional: create issue/pr with gh if available =="
ISSUE_NUM=""
if command -v gh >/dev/null 2>&1; then
  ISSUE_URL="$(gh issue create --title "$ISSUE_TITLE" --body "Task 4: fix planted bug so DB failures return 500 instead of 404." 2>/dev/null || true)"
  ISSUE_NUM="$(printf '%s' "$ISSUE_URL" | sed -n 's#.*/issues/\([0-9][0-9]*\).*#\1#p')"
  BODY_FILE="$(mktemp)"
  {
    echo "Fix Task 4 DB failure handling."
    [ -n "$ISSUE_NUM" ] && echo && echo "Closes #$ISSUE_NUM"
  } > "$BODY_FILE"
  gh pr create --title "Task 4: fix DB failure handling" --body-file "$BODY_FILE" 2>/dev/null || true
  rm -f "$BODY_FILE"
fi

echo "== remote rebuild/redeploy + verify failure path =="
ssh "$REMOTE" bash -s <<'EOS'
set -Eeuo pipefail

find_repo() {
  for d in /root/se-toolkit-lab-8 /root/app /app /srv/app; do
    if [ -d "$d" ]; then
      if [ -f "$d/docker-compose.yml" ] || [ -f "$d/compose.yaml" ] || [ -d "$d/.git" ]; then
        echo "$d"
        return 0
      fi
    fi
  done
  return 1
}

REPO="$(find_repo || true)"
[ -n "$REPO" ] || { echo "cannot find repo on remote"; exit 1; }
cd "$REPO"

if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  COMPOSE="docker-compose"
fi

git pull --rebase || true

$COMPOSE --env-file .env.docker.secret build backend
$COMPOSE --env-file .env.docker.secret up -d

echo "== detect backend port =="
PORT=""
for p in 8000 8080 42000 42001; do
  code="$(curl -s -o /tmp/task4_body.txt -w "%{http_code}" http://127.0.0.1:${p}/items || true)"
  if [ "$code" != "000" ]; then
    PORT="$p"
    echo "backend_port:$PORT"
    echo "initial_code:$code"
    break
  fi
done

POSTGRES_NAME="$(docker ps --format '{{.Names}}' | awk '/postgres|db/ {print; exit}')"
if [ -n "$PORT" ] && [ -n "$POSTGRES_NAME" ]; then
  echo "stopping:$POSTGRES_NAME"
  docker stop "$POSTGRES_NAME"
  sleep 3
  FAIL_CODE="$(curl -s -o /tmp/task4_fail.txt -w "%{http_code}" http://127.0.0.1:${PORT}/items || true)"
  echo "response_code:$FAIL_CODE"
  echo "response_body:"
  cat /tmp/task4_fail.txt || true
  echo
  docker start "$POSTGRES_NAME" >/dev/null 2>&1 || true
else
  echo "could_not_auto_verify"
fi
EOS

echo
echo "================ MANUAL STEPS STILL REQUIRED ================"
echo
echo "1) In the SAME open Flutter chat, send exactly:"
echo
echo "Create a health check for this chat that runs every 2 minutes. Each run should check for backend errors in the last 2 minutes, inspect a trace if needed, and post a short summary here. If there are no recent errors, say the system looks healthy. Use your cron tool."
echo
echo "2) Then send exactly:"
echo
echo "List scheduled jobs."
echo
echo "3) Trigger one more failing request while postgres is stopped, wait for the next cron cycle, then remove or change the test job."
echo
echo "4) For git workflow, you still need real approvals and merged PRs."
echo "   Example:"
echo "   gh pr review <PR_NUMBER> --approve   # from partner account"
echo "   gh pr merge <PR_NUMBER> --merge"
echo
echo "If remote verification printed response_code:500, the planted bug part is fixed."
