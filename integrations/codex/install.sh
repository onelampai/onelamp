#!/usr/bin/env bash
# OneLamp — Codex setup (self-contained).
#
# Run it either way:
#   curl -fsSL https://app.onelamp.ai/codex/install.sh | bash    # hosted one-liner
#   integrations/codex/install.sh                                # from a repo clone
#
# This file is the source of truth; the hosted copy at
# https://app.onelamp.ai/codex/install.sh is generated from it and kept in sync.
#
# Idempotently wires OneLamp into Codex so the tool auto-loads and saves your
# cross-tool context. Safe to re-run: it skips anything already present.
# It does three things in ~/.codex:
#   1. Writes the SessionStart/Stop hook scripts under ~/.codex/onelamp/.
#   2. Registers OneLamp as a native remote (streamable-HTTP) MCP server + wires
#      the lifecycle hooks (appends to ~/.codex/config.toml).
#   3. Appends OneLamp usage guidance to ~/.codex/AGENTS.md as a backstop.
#
# Hook scripts and the config/AGENTS blocks are written inline (heredocs) so the
# script is fully self-contained — no companion files to fetch. Existing files
# are appended to only when the OneLamp block isn't already present (we never
# clobber your config).
set -euo pipefail

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG="$CODEX_DIR/config.toml"
AGENTS="$CODEX_DIR/AGENTS.md"
SCRIPTS_DEST="$CODEX_DIR/onelamp"

mkdir -p "$CODEX_DIR" "$SCRIPTS_DEST"

# 1) Hook scripts — written inline; always refreshed so updates land.
cat > "$SCRIPTS_DEST/session-start.sh" <<'ONELAMP_CODEX_SESSION_START'
#!/usr/bin/env bash
# OneLamp — Codex SessionStart hook.
# Injects an instruction so Codex loads the user's OneLamp context at the start
# of the session. Fail-open: this hook must never block Codex, so it always
# exits 0 and only emits additionalContext. Codex reads stdin JSON (session_id,
# cwd, source, ...) but we don't need it — we drain it so the pipe never blocks.
cat >/dev/null 2>&1 || true

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"OneLamp is connected. Your portable, cross-agent context lives in the `onelamp` MCP server. Before starting work, call the OneLamp `get_context` tool with a short query describing the task (set source_surface: \"codex\") to load relevant prior context (project conventions, decisions, preferences, structure). It returns ranked source material to reason over, not an answer; an empty result is normal for a new user. Whenever you learn something durable this session, call OneLamp `save_context` (set source_surface: \"codex\") to persist it for future sessions and other agents."}}
JSON
exit 0
ONELAMP_CODEX_SESSION_START

cat > "$SCRIPTS_DEST/stop.sh" <<'ONELAMP_CODEX_STOP'
#!/usr/bin/env bash
# OneLamp — Codex Stop hook.
# Nudges Codex to persist durable learnings to OneLamp before the turn ends.
# Loop-safe: only fires once per stop cycle (respects `stop_hook_active`), so it
# can never trap Codex in a loop. Fail-open: any error allows the stop.
input="$(cat 2>/dev/null || true)"

# If this turn was already continued by a Stop hook, let the session stop.
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

cat <<'JSON'
{"decision":"block","reason":"Before finishing: if you learned anything durable this session (decisions, conventions, facts, project structure, preferences), persist it to OneLamp — prefer the `save_session` tool with a brief digest of the session (set source_surface: \"codex\"; it captures it all at once), or `save_context` for a single fact, so future sessions and other tools inherit it. If there is nothing worth saving, you may stop now."}
JSON
exit 0
ONELAMP_CODEX_STOP

chmod +x "$SCRIPTS_DEST/session-start.sh" "$SCRIPTS_DEST/stop.sh"
echo "✓ Installed hook scripts to $SCRIPTS_DEST"

