# jcl-dotfiles

Personal dev environment for multi-agent Claude Code workflows.

## Contents

### `tmux.conf`
Tmux configuration with Ctrl-Space prefix, bell notifications, pane labels, and a default session layout (large working pane + stacked tangent panes).

### `scripts/tangent`
Spawn an isolated Claude Code session for a side task. Creates a git worktree on a new branch, opens a tmux pane, and launches Claude with a prompt. Panes are auto-balanced across columns.

```
tangent <branch-name> "<prompt>"
tangent <branch-name>              # resume prior session
```

### `scripts/tangent-close`
Clean up a tangent: kill the pane, remove the worktree, prune git refs.

```
tangent-close <branch>
```

### `scripts/pr-watch`
Poll GitHub for new review comments on open PRs and route them to the Claude session working on that branch.

### `scripts/pr-daemon`
Background daemon that monitors PRs and dispatches review feedback.

## Setup

```bash
# Symlink tmux config
ln -sf $(pwd)/tmux.conf ~/.tmux.conf

# Add scripts to PATH
ln -sf $(pwd)/scripts/tangent ~/.local/bin/tangent
ln -sf $(pwd)/scripts/tangent-close ~/.local/bin/tangent-close
ln -sf $(pwd)/scripts/pr-daemon ~/.local/bin/pr-daemon
ln -sf $(pwd)/scripts/pr-watch ~/.local/bin/pr-watch
```
