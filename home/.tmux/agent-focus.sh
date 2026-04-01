#!/usr/bin/env bash
# Clears window tab blink when the pane is focused.

PANE="${1:-$TMUX_PANE}"
[ -z "$PANE" ] && exit 0

WIN_ID=$(tmux display-message -t "$PANE" -p '#{window_id}' 2>/dev/null)
tmux set-window-option -t "$WIN_ID" -u window-status-style 2>/dev/null || true
tmux refresh-client -S 2>/dev/null || true
