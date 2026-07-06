# tangent

Spawn isolated **GitHub Copilot CLI** sessions for side tasks using git worktrees and tmux.

> Fork of [JohnLangford/tangent](https://github.com/JohnLangford/tangent), adapted from Claude Code to the GitHub Copilot CLI (`copilot`). Same bash + tmux workflow.

## How it works

`tangent` creates a git worktree on a new branch, opens a tmux pane, and launches Copilot CLI with a prompt. Each tangent runs in its own worktree so it can't interfere with your main working tree. Panes are auto-balanced across tmux columns.

```
tangent <branch-name> "<prompt>"    # start a new side task
tangent <branch-name>               # resume a prior session
```

When the tangent's Copilot session finishes, the worktree contains any changes on its branch, ready for a PR or merge.

## tmux.conf

Companion tmux configuration: Ctrl-Space prefix, bell notifications (so tangent completions alert you), sticky pane labels, and a default session layout with a large working pane plus stacked tangent columns.

## Setup

```bash
# Put tangent on PATH
ln -sf $(pwd)/tangent ~/.local/bin/tangent

# Optional: use the tmux config
ln -sf $(pwd)/tmux.conf ~/.tmux.conf
```

Requires: `git`, `tmux`, `copilot` (GitHub Copilot CLI).

## Configuration

All optional, via environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `WORKTREE_ROOT` | `$HOME/worktrees` | Where tangent worktrees are created. |
| `TANGENT_BASE_REF` | current `HEAD` | Base ref for new tangent branches (e.g. `origin/main` to always branch from main). |
| `TANGENT_COPILOT_PERMS` | `--allow-all-tools` | Permission flags passed to `copilot`. Use `--yolo` for full autonomy, or `""` to be prompted. |

> **First run in a new worktree:** Copilot CLI may ask you to trust the new
> directory once. Approve it (or pre-trust `WORKTREE_ROOT`) so tangents launch
> unattended.
