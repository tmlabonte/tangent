# tangent

Spawn isolated **GitHub Copilot CLI** sessions for side tasks using git worktrees and tmux — either from the shell (`tangent …`) or with `/tangent:*` slash commands from inside a Copilot session.

> Fork of [JohnLangford/tangent](https://github.com/JohnLangford/tangent), adapted from Claude Code to the GitHub Copilot CLI (`copilot`). Same bash + tmux workflow.

## How it works

`tangent` creates a git worktree on a new branch, opens a tmux pane, and launches Copilot CLI with a prompt. Each tangent runs in its own worktree so it can't interfere with your main working tree. Panes are auto-balanced across tmux columns.

```
tangent <branch-name> "<prompt>"    # start a new side task
tangent <branch-name>               # resume a prior session
```

When the tangent's Copilot session finishes, the worktree contains any changes on its branch, ready for a PR or merge.

## Slash commands (Copilot CLI plugin)

This repo is also a **Copilot CLI plugin** that adds `/tangent` slash commands
you can run from *inside* a Copilot session — so you can spin off a side task
without leaving your current chat, optionally handing off context:

| Command | Context handoff | Use when |
|---|---|---|
| `/tangent:new [branch] [prompt]` | none — blank session | the side task is unrelated; you want a clean slate |
| `/tangent:summary [branch] [prompt]` | a model-written summary of the current chat | **most common** — hand off with just enough context |
| `/tangent:full [branch] [prompt]` | the entire conversation (session fork) | the side task needs the whole context |
| `/tangent:prune [selector]` | — | clean up finished tangent worktrees |

`branch` is optional; when omitted it is auto-named as a kebab-case slug from
the prompt (or the conversation). Every command shells out to the `tangent`
engine (and its `tangent-full` / `tangent-prune` helpers), so behavior matches
the CLI. `/tangent:prune` defaults to an interactive menu; it also takes
`--merged`, `--pushed`, `--orphaned`, `--all`, or `--branch=<name>`.

Load the plugin either way:

```bash
# Dev / local checkout — load straight from this repo:
copilot --plugin-dir /path/to/tangent

# Or install it as a managed plugin (also works as /plugin install inside the CLI):
copilot plugin install tmlabonte/tangent
```

> `/tangent:full` forks the current session by cloning its `session-state`
> under a fresh id (located via `COPILOT_AGENT_SESSION_ID`) and resuming it. It
> depends on Copilot CLI's session-state layout, so it is the most
> version-sensitive piece.

## tmux.conf

Companion tmux configuration: Ctrl-a prefix, sticky pane labels, and a default session layout with a large working pane plus stacked tangent columns.

## Setup

```bash
# Put the tangent engine + helpers on PATH
for s in tangent tangent-full tangent-prune; do
  ln -sf "$(pwd)/$s" ~/.local/bin/"$s"
done

# Load the slash-command plugin (dev: straight from this checkout)…
copilot --plugin-dir "$(pwd)"
# …or install it as a managed plugin: copilot plugin install tmlabonte/tangent

# Optional: use the tmux config
ln -sf "$(pwd)/tmux.conf" ~/.tmux.conf
```

Requires: `git`, `tmux`, `copilot` (GitHub Copilot CLI). The `/tangent:*` slash
commands shell out to the `tangent*` scripts, so those must be on your `PATH`.

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
