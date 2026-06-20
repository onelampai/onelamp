#!/usr/bin/env bash
# OneLamp — Cursor setup (self-contained).
#
# Run it either way:
#   curl -fsSL https://app.onelamp.ai/cursor/install.sh | bash    # hosted one-liner
#   integrations/cursor/install.sh                                # from a repo clone
#
# This file is the source of truth; the hosted copy at
# https://app.onelamp.ai/cursor/install.sh is generated from it and kept in sync.
#
# Idempotently wires OneLamp into Cursor so the tool auto-loads and saves your
# cross-tool knowledge base. Safe to re-run: it skips anything already present.
# It does three things in ~/.cursor:
#   1. Writes the sessionStart/stop hook scripts under ~/.cursor/onelamp/.
#   2. Registers OneLamp as a remote MCP server (merges into ~/.cursor/mcp.json).
#   3. Wires the lifecycle hooks (merges into ~/.cursor/hooks.json).
# It also drops an optional rules backstop at ~/.cursor/onelamp/onelamp.mdc.
#
# Hook scripts are written inline (heredocs) so the script is fully self-contained
# — no companion files to fetch. JSON files are merged with `jq` when available;
# without it, brand-new files are written directly and existing ones get
# manual-merge instructions (we never clobber a file you already have).
set -euo pipefail

MCP_URL="https://api.onelamp.ai/mcp"
CURSOR_DIR="${CURSOR_HOME:-$HOME/.cursor}"
MCP="$CURSOR_DIR/mcp.json"
HOOKS="$CURSOR_DIR/hooks.json"
DEST="$CURSOR_DIR/onelamp"

mkdir -p "$CURSOR_DIR" "$DEST"

have_jq() { command -v jq >/dev/null 2>&1; }

# 1) Hook scripts — written inline; always refreshed so updates land.
cat > "$DEST/session-start.sh" <<'ONELAMP_SESSION_START'
#!/usr/bin/env bash
# OneLamp — Cursor sessionStart hook.
# Injects an instruction so Cursor loads the user's OneLamp context at the start
# of a conversation. Fail-open: this hook must never block Cursor, so it always
# exits 0 and only emits `additional_context`. Cursor passes JSON on stdin
# (conversation_id, model, workspace_roots, …) which we drain but don't need.
cat >/dev/null 2>&1 || true

cat <<'JSON'
{"additional_context":"OneLamp is connected. Your portable, cross-tool context lives in the `onelamp` MCP server. Before starting work, call the OneLamp `get_context` tool with a short query describing the task (set source_surface: \"cursor\") to load relevant prior context (project conventions, decisions, preferences, structure). It returns ranked source material to reason over, not an answer; an empty result is normal for a new user. Whenever you learn something durable this session, call OneLamp `save_context` (set source_surface: \"cursor\") to persist it for future sessions and other tools."}
JSON
exit 0
ONELAMP_SESSION_START

cat > "$DEST/stop.sh" <<'ONELAMP_STOP'
#!/usr/bin/env bash
# OneLamp — Cursor stop hook.
# Nudges Cursor to persist durable learnings to OneLamp before the turn ends, via
# a one-time `followup_message`.
#
# Loop-safe: Cursor's `stop` hook (unlike Claude Code / Codex) carries no
# `stop_hook_active` flag, and a `followup_message` is auto-submitted — which would
# fire `stop` again and loop forever. So we guard with a per-conversation marker
# file: at most one nudge per `conversation_id`. Once nudged, every later stop in
# that conversation passes straight through.
#
# Fail-open: any error (no conversation_id, unwritable state dir) just lets the
# session stop — we emit nothing and exit 0, never blocking Cursor.
input="$(cat 2>/dev/null || true)"

# Pull conversation_id out of the stdin JSON without a jq dependency.
cid="$(printf '%s' "$input" | sed -n 's/.*"conversation_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

state_dir="${TMPDIR:-/tmp}/onelamp-cursor"
mkdir -p "$state_dir" 2>/dev/null || true
marker="$state_dir/${cid:-unknown}.nudged"

# Unknown conversation, or already nudged this one → let the session stop.
if [ -z "$cid" ] || [ -e "$marker" ]; then
  exit 0
fi
: > "$marker" 2>/dev/null || true

cat <<'JSON'
{"followup_message":"Before finishing: if you learned anything durable this session (decisions, conventions, facts, project structure, preferences), call the OneLamp `save_context` tool (set source_surface: \"cursor\") to persist it so future sessions and other tools inherit it. If there is nothing worth saving, just stop."}
JSON
exit 0
ONELAMP_STOP

