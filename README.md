<div align="center">

<a href="https://onelamp.ai">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/wordmark-dark.svg">
    <img alt="OneLamp" src="assets/wordmark.svg" width="320">
  </picture>
</a>

### Shared memory for your AI. Teach one, they all learn.

[Website](https://onelamp.ai) · [App](https://app.onelamp.ai) · [Docs](https://docs.onelamp.ai) · [Discord](https://discord.gg/8Q8n7xgWpb) · [X](https://x.com/onelampai)

</div>

---

You don't use one AI anymore — Claude to code, ChatGPT to think, Cursor in your
editor, Gemini to search. Each one quietly learns how you work, then keeps it to
itself, and AI providers have no incentive to share. **OneLamp is the self-curating,
neutral layer across all of them:** a per-user context layer every agent writes
to and reads from through a single MCP endpoint. Reach for the next tool and it
already knows your stack, your conventions, the decision you made an hour ago in
another tab.

- **Cross-provider.** One endpoint that Claude, ChatGPT, Cursor, Codex, and any
  other MCP client share.
- **Self-curating.** It keeps itself current as you work — surfacing what you
  rely on, letting go of what's gone stale — so it's never a file you
  hand-maintain.
- **Hooks into the agent loop, not just an endpoint.** Beyond MCP, our plugins for Claude Code, Codex, and Cursor install secure agent
  lifecycle hooks — auto-loading your context when a session starts and capturing
  learnings before it ends — so context adherence is enforced in the loop, not
  left to the agent to "remember".
- **Teams, by promotion not pooling.** Opt in to share a learning with your team without exposing your personal context. Use preset/custom policies to control context sharing.
- **Yours.** Export or delete everything at any time.

---

## Quickstart (~60s)

1. **Create an account** at **[app.onelamp.ai](https://app.onelamp.ai)** — sign
   in with email (one-time code), Google, or GitHub.
2. **Connect an agent** — copy your MCP endpoint and add it to your AI client
   (below). The client runs the sign-in flow itself; there's **no API key to
   paste**.
3. **Use it.** Your agents now auto-load context at the start of a session and
   save durable learnings as you work.

Your endpoint:

```
https://api.onelamp.ai/mcp
```

It's a **remote, streamable-HTTP** MCP server secured with **OAuth 2.1** — the
first connection opens a browser to sign in to OneLamp, then the client caches
the token.

---

## Example use cases

- **Cross-agent handoff (the "aha").** Tell Claude a decision about your
  architecture; open Cursor an hour later and it already knows — no re-explaining.
- **Your preferences travel with you.** Your stack, coding conventions, and
  writing voice follow you into every agent, so each one sounds like you from the
  first message.
- **Pick up where you left off.** Move to the next tool mid-task and your current
  focus and open work come along — no cold start in the new agent.
- **Onboard a new agent or tool instantly.** Point a fresh agent at OneLamp and it
  starts from everything the others learned, not from zero.
- **Bring your own knowledge.** Connect Notion, Drive, or any MCP server and pull
  your specs and docs in on demand — indexed into the same context every agent
  draws on.
- **Stop re-explaining across tools.** A ranked context pack beats re-pasting the
  same background into every new chat (fewer tokens is the side effect, not the
  point).
- **Share what works with your team.** Promote a hard-won fix or convention to a
  team; teammates' agents build on it — shared learnings are corroborated before
  they're trusted, without pooling anyone's private context.
- **Own and move your context.** Export your entire context as JSON from your
  account — anytime, no lock-in.

---

## Connect your agent

### Generic (any MCP client / Claude app custom connector)

Add OneLamp as a remote HTTP MCP server:

```json
{
  "mcpServers": {
    "onelamp": {
      "type": "http",
      "url": "https://api.onelamp.ai/mcp"
    }
  }
}
```

In the **Claude app**, add it as a *custom connector*; in **ChatGPT**, enable
*developer mode* and add the remote MCP server.

### Claude Code

Install the plugin (bundles the MCP server, auto get/save session hooks, and the
`/onelamp` command, aliased `/ol`):

```bash
# add the OneLamp marketplace, then install the plugin
/plugin marketplace add https://app.onelamp.ai/marketplace.json
/plugin install onelamp@onelamp
```

Run these in Claude Code itself (terminal or IDE extension) — `/plugin` isn't
available in the Claude desktop app's chat.

### OpenAI Codex

```bash
curl -fsSL https://app.onelamp.ai/codex/install.sh | bash
```

Registers OneLamp as a native remote MCP server and wires SessionStart/Stop
hooks (auto load/save, fail-open).

### Cursor

```bash
curl -fsSL https://app.onelamp.ai/cursor/install.sh | bash
```

Or one-click — **Add to Cursor**:

```
cursor://anysphere.cursor-deeplink/mcp/install?name=onelamp&config=eyJ1cmwiOiJodHRwczovL2FwaS5vbmVsYW1wLmFpL21jcCJ9
```

### ChatGPT

No installer — ChatGPT adds OneLamp as a **custom connector** in Developer Mode:
**Settings → Connectors → Developer Mode → add a custom connector** with the URL
`https://api.onelamp.ai/mcp`, then authorize. ChatGPT has no lifecycle hooks, so
paste [`integrations/chatgpt/custom-instructions.md`](integrations/chatgpt/custom-instructions.md)
into **Settings → Personalization → Custom instructions** as a capture backstop.
A first-class **ChatGPT app** with inline UI (via the OpenAI Apps SDK) is in
progress.

### Verify with MCP Inspector

Point the [MCP Inspector](https://github.com/modelcontextprotocol/inspector) at
`https://api.onelamp.ai/mcp` to confirm the OAuth flow and list the tools.

---

## Beyond the endpoint: agent-loop hooks

An MCP endpoint exposes the tools — but an endpoint alone can't guarantee an agent
actually *uses* them at the right moment. OneLamp's plugins go a layer deeper. For
**Claude Code**, **Codex**, and **Cursor**, installing the plugin securely wires
**session lifecycle hooks** directly into the agent's loop:

- **On session start**, the hook loads your ranked context pack before the agent
  takes its first step — so it begins every task already grounded in your
  preferences, decisions, and conventions.
- **On session end**, the hook captures durable learnings back to your context —
  so nothing has to be remembered manually.

Because loading and capture run as part of the agent's own lifecycle rather than
as optional tool calls, **context adherence is enforced in the loop, not left to
chance**. The hooks are **fail-open** (a OneLamp hiccup never blocks your agent)
and scoped to the lifecycle events they need — nothing more.

---

## The core tools

A small set of memory tools is the whole surface most agents use:

| Tool | What it does |
| --- | --- |
| `save_context` | Save a durable learning — a preference, decision, or fact — to your context. |
| `get_context` | Retrieve a relevance-ranked context pack for the current task. |
| `save_session` | Capture a session's takeaways as a handoff for the next tool. |
| `resume_session` | Pick up cross-tool work where you left off — list recent sessions, or load one in full. |
| `list_context` / `forget_context` | Browse what's saved, or delete an entry you no longer want. |

The Claude Code and Codex plugins call `get_context` at session start and
`save_context` / `save_session` before a session ends automatically, so capture
and recall happen without you thinking about it.

`get_context` also takes an optional `scope` — `personal`, `team`, `team:<id>`,
or `all` (the default) — so a query can draw on your personal context, a team's
shared context, or both at once. See [Teams](#teams) below. Export and account
management live in the app, not as chat tools.

---

## Data sources

Beyond what your agents capture directly, you can connect the tools you already
work in — Notion, Google Drive, Slack, or any remote MCP server. When you pull
content in, OneLamp **indexes it on demand** and folds it into the same
self-curating context layer your agents draw on — it enriches your context
rather than relaying a source straight through. Connect once, then pull in fresh
material whenever you want.

> **On-demand, not crawled.** Connected sources are indexed only when you
> explicitly pull them in — there's no background crawl. Capture is
> capture-on-write (agents call `save_context`); freshness for connected sources
> is an explicit action you take.

Connect a source, pull content in, and browse the compiled **Library** — a
searchable catalog your agents draw on — all from the **Data sources** and
**Library** pages in the app. These are managed in the app rather than as chat
tools, so they never crowd an agent's tool list.

---

## Teams

A team shares one context layer — but by **promotion, not pooling.** Your personal
context is never merged into a team's. Instead, you explicitly **promote** a
selected learning into a separate, ACL'd team store, where every teammate's agents
can draw on it. Joining a team never exposes your private entries.

- **Opt-in and explicit.** `save_context` always writes to your **personal**
  store. A learning reaches the team only when you choose to promote it — the
  **Promote** action in the app.
- **Secret-redacted at the boundary.** Promotions are scrubbed of secrets before
  they cross into the shared store, and tagged with you as the contributor.
- **Corroborated before it's trusted.** A shared learning is held as needing
  corroboration until another teammate independently confirms it; a conflicting
  learning is flagged for an admin to resolve — so one wrong fix can't silently
  spread.
- **Read with `scope`.** `get_context` draws on your personal pack plus in-scope
  team packs in one ranked result; each entry is tagged with its scope and
  contributor.

Promote learnings, and manage members and roles, from the **Teams** area in the
app.

---

## Pricing

Flat, no metering, no usage billing — OneLamp is a retrieval/indexing layer, so
there's no per-request generation cost to pass through. See [Pricing](https://onelamp.ai/pricing) for current details.

| Plan | Price | For |
| --- | --- | --- |
| **Free** | $0 | 2 agents, 5 data sources, share with 1 team, export anytime — no card. |
| **Pro** | $3/mo (or $2/mo billed annually) | Unlimited AI tools, data sources, and teams. |
| **Enterprise** | Contact sales | Everything in Pro org-wide, plus SSO/SAML, audit logs, and data residency. |

---

## Privacy & data ownership

OneLamp is privacy-first by design: your context is per-user, never mixed across
users, and fully exportable and deletable. Use of the hosted service is governed
by the [Terms of Service and Privacy Policy](https://onelamp.ai).

---

## License

Licensed under the [Apache License 2.0](LICENSE). "OneLamp", "Saho Labs", and the
OneLamp logo are trademarks of Saho Labs, Inc. — see [`NOTICE`](NOTICE). This license
covers the docs and examples in this repository; the OneLamp product source is
proprietary and owned by Saho Labs, Inc.
