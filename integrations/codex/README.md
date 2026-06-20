# OneLamp for OpenAI Codex

Gives [Codex](https://github.com/openai/codex) access to your OneLamp
context through the `get_context` / `save_context` tools, so
your context follows you across every agent and model.

This integration is at **parity with the Claude Code plugin**: Codex connects to
OneLamp over native remote MCP (no bridge) and uses real **SessionStart/Stop
lifecycle hooks** to auto-load context at the start of a session and save durable
learnings before it ends.

## Install

One idempotent command (safe to re-run):

```bash
curl -fsSL https://app.onelamp.ai/codex/install.sh | bash
```

That's the hosted copy of [`install.sh`](./install.sh) — from a repo clone you can
run it directly (`integrations/codex/install.sh`); it's the same self-contained
script. It does three things in `~/.codex`:

1. **Writes the hook scripts** — `session-start.sh` and `stop.sh` to
   `~/.codex/onelamp/` (inline, so the script needs no companion files), and
   marks them executable.
2. **Registers the MCP server + hooks** — appends the [`config.toml`](./config.toml)
   block to `~/.codex/config.toml`: the `[mcp_servers.onelamp]` remote-HTTP block
   plus the `[[hooks.SessionStart]]` / `[[hooks.Stop]]` blocks that point at the
   scripts.
3. **Adds usage guidance** — appends the [`AGENTS.md`](./AGENTS.md) block to
   `~/.codex/AGENTS.md` as a backstop for the hooks.

On the first task that touches OneLamp, a browser opens to complete OneLamp
**OAuth** sign-in (Codex runs the flow itself and caches the token), and Codex
asks you to **trust the OneLamp hooks**. Approve both once.

> **Manual setup** (if you'd rather not run the script): copy `scripts/` to
> `~/.codex/onelamp/` (and `chmod +x` both files), paste
> [`config.toml`](./config.toml) into `~/.codex/config.toml`, and paste
> [`AGENTS.md`](./AGENTS.md) into `~/.codex/AGENTS.md`.

## How it works

**Native remote MCP.** Current Codex speaks streamable-HTTP MCP directly and runs
the OAuth flow itself, so the server is just a `url`:

```toml
[mcp_servers.onelamp]
url = "https://api.onelamp.ai/mcp"
startup_timeout_sec = 60
```

OneLamp's endpoint advertises RFC 8414/9728 OAuth discovery + dynamic client
registration, which is exactly what Codex's built-in OAuth client consumes — no
`mcp-remote`, no npx.

**Lifecycle hooks.** Codex fires the same hook events Claude Code does. The
SessionStart hook emits `additionalContext` telling the agent to call
`get_context`; the Stop hook returns `{"decision":"block","reason":...}` (guarded
by `stop_hook_active`, so it nudges at most once) to remind the agent to
`save_context`. Both scripts fail open — any error exits 0 and never blocks Codex.

This is a deterministic auto-load/save, not just an AGENTS.md nudge. AGENTS.md is
kept as a backstop for the window before you trust the hooks (and for clients
that don't run them).

## Files

```
codex/
├── config.toml             # [mcp_servers.onelamp] (native url) + [[hooks.*]]
├── scripts/
│   ├── session-start.sh    # SessionStart → additionalContext: load context
│   └── stop.sh             # Stop → nudge save_context (loop-safe)
├── AGENTS.md               # backstop usage guidance
├── install.sh              # idempotent merge into ~/.codex (+ installs scripts)
└── README.md
```

Your context is stored and retrieved through the OneLamp API and stays available
to every agent you connect — this integration simply links Codex to your account.
