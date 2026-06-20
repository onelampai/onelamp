---
description: Save durable context to OneLamp (a fact, decision, preference — or this session)
argument-hint: [what to remember]
---

Save durable context to OneLamp so it follows me across every AI tool and session.

- **If arguments were provided**, save exactly that as a single durable memory:
  call `save_context` with **$ARGUMENTS** (set `source_surface: "claude-code"`).
- **If no arguments**, the user is explicitly asking to save this session —
  capture it. Prefer `save_session` with the transcript (or a brief digest);
  OneLamp distills a structured handoff briefing — **DECISIONS MADE**, **FEEDBACK
  GIVEN** (ideas/options rejected or chosen), **ACTIONS TAKEN** (the progress made),
  **ARTIFACTS** (the concrete deliverables produced — files, docs, specs, PRs — with
  their latest state), and **NEXT STEPS**, plus durable preferences and facts —
  so the next AI tool can continue the work. Use `save_context` for a single
  standalone fact.

Then confirm what you saved in one line.

**Never save secrets or credentials.** Saving is idempotent, so re-saving the
same thing is safe. Skip anything that's ephemeral or specific only to this one
conversation.
