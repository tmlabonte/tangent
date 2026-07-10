---
description: Fork completed history before this command into an isolated tangent via git worktree + tmux pane
argument-hint: "[branch] [prompt...]"
---

# /tangent:full

Spawn an isolated Copilot CLI session that is a **full-fidelity fork of this
conversation** — the tangent resumes the completed event history before this
command, in its own git worktree and tmux pane. Use when the side task genuinely
needs the whole context. ⚠ On very long sessions this is heavy and can crowd the
forked session's context window.

Arguments: `$ARGUMENTS`

## Procedure

1. **Parse the arguments** into an optional `<branch>` and an optional
   `<task>`, using the same grammar as `/tangent:new`. Derive a 2–4 word
   kebab-case `<branch>` when it is omitted.
2. **Dispatch exactly once** via the bash tool:
   ```bash
   tangent-full "<branch>" "<task>"     # <task> is optional
   ```
   `tangent-full` clones the current session (located via
   `COPILOT_AGENT_SESSION_ID`) under a fresh id, then hands off to the
   `tangent` engine, which creates the worktree + pane and resumes the fork.
   A provided `<task>` is auto-sent to the resumed session; with no task, the
   tangent simply opens on completed history before this command. A live fork
   removes this triggering command turn and refuses to launch if it cannot
   verify and trim the cloned event log.
3. **Print** the command's stdout back to the user, briefly. Do no further work
   in this session — the spawned pane owns the task.

## Examples

```
/tangent:full continue this whole investigation in isolation
/tangent:full fix-auth continue the auth work with full context
/tangent:full                                    # fork convo, name from it
```

## See also

- `/tangent:new` — blank session, no context handoff.
- `/tangent:summary` — concise model-written summary handoff.
- `/tangent:prune` — clean up finished tangent worktrees.
