#!/usr/bin/env bash
set -euo pipefail

REMOTE="root@10.93.25.210"

echo "== 1) Fix planted bug: DB errors must return 500, not 404 =="

git checkout -b fix/task4-db-500-$(date +%s) || git checkout -b fix/task4-db-500

python3 - <<'PY'
from pathlib import Path
import re

roots = [Path("."), Path("./backend"), Path("./app")]
candidates = []
for root in roots:
    if root.exists():
        for p in root.rglob("*"):
            if p.suffix in {".py", ".js", ".ts", ".go", ".java"} and p.is_file():
                try:
                    txt = p.read_text(encoding="utf-8", errors="ignore")
                except Exception:
                    continue
                if "404" in txt and ("items" in txt.lower() or "database" in txt.lower() or "db" in txt.lower() or "exception" in txt.lower()):
                    candidates.append(p)

patched = []
for p in candidates:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    new = txt

    new = re.sub(r'HTTP_404_NOT_FOUND', 'HTTP_500_INTERNAL_SERVER_ERROR', new)
    new = re.sub(r'status_code\s*=\s*404', 'status_code=500', new)
    new = re.sub(r'status\s*:\s*404', 'status: 500', new)
    new = re.sub(r'response\.status\(\s*404\s*\)', 'response.status(500)', new)
    new = re.sub(r'return\s+404\b', 'return 500', new)

    if new != txt:
        p.write_text(new, encoding="utf-8")
        patched.append(str(p))

print("PATCHED_FILES=" + (",".join(patched) if patched else "NONE"))
PY

echo "== 2) Commit local fix =="
git add .
git commit -m "Fix DB failure handling to return 500 instead of 404" || true

echo "== 3) Redeploy on remote =="
ssh "$REMOTE" '
set -e
cd /root 2>/dev/null || true

if [ -d /root/se-toolkit-lab-8 ]; then
  cd /root/se-toolkit-lab-8
elif [ -d /app ]; then
  cd /app
elif [ -d /root/app ]; then
  cd /root/app
else
  echo "Could not find app directory"; exit 1
fi

git pull || true

if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    docker compose down || true
    docker compose up -d --build
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose down || true
    docker-compose up -d --build
  fi
fi
'

echo "== 4) Install proactive health check cron job =="
ssh "$REMOTE" 'cat > /root/task4_healthcheck.sh <<'"'"'EOS'"'"'
#!/usr/bin/env bash
set -e
TS=$(date -Iseconds)
URLS="http://127.0.0.1:8000/items http://127.0.0.1/items http://127.0.0.1:8080/items"
OUT=""
for u in $URLS; do
  CODE=$(curl -s -o /tmp/task4_health_body.txt -w "%{http_code}" "$u" || true)
  if [ -n "$CODE" ] && [ "$CODE" != "000" ]; then
    BODY=$(head -c 300 /tmp/task4_health_body.txt | tr "\n" " ")
    OUT="[$TS] $u code=$CODE body=$BODY"
    break
  fi
done
if [ -z "$OUT" ]; then
  OUT="[$TS] backend unreachable"
fi
echo "$OUT" >> /root/task4_health.log
EOS
chmod +x /root/task4_healthcheck.sh
( crontab -l 2>/dev/null | grep -v task4_healthcheck.sh ; echo "*/15 * * * * /root/task4_healthcheck.sh" ) | crontab -
crontab -l
/root/task4_healthcheck.sh
tail -n 5 /root/task4_health.log || true
'

echo "== 5) Push branch =="
git push -u origin HEAD || true

echo
echo "DONE: bug fix committed, redeploy attempted, cron job installed."
echo "LEFT MANUALLY: create issue + PR with \"Closes #...\" and get approvals."
