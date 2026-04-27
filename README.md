# tangent

Spawn isolated Claude Code sessions for side tasks using git worktrees and tmux.

## How it works

`tangent` creates a git worktree on a new branch, opens a tmux pane, and launches Claude Code with a prompt. Each tangent runs in its own worktree so it can't interfere with your main working tree. Panes are auto-balanced across tmux columns.

```
tangent <branch-name> "<prompt>"    # start a new side task
tangent <branch-name>               # resume a prior session
```

When the tangent's Claude session finishes, the worktree contains any changes on its branch, ready for a PR or merge.

## tmux.conf

Companion tmux configuration: Ctrl-Space prefix, bell notifications (so tangent completions alert you), sticky pane labels, and a default session layout with a large working pane plus stacked tangent columns.

## Setup

```bash
# Put tangent on PATH
ln -sf $(pwd)/tangent ~/.local/bin/tangent

# Optional: use the tmux config
ln -sf $(pwd)/tmux.conf ~/.tmux.conf
```

Requires: `git`, `tmux`, `claude` (Claude Code CLI).
