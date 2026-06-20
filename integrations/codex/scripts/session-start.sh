#!/usr/bin/env bash
# OneLamp — Codex SessionStart hook.
# Injects an instruction so Codex loads the user's OneLamp context at the start
# of the session. Fail-open: this hook must never block Codex, so it always
# exits 0 and only emits additionalContext. Codex reads stdin JSON (session_id,
# cwd, source, ...) but we don't need it — we drain it so the pipe never blocks.
cat >/dev/null 2>&1 || true

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"OneLamp is connected. Your portable, cross-tool context lives in the `onelamp` MCP server. Before starting work, call the OneLamp `get_context` tool with a short query describing the task (set source_surface: \"codex\") to load relevant prior context (project conventions, decisions, preferences, structure). It returns ranked source material to reason over, not an answer; an empty result is normal for a new user. Whenever you learn something durable this session, call OneLamp `save_context` (set source_surface: \"codex\") to persist it for future sessions and other tools."}}
JSON
exit 0
