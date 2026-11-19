#!/usr/bin/env bats

# A throwaway HOME, and a private socket folder so the script can never reach the tmux server you work in
setup() {
  bin="$BATS_TEST_DIRNAME/../bin/install/tmux-host"
  export HOME="$BATS_TEST_TMPDIR/home"
  export TMUX_TMPDIR="$BATS_TEST_TMPDIR/sockets"
  mkdir -p "$HOME" "$TMUX_TMPDIR"
  printf '# the server own config\nset -g mouse on\n' >"$HOME/.tmux.conf"
  printf '# the server own bashrc\n' >"$HOME/.bashrc"
}

@test "first run writes the config and adds one source line, keeping what was there" {
  run "$bin"
  [ "$status" -eq 0 ]
  grep -qxF "set -g set-titles-string '#{pane_title}'" "$HOME/.tmux/agents-host.conf"
  [ "$(head -2 "$HOME/.tmux.conf")" = "$(printf '# the server own config\nset -g mouse on')" ]
  [ "$(grep -c 'agents-host.conf' "$HOME/.tmux.conf")" -eq 1 ]
  [ "$(grep -c 'agents-host-title.sh' "$HOME/.bashrc")" -eq 1 ]
}

@test "a second run changes nothing" {
  "$bin"
  before=$(cat "$HOME/.tmux.conf" "$HOME/.bashrc" "$HOME/.tmux/agents-host.conf" "$HOME/.tmux/agents-host-title.sh")
  run "$bin"
  [ "$status" -eq 0 ]
  [[ $output != *wrote:* && $output != *added:* ]]
  [ "$before" = "$(cat "$HOME/.tmux.conf" "$HOME/.bashrc" "$HOME/.tmux/agents-host.conf" "$HOME/.tmux/agents-host-title.sh")" ]
}

@test "an older managed config is replaced, not appended to" {
  "$bin"
  printf 'set -g set-titles off\n' >"$HOME/.tmux/agents-host.conf"
  run "$bin"
  [[ $output == *"wrote: $HOME/.tmux/agents-host.conf"* ]]
  ! grep -q 'set-titles off' "$HOME/.tmux/agents-host.conf"
}

@test "a rewrite keeps the file mode and leaves no temp files" {
  chmod 640 "$HOME/.bashrc"
  "$bin"
  [ "$(stat -f %Lp "$HOME/.bashrc" 2>/dev/null || stat -c %a "$HOME/.bashrc")" = 640 ]
  [ "$(cd "$HOME" && find . -type f | sort | tr '\n' ' ')" = "./.bashrc ./.tmux.conf ./.tmux/agents-host-title.sh ./.tmux/agents-host.conf " ]
}

@test "the bash hook titles the pane user@host: dir over ssh" {
  "$bin"
  out=$(SSH_CONNECTION=x HOSTNAME=legion.lan bash -c ". $HOME/.tmux/agents-host-title.sh; cd /tmp; eval \"\$PROMPT_COMMAND\"")
  [ "$out" = "$(printf '\033]2;%s@legion: /tmp\a' "$USER")" ]
}
