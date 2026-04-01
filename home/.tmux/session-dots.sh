#!/usr/bin/env bash
# Outputs clickable session dots for tmux status bar.
# Active session = filled blue dot, inactive = hollow grey dot.

tmux ls 2>/dev/null | while IFS=: read -r name rest; do
  if echo "$rest" | grep -q "(attached)"; then
    printf "#[range=user,%s]#[fg=colour39]●#[range=default]#[fg=colour245] " "$name"
  else
    printf "#[range=user,%s]#[fg=colour245]○#[range=default] " "$name"
  fi
done
