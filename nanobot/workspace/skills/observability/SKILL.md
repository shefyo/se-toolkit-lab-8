# System Health & Diagnostics Strategy
- When the user asks "What went wrong?" or "Check health":
    1. Search logs: `logs_search(query='_stream:{service="backend"} AND level:error')`.
    2. If logs contain a 'trace_id', fetch it: `traces_get(trace_id='...')`.
    3. Analyze if the error is a DB connection issue or a logic bug.
    4. Summarize: Mention the specific error from logs and the failing span from traces.
- For CRON tasks:
    - Check logs for errors in the last 2 minutes.
    - If clean, report "System is healthy".
    - If errors exist, provide the trace summary.
