#!/usr/bin/env bash
# The right side of the status bar as one job that keeps running. tmux re-ran each widget as its own job
# every status-interval, and a widget now and then drew empty for a frame, so the bar flickered. A job
# that never exits is never re-run, it prints a line every 5 seconds, and each part keeps its last value
set -u
p=$HOME/.tmux/plugins
cpu='' mem='' load='' wx='' bicon='' bpct='' vpn='' net=''

# Prints a widget's output, or the last one it gave when this read came back empty
read_into() {
  local v
  v=$("${@:2}" 2>/dev/null)
  if [[ -n $v ]]; then
    printf -v "$1" '%s' "$v"
  fi
}

while true; do
  # Stops once the server is gone or the status bar no longer runs this script, such as after a config change
  if ! tmux show -gv status-right 2>/dev/null | grep -q 'stats\.sh'; then
    exit 0
  fi

  read_into cpu "$HOME/.tmux/stat-pad.sh" cpu 10
  read_into mem "$HOME/.tmux/stat-pad.sh" mem 13
  read_into load "$p/tmux-plugin-sysstat/scripts/loadavg.sh"
  read_into wx "$p/tmux-weather/scripts/forecast.sh"
  read_into bicon "$p/tmux-battery/scripts/battery_icon.sh"
  read_into bpct "$p/tmux-battery/scripts/battery_percentage.sh"
  read_into vpn "$p/tmux-vpn-status/scripts/vpn.sh"
  read_into net "$p/tmux-online-status/scripts/online_status_icon.sh"
  printf '%s | %s | %s | #[fg=#{@thm_purple}]%s#[default] | %s |  %s %s  | VPN: %s | %s \n' \
    "$cpu" "$mem" "$load" "$(date '+%b %d %H:%M')" "$wx" "$bicon" "$bpct" "$vpn" "$net"
  sleep 5
done
