---
description: Clean up finished tangent worktrees — interactive menu by default, or bucket/targeted fast paths
argument-hint: "[--merged] [--pushed] [--orphaned] [--all] [--branch=<name>] [--dry-run]"
---

# /tangent:prune

Safely remove tangent worktrees (and their branches) via the `tangent-prune`
engine. Guardrails it enforces for you: never touches the worktree you're
currently in, never touches the main worktree, skips a worktree whose tmux
pane is still live (unless `--force`), and refuses a dirty worktree unless you
choose how to handle the changes.

Arguments: `$ARGUMENTS`

## Mode selection (chosen by the arguments)

| Invocation | Mode |
|---|---|
| `/tangent:prune` (no args) | **Interactive menu — the default.** |
| `/tangent:prune --merged` / `--pushed` / `--orphaned` / `--all` | Bucket fast path. |
| `/tangent:prune --branch=<name>` | Targeted (any status). |

`--dry-run` works in any mode.

## Procedure — interactive menu (no args)

1. **Get the inventory** as JSON:
   ```bash
   tangent-prune --list --json
   ```
   Each item is `{branch, path, status, dirty, live}` where `status` is one of
   `merged | pushed | unmerged | orphaned`. If the array is empty, tell the
   user there are no tangent worktrees and stop.
2. **Build a single-select menu** with `ask_user` (`allow_freeform: false`):
   - one choice per worktree, labelled e.g. `🌿 <branch> — <status>` with
     ` • dirty` / ` • live` suffixes when those flags are set,
   - add an `All merged` shortcut when any are merged, and an `All cleanable`
     shortcut when any are merged/pushed/orphaned,
   - always add `Cancel`.
3. **Preview, then confirm** the pick:
   ```bash
   tangent-prune --dry-run --branch="<branch>"
   ```
   - If that worktree is `dirty`, first ask how to handle it (Commit / Stash /
     Discard / Cancel) via `ask_user`, and pass the choice as
     `--on-dirty=commit|stash|discard` (add `--message="<msg>"` for commit).
   - If it is `live`, warn that its tmux pane is still open and offer to
     proceed with `--force`, or cancel.
   Then execute (re-run without `--dry-run`):
   ```bash
   tangent-prune --branch="<branch>" [--on-dirty=...] [--message="..."] [--force]
   ```
4. **Report** the result. If worktrees remain, offer to prune another (loop
   back to step 2); otherwise stop.

## Procedure — bucket / targeted

- **Bucket:** `tangent-prune --dry-run <flag>` → confirm via `ask_user` →
  re-run without `--dry-run`.
- **Targeted:** `tangent-prune --dry-run --branch=<name>` → confirm → execute.
  If a named branch is dirty, use the same Commit/Stash/Discard sub-flow as the
  interactive menu.

## Examples

```
/tangent:prune                                   # interactive menu (default)
/tangent:prune --merged                          # drop all merged tangents
/tangent:prune --all --dry-run                   # preview the full sweep
/tangent:prune --branch=tylerlabonte/spike-graphql
```

## See also

- `/tangent:new`, `/tangent:summary`, `/tangent:full` — spawn tangents.
