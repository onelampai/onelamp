#!/usr/bin/env bash
# OneLamp — Stop hook.
# Nudges Claude to persist durable learnings to OneLamp before the turn ends.
# Loop-safe: only fires once per stop cycle (respects `stop_hook_active`), so it
# can never trap Claude Code in a loop. Fail-open: any error allows the stop.
input="$(cat 2>/dev/null || true)"

# If we're already inside a stop-hook continuation, let the session stop.
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

cat <<'JSON'
{"decision":"block","reason":"Before finishing: if you learned anything durable this session (decisions, conventions, facts, project structure, preferences), persist it to OneLamp — prefer the `save_session` tool with a brief digest of everything durable from this session (it captures it all at once), or `save_context` for a single fact, so future sessions and other tools inherit it. If there is nothing worth saving, you may stop now."}
JSON
exit 0
