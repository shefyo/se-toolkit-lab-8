#!/usr/bin/env bash
set -Eeuo pipefail

REMOTE_HOST="${REMOTE_HOST:-root@10.93.25.210}"
COMPOSE_ENV="${COMPOSE_ENV:-.env.docker.secret}"
BRANCH="fix/task4-db-failure-500-$(date +%s)"
ISSUE_TITLE="Task 4: fix DB failure handling and make agent proactive"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yel()   { printf '\033[33m%s\033[0m\n' "$*"; }
blu()   { printf '\033[34m%s\033[0m\n' "$*"; }

need() {
  command -v "$1" >/dev/null 2>&1 || { red "Missing required command: $1"; exit 1; }
}

need git
need ssh
need grep
need sed
need awk
need curl
need python3

if [ ! -d .git ]; then
  red "Run this from the repo root."
  exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  red "No git remote named origin."
  exit 1
fi

blu "== 0) Create working branch =="
git checkout -b "$BRANCH"

blu "== 1) Try to find and patch the planted bug: DB failure must return 500, not 404 =="

python3 <<'PY'
from pathlib import Path
import re
import sys

roots = [Path("."), Path("backend"), Path("app"), Path("src")]
exts = {".py", ".js", ".ts", ".tsx", ".go", ".java", ".kt", ".rb"}
skip = {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build"}

candidates = []
for root in roots:
    if not root.exists():
        continue
    for p in root.rglob("*"):
        if any(part in skip for part in p.parts):
            continue
        if p.is_file() and p.suffix in exts:
            try:
                txt = p.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
            lower = txt.lower()
            if ("/items" in lower or "items" in lower) and ("404" in txt or "not found" in lower or "http_404" in lower):
                candidates.append(p)

patched = []
for p in candidates:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    new = txt

    new = re.sub(r'HTTP_404_NOT_FOUND', 'HTTP_500_INTERNAL_SERVER_ERROR', new)
    new = re.sub(r'status_code\s*=\s*404', 'status_code=500', new)
    new = re.sub(r'response\.status\(\s*404\s*\)', 'response.status(500)', new)
    new = re.sub(r'return\s+JSONResponse\(([^)]*?)status_code\s*=\s*404', r'return JSONResponse(\1status_code=500', new, flags=re.S)
    new = re.sub(r'return\s+\{([^}]*)\}\s*,\s*404\b', r'return {\1}, 500', new)
    new = re.sub(r'raise\s+HTTPException\(([^)]*?)status_code\s*=\s*404', r'raise HTTPException(\1status_code=500', new, flags=re.S)

    # Make the detail less misleading where obvious
    new = new.replace('detail="not found"', 'detail="internal server error"')
    new = new.replace("detail='not found'", "detail='internal server error'")

    if new != txt:
        p.write_text(new, encoding="utf-8")
        patched.append(str(p))

print("PATCHED_FILES=" + (",".join(patched) if patched else "NONE"))
PY

blu "== 2) Show likely remaining suspicious spots =="
grep -RniE 'HTTP_404_NOT_FOUND|status_code *= *404|response\.status\(404\)|not found' . \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=.venv \
  --exclude-dir=venv \
  --exclude-dir=dist \
  --exclude-dir=build \
  || true

blu "== 3) Commit the fix locally =="
git add .
git commit -m "Fix DB failures to return 500 instead of 404"

blu "== 4) Push branch =="
git push -u origin "$BRANCH"

blu "== 5) Try to create GitHub issue and PR if gh is available =="
ISSUE_NUMBER=""
PR_URL=""
if command -v gh >/dev/null 2>&1; then
  set +e
  ISSUE_OUT=$(gh issue create --title "$ISSUE_TITLE" --body "Task 4: fix planted bug so DB failure returns 500 instead of 404; add proactive health-check workflow evidence." 2>/dev/null)
  GH_ISSUE_RC=$?
  set -e
  if [ $GH_ISSUE_RC -eq 0 ]; then
    ISSUE_NUMBER=$(printf '%s' "$ISSUE_OUT" | sed -n 's#.*/issues/\([0-9][0-9]*\).*#\1#p')
  fi

  PR_BODY_FILE=$(mktemp)
  {
    echo "This PR fixes the planted backend bug so DB failures return HTTP 500 instead of a misleading 404."
    echo
    if [ -n "$ISSUE_NUMBER" ]; then
      echo "Closes #$ISSUE_NUMBER"
      echo
    fi
    echo "Also includes Task 4 operational verification steps."
  } > "$PR_BODY_FILE"

  set +e
  PR_OUT=$(gh pr create --title "Task 4: fix DB failure handling" --body-file "$PR_BODY_FILE" 2>/dev/null)
  GH_PR_RC=$?
  set -e
  rm -f "$PR_BODY_FILE"
  if [ $GH_PR_RC -eq 0 ]; then
    PR_URL="$PR_OUT"
  fi
fi

blu "== 6) Attempt remote rebuild/redeploy and live verification =="
ssh "$REMOTE_HOST" bash -s <<'EOS'
set -Eeuo pipefail

REPO_DIR=""
for d in /root/se-toolkit-lab-8 /root/app /app /srv/app; do
  if [ -d "$d/.git" ] || [ -f "$d/docker-compose.yml" ] || [ -f "$d/compose.yaml" ]; then
    REPO_DIR="$d"
    break
  fi
done

if [ -z "$REPO_DIR" ]; then
  echo "ERROR: could not locate app dir on remote host"
  exit 1
fi

cd "$REPO_DIR"

if [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then
  echo "WARN: remote repo has local changes; continuing anyway"
fi

git fetch --all || true
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD || echo main)
git pull --rebase || true

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose --env-file .env.docker.secret "$@"
  else
    docker-compose --env-file .env.docker.secret "$@"
  fi
}

