# OneLamp — Claude Code plugin

Connects Claude Code to your **onelamp** context layer so it follows
you across every agent — with no re-explaining and fewer tokens.

What it does:

- **Bundles the OneLamp remote MCP server** (`get_context`, `save_context`,
  `save_session`). On first use, Claude Code runs the OAuth flow — you sign in
  to OneLamp (GitHub / Google / email) and authorize access.
- **SessionStart hook** → instructs Claude to call `get_context` at the start of
  every session, so it begins with your relevant context already loaded.
- **Stop hook** → nudges Claude to `save_context` durable learnings before the
  turn ends (once per stop cycle, loop-safe).
- **`/recall` command** → pull your relevant OneLamp context into the session on
  demand (`/recall [topic]`).
- **`/save` command** → persist a durable fact/decision now (`/save [what]`), or
  distill and save this session when called with no argument.

## Install

```
/plugin marketplace add https://app.onelamp.ai/marketplace.json
/plugin install onelamp@onelamp
```

Run these in Claude Code itself (terminal or IDE extension) — `/plugin` isn't
available in the Claude desktop app's chat.

Then use `/recall` to load your context and `/save` to persist a learning — the
SessionStart/Stop hooks already do both automatically each session.

> The manifest is served by the OneLamp web app at `app.onelamp.ai` and resolves
> the plugin straight from this folder via a `git-subdir` source. Installing from
> the public repo directly (`/plugin marketplace add onelampai/onelamp`) also works
> as a fallback.

## How "always save" works (and its limits)

Claude Code exposes deterministic **hooks**, so OneLamp can reliably act at
session start and stop — that's the strongest enforcement available in any
client today. The hooks are **fail-open**: they never crash or trap Claude Code,
and the Stop nudge fires at most once per stop cycle.

The hooks *instruct* the model to call the MCP tools rather than calling them
directly (hooks are shell commands and can't invoke MCP tools). In practice this
gives reliable auto-load/auto-save without manual calls; `/recall` and `/save`
are there for when you want to trigger it by hand. Clients without hooks
(Cursor, ChatGPT) can only be nudged via rules/prompts — best-effort, not
guaranteed. This is a real, honest limitation of "forcing" third-party agents.

## Configuration

`.mcp.json` points at the OneLamp MCP endpoint. Replace the URL with your
deployment's endpoint if you self-host (e.g.
`https://onelamp-api.<account>.workers.dev/mcp`).
