# OneLamp for Cursor

Gives [Cursor](https://cursor.com) access to your OneLamp context through the
`get_context` / `save_context` tools, so your context follows
you across every agent and model.

This integration is at **parity with the Claude Code and Codex plugins**: Cursor
connects to OneLamp over remote MCP (no bridge) and uses real **sessionStart/stop
lifecycle hooks** ([docs](https://cursor.com/docs/hooks)) to auto-load context at
the start of a conversation and nudge a save of durable learnings before it ends.

## Install

One idempotent command (safe to re-run):

```bash
curl -fsSL https://app.onelamp.ai/cursor/install.sh | bash
```

That's the hosted copy of [`install.sh`](./install.sh) — from a repo clone you can
run it directly (`integrations/cursor/install.sh`); it's the same self-contained
script. It does three things in `~/.cursor`:

1. **Writes the hook scripts** — `session-start.sh` and `stop.sh` to
   `~/.cursor/onelamp/` (inline, so the script needs no companion files), and
   marks them executable.
2. **Registers the MCP server** — merges `{ "onelamp": { "url": … } }` into
   `~/.cursor/mcp.json`.
3. **Wires the hooks** — merges `sessionStart` / `stop` entries into
   `~/.cursor/hooks.json`, pointing at the scripts.

JSON files are merged with `jq` when it's available; without `jq`, brand-new
files are written directly and existing ones get manual-merge instructions (the
installer never clobbers a file you already have).

On the first chat that touches OneLamp, a browser opens to complete OneLamp
**OAuth** sign-in. Approve it once.

## How it works

**Remote MCP.** Cursor speaks remote (HTTP / streamable) MCP and runs the OAuth
flow itself, so the server is just a `url`:

```json
{
  "mcpServers": {
    "onelamp": { "url": "https://api.onelamp.ai/mcp" }
  }
}
```

OneLamp's endpoint advertises RFC 8414/9728 OAuth discovery + dynamic client
registration, so there's no API key and no `client_id` to paste — Cursor registers
itself.

**Lifecycle hooks.** Cursor fires lifecycle hooks much like Claude Code and Codex
([hooks docs](https://cursor.com/docs/hooks)). The `sessionStart` hook returns
`additional_context` telling the agent to call `get_context`; the `stop` hook
returns a `followup_message` reminding the agent to `save_context`. Both scripts
**fail open** — any error exits 0 and never blocks Cursor.

Cursor's `stop` has no `stop_hook_active` flag and a `followup_message` is
auto-submitted, which would re-fire `stop` and loop. So the stop hook guards with
a per-conversation marker file (under `$TMPDIR/onelamp-cursor`): it nudges **once
per conversation**, then lets every later stop pass through.

This is a deterministic auto-load/save, not just a rules nudge. The installer also
writes [`rules/onelamp.mdc`](./rules/onelamp.mdc) to `~/.cursor/onelamp/` as a
backstop for the window before the hooks are trusted (and for setups that don't
run them) — drop it into a project's `.cursor/rules/`, or paste its body into
Cursor Settings → Rules → User Rules.

## Files

```
cursor/
├── install.sh              # self-contained installer (writes scripts + merges config)
├── rules/
│   └── onelamp.mdc         # backstop rule (project .cursor/rules or User Rules)
└── README.md
```

Your context is stored and retrieved through the OneLamp API and stays available
to every agent you connect — this integration simply links Cursor to your account.
