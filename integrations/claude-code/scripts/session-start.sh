#!/usr/bin/env bash
# OneLamp — SessionStart hook.
# Injects an instruction so Claude loads the user's OneLamp context at the
# start of the session. Fail-open: this hook must never block Claude Code, so
# it always exits 0 and only emits additionalContext.
cat >/dev/null 2>&1 || true

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"OneLamp is connected. Your portable, cross-agent context lives in the `onelamp` MCP server. Before starting work, call the OneLamp `get_context` tool (set source_surface: \"claude-code\") to load relevant prior context (project conventions, decisions, preferences, structure); skip it for generic questions with no personal angle. Whenever the user shares something durable, call OneLamp `save_context` proactively (set source_surface: \"claude-code\") to persist it for future sessions and other agents — never save secrets. If the user is picking up earlier work (\"resume where we left off\"), call `resume_session` to find and load the relevant prior session."}}
JSON
exit 0
