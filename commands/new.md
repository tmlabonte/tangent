---
description: Spawn an isolated Copilot CLI session in a new git worktree + tmux pane — no context handoff (blank session)
argument-hint: "[branch] [prompt...]"
---

# /tangent:new

Spawn a **blank** isolated Copilot CLI session for a side task in its own git
worktree and tmux pane, using the `tangent` engine. No context is handed off —
the new session starts fresh with only the task prompt (if one is given).

Arguments: `$ARGUMENTS`

## Procedure

1. **Parse the arguments** into an optional `<branch>` and an optional
   `<prompt>`:
   - If the first whitespace-delimited token is a bare branch-like slug
     (matches `^[A-Za-z0-9][A-Za-z0-9._/-]*$`, no spaces) **and** there is more
     text after it, that token is `<branch>` and the remainder is `<prompt>`.
   - If the only argument is a single bare slug, it is `<branch>` with no
     prompt.
   - Otherwise the whole argument string is the `<prompt>` and `<branch>` is
     omitted.
2. **Derive a branch when omitted:** generate a 2–4 word kebab-case slug that
   captures the task — from the prompt, or (if there were no arguments at all)
   from the current conversation — and use it as `<branch>`.
3. **Dispatch exactly once** via the bash tool:
   ```bash
   tangent "<branch>" "<prompt>"     # when a prompt is present
   tangent "<branch>"                # when there is no prompt
   ```
   The `tangent` engine owns everything else: worktree creation, `username/`
   branch auto-prefixing, tmux pane placement, and launching Copilot.
4. **Print** the command's stdout back to the user, briefly. Do no further work
   in this session — the spawned pane owns the task.

## Examples

```
/tangent:new                                     # blank tangent, name from convo
/tangent:new spike-graphql                       # blank tangent on branch spike-graphql
/tangent:new try a jose v5 migration             # derives a branch, seeds the task
/tangent:new jose-v5 migrate the JWT middleware to jose v5
```

## See also

- `/tangent:summary` — hand off a concise summary of this conversation.
- `/tangent:full` — fork the entire conversation into the tangent.
- `/tangent:prune` — clean up finished tangent worktrees.
