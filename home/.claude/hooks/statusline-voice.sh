#!/usr/bin/env bash
# Wraps the statusbar plugin to append a voice segment, because its widget list
# is fixed and an update would overwrite a patched file
set -uo pipefail

# Newest version dir, so a plugin upgrade does not leave this pointing at a
# path that no longer exists
PLUGIN="$(ls -1d "$HOME"/.claude/plugins/cache/claude-statusbar/statusbar/*/scripts/statusline.js 2>/dev/null | sort -V | tail -1)"
DATA="$HOME/.claude/plugins/data/statusbar-claude-statusbar"
STATE="$HOME/.claude/voice-reply.state"
QUEUE="/tmp/claude-voice-reply.queue"
LOCK="/tmp/claude-voice-reply.lock"

payload="$(cat)"
if [ -n "$PLUGIN" ] && [ -f "$PLUGIN" ]; then
  bar="$(printf '%s' "$payload" | node "$PLUGIN" --data-dir "$DATA" 2>/dev/null)"
else
  bar=""
fi

if [ "$(cat "$STATE" 2>/dev/null)" = "on" ]; then
  waiting=0
  if [ -s "$QUEUE" ]; then
    waiting="$(awk 'NF' "$QUEUE" 2>/dev/null | wc -l | tr -d ' ')"
  fi
  # A held lock means something is speaking now
  if [ -f "$LOCK" ] && lsof -t "$LOCK" >/dev/null 2>&1; then
    voice=$'\033[32m\xf0\x9f\x94\x8a speaking\033[0m'
    [ "$waiting" -gt 0 ] && voice=$'\033[32m\xf0\x9f\x94\x8a speaking +'"$waiting"$'\033[0m'
  else
    voice=$'\033[90m\xf0\x9f\x94\x8a\033[0m'
  fi
else
  voice=$'\033[90m\xf0\x9f\x94\x87 paused\033[0m'
fi

printf '%s' "$bar"
printf ' \033[90m|\033[0m %s\n' "$voice"
