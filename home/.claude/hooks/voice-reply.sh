#!/usr/bin/env bash
# Toggles spoken replies and pins the voice, the Stop hook reads these state files
set -euo pipefail
STATE="$HOME/.claude/voice-reply.state"
VOICEPIN="$HOME/.claude/voice-reply.voice"
SPEEDFILE="$HOME/.claude/voice-reply.speed"
LIMITFILE="$HOME/.claude/voice-reply.limit"
QUEUE="/tmp/claude-voice-reply.queue"
LOCKF="/tmp/claude-voice-reply.lock"
case "${1:-status}" in
  on|resume)  echo on > "$STATE"; echo "voice replies on" ;;
  off|pause)  echo off > "$STATE"; pkill -x afplay 2>/dev/null || true; : > "$QUEUE"; echo "voice replies paused" ;;
  skip)  pkill -x afplay 2>/dev/null || true; echo "skipped the one speaking" ;;
  toggle)
    if [ "$(cat "$STATE" 2>/dev/null)" = "on" ]; then
      echo off > "$STATE"; pkill -x afplay 2>/dev/null || true; : > "$QUEUE"; echo "paused"
    else
      echo on > "$STATE"; echo "on"
    fi ;;
  icon)
    if [ "$(cat "$STATE" 2>/dev/null)" = "on" ]; then
      if [ -f "$LOCKF" ] && lsof -t "$LOCKF" >/dev/null 2>&1; then printf '\xf0\x9f\x94\x8a>'; else printf '\xf0\x9f\x94\x8a'; fi
    else
      printf '\xf0\x9f\x94\x87'
    fi ;;
  voice) echo "${2:-random}" > "$VOICEPIN"; echo "voice: ${2:-random}" ;;
  speed) echo "${2:-1.0}" > "$SPEEDFILE"; echo "speed: ${2:-1.0}" ;;
  limit) echo "${2:-full}" > "$LIMITFILE"; echo "limit: ${2:-full}" ;;
  status)
    printf 'replies: %s\n' "$(cat "$STATE" 2>/dev/null || echo off)"
    printf 'voice:   %s\n' "$(cat "$VOICEPIN" 2>/dev/null || echo random)"
    printf 'speed:   %s\n' "$(cat "$SPEEDFILE" 2>/dev/null || echo 1.0)"
    printf 'limit:   %s\n' "$(cat "$LIMITFILE" 2>/dev/null || echo full)"
    printf 'last:    %s\n' "$(cat /tmp/claude-voice-reply.last 2>/dev/null || echo none)"
    printf 'waiting: %s\n' "$([ -f "$QUEUE" ] && wc -l < "$QUEUE" | tr -d ' ' || echo 0)"
    ;;
  *) echo "usage: voice-reply.sh on|off|pause|resume|toggle|skip|icon|status|voice <name|random>|speed <0.5-2.0>|limit <chars|full>" >&2; exit 1 ;;
esac