# 2) MCP server + hooks block — skip if [mcp_servers.onelamp] already exists.
if [ -f "$CONFIG" ] && grep -qF '[mcp_servers.onelamp]' "$CONFIG"; then
  echo "✓ OneLamp MCP server already in $CONFIG"
  # Warn if this is the pre-native-HTTP bridge config so the user can migrate.
  # Ignore comment lines so our own "no mcp-remote" comment can't false-positive.
  if grep -v '^[[:space:]]*#' "$CONFIG" | grep -q 'mcp-remote'; then
    echo "  ⚠ Found an older mcp-remote bridge block. Replace the [mcp_servers.onelamp]"
    echo "    section in $CONFIG with the url-based one this installer writes,"
    echo "    and add the [[hooks.SessionStart]]/[[hooks.Stop]] blocks."
  fi
else
  cat >> "$CONFIG" <<'ONELAMP_CODEX_CONFIG'

# OneLamp for OpenAI Codex.
#
# install.sh appended this verbatim to ~/.codex/config.toml. It does two things:
#   1. Registers OneLamp as a native remote (streamable-HTTP) MCP server. Codex
#      speaks HTTP MCP directly and runs the OAuth flow itself — no `mcp-remote`
#      bridge, no npx. The first task that touches the server opens a browser to
#      sign in to OneLamp; Codex caches the token afterward.
#   2. Wires SessionStart/Stop lifecycle hooks so context auto-loads at the start
#      of a session and durable learnings get saved before it ends — the same
#      mechanism as the Claude Code plugin, not just an AGENTS.md nudge.

# --- MCP server (native remote HTTP + OAuth) ------------------------------------
[mcp_servers.onelamp]
url = "https://api.onelamp.ai/mcp"
# Headroom for the first-run interactive OAuth browser sign-in (default is 10s).
startup_timeout_sec = 60
# No bearer_token_env_var: Codex's OAuth client obtains and refreshes the token
# from the endpoint's discovery metadata (RFC 8414/9728 + dynamic registration).

# --- Lifecycle hooks (auto load / save) -----------------------------------------
# Paths resolve at hook-exec time via the shell, honoring CODEX_HOME and falling
# back to ~/.codex — wherever install.sh placed the scripts. Both hooks fail open
# (always exit 0 on their own errors) so they can never block Codex.
[[hooks.SessionStart]]
matcher = "startup|resume|clear|compact"

[[hooks.SessionStart.hooks]]
type = "command"
command = '"${CODEX_HOME:-$HOME/.codex}/onelamp/session-start.sh"'
timeout = 10
statusMessage = "Loading OneLamp context"

[[hooks.Stop]]

[[hooks.Stop.hooks]]
type = "command"
command = '"${CODEX_HOME:-$HOME/.codex}/onelamp/stop.sh"'
timeout = 10
statusMessage = "Saving durable context to OneLamp"
ONELAMP_CODEX_CONFIG
  echo "✓ Added OneLamp MCP server + hooks to $CONFIG"
fi

# 3) Global AGENTS.md guidance (backstop for when hooks aren't trusted yet).
if [ -f "$AGENTS" ] && grep -qF "OneLamp context (for Codex)" "$AGENTS"; then
  echo "✓ OneLamp guidance already in $AGENTS"
else
  cat >> "$AGENTS" <<'ONELAMP_CODEX_AGENTS'

# OneLamp context (for Codex)

You have access to the user's personalized OneLamp context through the
`onelamp` MCP server (tools: `get_context`, `save_context`, `save_session`).
OneLamp's SessionStart/Stop hooks already prompt you to do this each session;
these notes are a backstop in case the hooks aren't enabled.

- **At the start of a task**, call `get_context` with a short query describing
  what you're about to work on (set `source_surface: "codex"`), and use what it
  returns (conventions, decisions, preferences, project structure) to inform your
  work. It returns ranked source material to reason over — not an answer. An empty
  result is normal for a new user; just proceed.
- **Whenever the user shares something durable** — a decision, a preference, a
  convention, or a fact worth remembering across tools and sessions — call
  `save_context` to persist it (set `source_surface: "codex"`). It is idempotent,
  so saving the same thing twice is safe.

This keeps the user's context consistent across every agent and model.
ONELAMP_CODEX_AGENTS
  echo "✓ Added OneLamp guidance to $AGENTS"
fi

echo ""
echo "Done. Start codex and run a task — OneLamp will load and save your context."
echo "First run: a browser opens to sign in to OneLamp (OAuth), and Codex will ask"
echo "you to trust the OneLamp hooks. Approve both once and you're set."
