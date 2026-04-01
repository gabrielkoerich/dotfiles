#!/usr/bin/env bash
# Called by Claude/Codex/OpenCode hooks.
# Blinks the window tab on needs-input (yellow) and done (orange).

[ -z "$TMUX" ]      && exit 0
[ -z "$TMUX_PANE" ] && exit 0

STATE="running"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --state) STATE="$2"; shift 2 ;;
    --agent) shift 2 ;;
    *)       shift ;;
  esac
done

WIN_ID=$(tmux display-message -t "$TMUX_PANE" -p '#{window_id}' 2>/dev/null)

case "$STATE" in
  needs-input) tmux set-window-option -t "$WIN_ID" window-status-style "fg=colour220,blink" 2>/dev/null || true ;;
  done)        tmux set-window-option -t "$WIN_ID" window-status-style "fg=colour166,blink" 2>/dev/null || true ;;
  *)           tmux set-window-option -t "$WIN_ID" -u window-status-style 2>/dev/null || true ;;
esac

tmux refresh-client -S 2>/dev/null || true
