#!/bin/bash
# pane-layout.sh — shared column management for tangent, pushpane, pullpane.
# Source this file; do not execute directly.

MIN_PANE_HEIGHT=8

# ── Pane identification ───────────────────────────────────────────────────

resolve_pane() {
    # Resolve a pane argument: pane ID (%42), tmux target (0.9, window.pane),
    # @label, or empty (current pane).
    local arg="${1:-}"
    if [[ -z "$arg" ]]; then
        # Default to current pane
        tmux display-message -p '#{pane_id}'
        return
    fi
    if [[ "$arg" == %* ]]; then
        echo "$arg"
        return
    fi
    # Try as tmux pane target (e.g., 0.9, @0.3, window:pane)
    local resolved
    resolved=$(tmux display-message -t "$arg" -p '#{pane_id}' 2>/dev/null)
    if [[ -n "$resolved" ]]; then
        echo "$resolved"
        return
    fi
    # Match by @label
    local match
    match=$(tmux list-panes -a -F '#{pane_id} #{@label}' | awk -v b="$arg" '$2 == b {print $1; exit}')
    if [[ -n "$match" ]]; then
        echo "$match"
        return
    fi
    echo "pane-layout: cannot resolve pane '$arg'" >&2
    return 1
}

# ── Column detection (scoped to a window) ─────────────────────────────────

# All functions below operate on the window passed as $1 or default to current.

_panes_by_column() {
    local win="${1:-$(tmux display-message -p '#{window_id}')}"
    tmux list-panes -t "$win" -F '#{pane_id} #{pane_left} #{pane_top} #{pane_width} #{pane_height}' \
        | sort -k2,2n -k3,3n | awk '
    {
        id=$1; x=$2; y=$3; w=$4; h=$5
        if (NR == 1 || x != prev_x) { col++ }
        prev_x = x
        print col, id, y, h
    }'
}

n_cols() {
    local win="${1:-$(tmux display-message -p '#{window_id}')}"
    _panes_by_column "$win" | awk '{print $1}' | sort -u | wc -l
}

col_pane_count() {
    local col="$1" win="${2:-$(tmux display-message -p '#{window_id}')}"
    _panes_by_column "$win" | awk -v c="$col" '$1 == c' | wc -l
}

col_pane_ids() {
    local col="$1" win="${2:-$(tmux display-message -p '#{window_id}')}"
    _panes_by_column "$win" | awk -v c="$col" '$1 == c {print $2}'
}

col_bottom_pane() {
    local col="$1" win="${2:-$(tmux display-message -p '#{window_id}')}"
    _panes_by_column "$win" | awk -v c="$col" '$1 == c {last=$2} END {print last}'
}

col_total_height() {
    local col="$1" win="${2:-$(tmux display-message -p '#{window_id}')}"
    local total=0 n=0
    while IFS=' ' read -r c pid ptop pheight; do
        if [[ "$c" == "$col" ]]; then
            total=$((total + pheight))
            n=$((n + 1))
        fi
    done <<< "$(_panes_by_column "$win")"
    echo $((total + n - 1))
}

equalize_column() {
    local col="$1" win="${2:-$(tmux display-message -p '#{window_id}')}"
    local pane_ids=($(col_pane_ids "$col" "$win"))
    local n=${#pane_ids[@]}
    [[ $n -le 1 ]] && return

    local total_h=0
    while IFS=' ' read -r c pid ptop pheight; do
        if [[ "$c" == "$col" ]]; then
            total_h=$((total_h + pheight))
        fi
    done <<< "$(_panes_by_column "$win")"
    total_h=$((total_h + n - 1))
    local per_pane=$((total_h / n))

    for ((i=0; i < n-1; i++)); do
        tmux resize-pane -t "${pane_ids[$i]}" -y "$per_pane" 2>/dev/null || true
    done
}

# ── Column selection ──────────────────────────────────────────────────────

# Pick the best column to add a pane to (least-loaded, respecting min height).
# Returns column number or empty string if all full.
pick_target_col() {
    local win="${1:-$(tmux display-message -p '#{window_id}')}"
    local ncols=$(n_cols "$win")
    local win_height=$(tmux display-message -t "$win" -p '#{window_height}')
    local max_col_panes=$(( win_height / (MIN_PANE_HEIGHT + 1) ))
    [[ $max_col_panes -lt 2 ]] && max_col_panes=2

    local best_col="" best_count=999
    for col in $(seq 2 "$ncols"); do
        local count=$(col_pane_count "$col" "$win")
        local height=$(col_total_height "$col" "$win")
        local per_pane=$(( (height - count) / (count + 1) ))
        if [[ $per_pane -lt $MIN_PANE_HEIGHT ]]; then
            continue
        fi
        if [[ $count -lt $max_col_panes && $count -lt $best_count ]]; then
            best_col=$col
            best_count=$count
        fi
    done
    echo "$best_col"
}

# ── Window management ─────────────────────────────────────────────────────

SECONDARY_WINDOW_NAME="overflow"

ensure_secondary_window() {
    # Create the secondary window if it doesn't exist. Returns its window_id.
    local existing
    existing=$(tmux list-windows -F '#{window_id} #{window_name}' \
        | awk -v n="$SECONDARY_WINDOW_NAME" '$2 == n {print $1; exit}')
    if [[ -n "$existing" ]]; then
        echo "$existing"
        return
    fi
    # Create new window (don't switch to it)
    tmux new-window -d -n "$SECONDARY_WINDOW_NAME" -P -F '#{window_id}'
}

get_primary_window() {
    # Primary is window index 0 (or the first window)
    tmux list-windows -F '#{window_id} #{window_index}' | awk '$2 == 0 {print $1; exit}'
}
