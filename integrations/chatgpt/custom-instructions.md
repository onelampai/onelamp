# OneLamp custom instructions (for ChatGPT)

Paste the block below into ChatGPT → **Settings → Personalization → Custom
instructions** (in the "Anything else ChatGPT should know?" box), or into a
**Project's** instructions to scope it to one workspace.

It's the hookless backstop for ChatGPT: since ChatGPT has no SessionStart/Stop
lifecycle hooks, these standing instructions are what keep your context loading
and saving on every task — the equivalent of the session hooks the Claude Code,
Codex, and Cursor integrations install.

After pasting, every new ChatGPT conversation reads these instructions and keeps
your OneLamp context in sync on its own — no per-message reminders needed. Writes
will surface ChatGPT's tool-confirmation modal before they run; that's expected.

---

```
I use OneLamp (connected via MCP) as my shared context across every AI tool.
Use its tools to keep my context portable. Always pass source_surface: "chatgpt".

- At the START of any task with a personal angle — references to my/our projects,
  personalized advice, continuing earlier work, or anything that depends on my
  preferences or conventions — call get_context with a short query about the task
  (source_surface: "chatgpt"). Use what it returns as source material to reason
  over; it is not a finished answer. An empty result is normal — just proceed.
  SKIP it for generic factual or technical questions with no personal angle.

- Whenever I share something DURABLE — a decision, a preference, a convention, a
  goal, or a project fact worth remembering across tools and sessions — call
  save_context proactively, without being asked (source_surface: "chatgpt"). 
  NEVER save secrets, credentials, or tokens.

- When I'm picking up earlier work ("resume where we left off", "continue the X
  thread", "what was I working on"), call resume_session to find recent sessions;
  if more than one could be what I mean, show the top few and let me choose.

- When a conversation WRAPS UP, call save_session with a brief digest of
  everything durable I revealed (source_surface: "chatgpt"), so the work can be
  resumed later from any tool. This is the end-of-session backstop ChatGPT can't
  run automatically.
```