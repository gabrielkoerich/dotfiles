#!/usr/bin/env bash
# Clickable session dots, attached = filled blue, detached = hollow grey
# Ranges carry the session id, names can exceed the 15 byte range limit

tmux ls -F '#{session_id} #{session_attached}' 2>/dev/null | while read -r id attached; do
  if [ "$attached" != "0" ]; then
    printf "#[range=user|%s]#[fg=colour39]●#[norange]#[fg=colour245] " "$id"
  else
    printf "#[range=user|%s]#[fg=colour245]○#[norange] " "$id"
  fi
done
