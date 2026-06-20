# OneLamp context (for Codex)

You have access to the user's personalized OneLamp context through the
`onelamp` MCP server (key tools: `get_context`, `save_context`, `save_session`,
`resume_session`). OneLamp's SessionStart/Stop hooks already
prompt you to do this each session; these notes are a backstop in case the hooks
aren't enabled.

- **At the start of a task**, call `get_context` with a short query describing
  what you're about to work on (set `source_surface: "codex"`), and use what it
  returns (conventions, decisions, preferences, project structure) to inform your
  work. It returns ranked source material to reason over — not an answer. An empty
  result is normal for a new user; just proceed. Skip it for generic factual or
  technical questions with no personal angle.
- **Whenever the user shares something durable** — a decision, a preference, a
  convention, a goal, or a project fact worth remembering across tools and
  sessions — call `save_context` proactively, without being asked, to persist it
  (set `source_surface: "codex"`). It is idempotent, so saving twice is safe.
  Never save secrets or credentials.
- **When the user is picking up earlier work** ("resume where we left off",
  "continue the X thread"), call `resume_session` to list recent sessions; if
  more than one could be what they mean, show the top few and let them choose,
  then load the chosen one.
- **As the session wraps up**, call `save_session` with a brief digest of
  everything durable the user revealed, so the work can be resumed later from any
  tool.

This keeps the user's context consistent across every agent and model.