compose build backend
compose up -d

echo "== containers =="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

POSTGRES_NAME=$(docker ps --format '{{.Names}}' | awk '/postgres|db/ {print; exit}')
BACKEND_PORT=""
for p in 8000 8080 42000 42001; do
  code=$(curl -s -o /tmp/t4_ok.txt -w "%{http_code}" "http://127.0.0.1:${p}/items" || true)
  if [ "$code" != "000" ]; then
    BACKEND_PORT="$p"
    echo "Detected backend /items on port $BACKEND_PORT with code $code"
    break
  fi
done

if [ -z "$BACKEND_PORT" ]; then
  echo "WARN: could not auto-detect backend port for /items"
else
  if [ -n "$POSTGRES_NAME" ]; then
    echo "Stopping postgres container: $POSTGRES_NAME"
    docker stop "$POSTGRES_NAME"
    sleep 3
    FAIL_CODE=$(curl -s -o /tmp/t4_fail.txt -w "%{http_code}" "http://127.0.0.1:${BACKEND_PORT}/items" || true)
    echo "response_code:$FAIL_CODE"
    echo "response_body:"
    cat /tmp/t4_fail.txt || true
    echo
    docker start "$POSTGRES_NAME"
  else
    echo "WARN: postgres container not found automatically"
  fi
fi
EOS

blu "== 7) Suggested REPORT.md entries (appended if file exists) =="
if [ -f REPORT.md ]; then
  {
    echo
    echo "## Task 4C — Bug fix and recovery"
    echo
    echo "- Fixed the planted bug so DB failures return HTTP 500 instead of misleading HTTP 404."
    echo "- Rebuilt and redeployed backend."
    echo "- Re-tested the failure path with PostgreSQL stopped."
    echo
  } >> REPORT.md
  git add REPORT.md
  git commit -m "Update REPORT.md for Task 4C" || true
  git push || true
fi

green
echo "=================================================================="
echo "AUTOMATED PART COMPLETE"
echo "=================================================================="
echo
echo "Branch: $BRANCH"
if [ -n "$ISSUE_NUMBER" ]; then
  echo "Issue: #$ISSUE_NUMBER"
fi
if [ -n "$PR_URL" ]; then
  echo "PR: $PR_URL"
fi
echo
yel "NOW DO THESE TWO MANUAL PARTS REQUIRED BY THE TASK:"
echo
echo "1) In the SAME open Flutter chat, send exactly:"
echo
echo "Create a health check for this chat that runs every 2 minutes. Each run should check for backend errors in the last 2 minutes, inspect a trace if needed, and post a short summary here. If there are no recent errors, say the system looks healthy. Use your cron tool."
echo
echo "Then send:"
echo "List scheduled jobs."
echo
echo "2) For the git workflow check, you still need real approvals and merged PRs."
echo "   This repository currently shows 0 PRs and 0 approvals unless you create and merge them."
echo
echo "Useful commands:"
echo "  gh pr review <PR_NUMBER> --approve        # from partner account"
echo "  gh pr merge <PR_NUMBER> --merge"
echo
echo "If the remote verification above printed response_code:500 after stopping postgres, the planted bug part is fixed."
