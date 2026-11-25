#!/usr/bin/env bash
# Runs a tmux-plugin-sysstat widget and pads it to a fixed width, so a value that grows a digit does not
# shift the rest of the status bar. Only visible text counts, not the #[...] colour codes: stat-pad.sh cpu 10
set -u
out=$("$HOME/.tmux/plugins/tmux-plugin-sysstat/scripts/${1:?usage: stat-pad.sh cpu|mem width}.sh" 2>/dev/null)
visible=$(printf '%s' "$out" | sed 's/#\[[^]]*\]//g')
pad=$(( ${2:?usage: stat-pad.sh cpu|mem width} - ${#visible} ))
if (( pad > 0 )); then
  printf '%*s' "$pad" ''
fi
printf '%s' "$out"
