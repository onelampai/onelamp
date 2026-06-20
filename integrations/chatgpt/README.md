# OneLamp for ChatGPT

Gives [ChatGPT](https://chatgpt.com) access to your OneLamp context through the
`get_context` / `save_context` tools, so your context follows
you across every AI tool and model.

ChatGPT connects to the **same** OneLamp endpoint as every other client —
`https://api.onelamp.ai/mcp` — added as a custom connector in **Developer Mode**.
The tool surface is identical to Claude Code, Codex, and Cursor; the one
difference is that **ChatGPT has no lifecycle hooks**, so it can't auto-load and
auto-save on a session boundary. Capture is therefore *best-effort* via **custom
instructions** (the paste-able backstop below) rather than deterministic. There's
**nothing to install locally** — no `~/.chatgpt`, no `install.sh`; the connector
is added inside the ChatGPT app and the backstop lives in your account settings.

## Connect

1. Open ChatGPT → **Settings → Connectors** (formerly "Apps & Connectors").
2. Enable **Developer Mode** (under **Advanced**). Developer Mode is currently
   available on **Plus, Pro, and Business** plans — verify the current gating in
   the ChatGPT settings, since OpenAI moves it.
3. Choose **Add a custom connector** (it may read "Create" / "New connector") and
   enter the OneLamp MCP URL:

   ```
   https://api.onelamp.ai/mcp
   ```

4. **Authorize.** ChatGPT opens OneLamp in your browser to sign in and consent.
   OneLamp is its own OAuth 2.1 provider with RFC 8414/9728 discovery + dynamic
   client registration — there's **no API key** and **no `client_id`** to paste;
   ChatGPT registers itself, exactly as Codex and Cursor do.

After authorizing, the OneLamp tools (`get_context`, `save_context`,
`save_session`, `resume_session`, `list_context`, `forget_context`)
appear in ChatGPT.

## Capture backstop

ChatGPT has no SessionStart/Stop hooks, so loading and saving aren't enforced for
you. To get close to the deterministic behavior the hooked clients have, paste
[`custom-instructions.md`](./custom-instructions.md) into ChatGPT →
**Settings → Personalization → Custom instructions** (or a Project's
instructions, to scope it to one workspace).

That block tells ChatGPT to call `get_context` at the start of a task with a
personal angle, `save_context` proactively on durable facts, and `save_session`
when a conversation wraps up — all stamped `source_surface: "chatgpt"` so your
cross-tool reuse is attributed cleanly. Writes surface ChatGPT's
**tool-confirmation modal** before they run — that's expected; approve them.

## How it works

**Remote MCP, same endpoint.** ChatGPT speaks remote (streamable-HTTP) MCP and
runs the OAuth flow itself, so the connector is just the URL above — the identical
server that serves Claude Code, Codex, and Cursor. Context you save in any one
tool surfaces in the others through `get_context`; ChatGPT is one more reader and
writer of the same store.

**Best-effort capture.** Unlike the hooked clients, ChatGPT can't run code on a
session boundary, so the custom-instructions block is the enforcement mechanism —
a system-prompt nudge rather than a deterministic hook. It's the same trade-off
every hookless surface (browser Gemini, Perplexity) makes.

> **Naming note.** OpenAI renamed "connectors" → "apps" in December 2025; the
> settings UI may say either. The connect steps are the same regardless of label.
> A first-class OneLamp **app** with inline UI (built on the OpenAI Apps SDK) is in
> progress — it renders the context pack, memory browser, and save confirmation as
> interactive cards instead of plain text, and installs from the ChatGPT app
> directory once submitted.

Your context is stored and retrieved through the OneLamp API and stays available
to every AI tool you connect — this integration simply links ChatGPT to your
account.