chmod +x "$DEST/session-start.sh" "$DEST/stop.sh"
echo "✓ Installed hook scripts to $DEST"

# 1b) Optional rules backstop — written so curl|bash users have it locally too.
cat > "$DEST/onelamp.mdc" <<'ONELAMP_RULE'
---
description: Load and save portable context via the OneLamp MCP server
alwaysApply: true
---

# OneLamp context (for Cursor)

You have access to the user's personalized OneLamp knowledge base through the
`onelamp` MCP server (tools: `get_context`, `save_context`, `save_session`).
OneLamp's sessionStart/stop hooks already prompt you to do this each session;
these notes are a backstop in case the hooks aren't installed.

- **At the start of a task**, call `get_context` with a short query describing
  what you're about to work on (set `source_surface: "cursor"`), and use what it
  returns (conventions, decisions, preferences, project structure) to inform your
  work. It returns ranked source material to reason over — not an answer. An empty
  result is normal for a new user; just proceed.
- **Whenever the user shares something durable** — a decision, a preference, a
  convention, or a fact worth remembering across tools and sessions — call
  `save_context` to persist it (set `source_surface: "cursor"`). It is
  idempotent, so saving the same thing twice is safe.

This keeps the user's context consistent across every agent and model.
ONELAMP_RULE

# 2) MCP server — add mcpServers.onelamp = { url } (idempotent).
if [ -f "$MCP" ] && grep -q '"onelamp"' "$MCP"; then
  echo "✓ OneLamp MCP server already in $MCP"
elif [ ! -f "$MCP" ]; then
  printf '{\n  "mcpServers": {\n    "onelamp": { "url": "%s" }\n  }\n}\n' "$MCP_URL" > "$MCP"
  echo "✓ Created $MCP with the OneLamp MCP server"
elif tmp="$(mktemp)" && have_jq &&
  jq --arg url "$MCP_URL" '.mcpServers.onelamp = { "url": $url }' "$MCP" > "$tmp" 2>/dev/null; then
  mv "$tmp" "$MCP"
  echo "✓ Added OneLamp MCP server to $MCP"
else
  rm -f "$tmp" 2>/dev/null || true
  echo "⚠ Couldn't merge automatically (no jq, or $MCP isn't valid JSON)."
  echo "  Add this under \"mcpServers\" by hand:"
  echo "      \"onelamp\": { \"url\": \"$MCP_URL\" }"
fi

# 3) Lifecycle hooks — add sessionStart + stop entries pointing at the scripts.
if [ -f "$HOOKS" ] && grep -q 'onelamp/session-start.sh' "$HOOKS"; then
  echo "✓ OneLamp hooks already in $HOOKS"
elif [ ! -f "$HOOKS" ]; then
  cat > "$HOOKS" <<'ONELAMP_HOOKS'
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": "./onelamp/session-start.sh" }],
    "stop": [{ "command": "./onelamp/stop.sh" }]
  }
}
ONELAMP_HOOKS
  echo "✓ Created $HOOKS with the OneLamp lifecycle hooks"
elif tmp="$(mktemp)" && have_jq && jq '
    .version = (.version // 1)
    | .hooks.sessionStart = ((.hooks.sessionStart // []) + [{ "command": "./onelamp/session-start.sh" }])
    | .hooks.stop = ((.hooks.stop // []) + [{ "command": "./onelamp/stop.sh" }])
  ' "$HOOKS" > "$tmp" 2>/dev/null; then
  mv "$tmp" "$HOOKS"
  echo "✓ Added OneLamp lifecycle hooks to $HOOKS"
else
  rm -f "$tmp" 2>/dev/null || true
  echo "⚠ Couldn't merge automatically (no jq, or $HOOKS isn't valid JSON)."
  echo "  Add these under the \"hooks\" object by hand:"
  echo '      "sessionStart": [{ "command": "./onelamp/session-start.sh" }],'
  echo '      "stop": [{ "command": "./onelamp/stop.sh" }]'
fi

# 4) Rules backstop (optional). Cursor's global rules live in Settings → Rules,
#    not a file, so we don't auto-enable it — it's written to ~/.cursor/onelamp/.
echo ""
echo "Optional backstop: copy $DEST/onelamp.mdc into a project's .cursor/rules/,"
echo "or paste its body into Cursor Settings → Rules → User Rules. The hooks above"
echo "already enforce load/save; the rule only matters before hooks are trusted."

echo ""
echo "Done. Open Cursor and start a chat — OneLamp will load and save your context."
echo "First run: a browser opens to sign in to OneLamp (OAuth). Approve it once and"
echo "you're set."
