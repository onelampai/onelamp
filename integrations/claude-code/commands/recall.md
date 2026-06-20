---
description: Pull your relevant OneLamp context into this session
argument-hint: [topic to recall]
---

Recall my portable OneLamp context for the current work.

1. Call the OneLamp `get_context` tool (set `source_surface: "claude-code"`).
   - If arguments were provided, use them as the query: **$ARGUMENTS**.
   - Otherwise, infer a short query from what we're working on right now.
2. Briefly summarize what you loaded (conventions, decisions, preferences,
   project facts) and how it applies to the task.

This is **retrieval, not generation** — `get_context` returns ranked source
material to reason over, never a synthesized answer. An empty result is normal
for a new user or an unrelated topic; just say so and proceed. Don't modify any
project files.
