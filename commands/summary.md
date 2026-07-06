---
description: Spawn an isolated Copilot CLI session seeded with a concise summary of the current conversation
argument-hint: "[branch] [prompt...]"
---

# /tangent:summary

Spawn an isolated Copilot CLI session for a side task in its own git worktree
and tmux pane, **seeded with a concise summary of this conversation**. This is
usually the right handoff: enough context to be productive, without the full
transcript. Backed by the `tangent` engine.

Arguments: `$ARGUMENTS`

## Procedure

1. **Parse the arguments** into an optional `<branch>` and an optional
   `<task>`, using the same grammar as `/tangent:new` (a leading bare slug is
   the branch when followed by more text; otherwise the text is the task and
   the branch is derived as a 2–4 word kebab-case slug).
2. **Write the summary.** This is your one creative responsibility. Compose a
   200–500 word markdown summary of the current session covering:
   - the user's overarching goal and the current task,
   - key decisions made and their rationale,
   - files/modules touched and their roles,
   - open threads, blockers, and things to verify next.
3. **Dispatch exactly once** via the bash tool. Stage the seed in a temp file
   so multi-line markdown quotes cleanly, then hand it to the engine:
   ```bash
   SEED=$(mktemp /tmp/tangent-seed-XXXXXX)
   cat > "$SEED" <<'CTX'
   # Context handed off from the parent Copilot session

   <your markdown summary here>

   ## Your task
   <the task; or "Continue the work summarized above." if none was given>
   CTX
   tangent "<branch>" "$(cat "$SEED")"
   rm -f "$SEED"
   ```
4. **Print** the engine's stdout back to the user, briefly. Do no further work
   in this session — the spawned pane owns the task.

## Examples

```
/tangent:summary refactor the JWT middleware to use jose v5
/tangent:summary jose-v5 refactor the JWT middleware to use jose v5
/tangent:summary                                 # summarize convo, name from it
```

## See also

- `/tangent:new` — blank session, no context handoff.
- `/tangent:full` — fork the entire conversation (full fidelity).
- `/tangent:prune` — clean up finished tangent worktrees.
