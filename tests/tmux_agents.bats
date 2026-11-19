#!/usr/bin/env bats

setup() {
  bin="$BATS_TEST_DIRNAME/../home/.tmux/tmux-agents"
  fx="$BATS_TEST_DIRNAME/fixtures/tmux-agents"
}

@test "a Claude spinner line reads as working" {
  run "$bin" classify < "$fx/working.txt"
  [ "$output" = working ]
}

@test "a Codex spinner line reads as working" {
  run "$bin" classify < "$fx/codex-working.txt"
  [ "$output" = working ]
}

@test "a permission menu reads as blocked" {
  run "$bin" classify < "$fx/blocked.txt"
  [ "$output" = blocked ]
}

@test "a finished turn reads as nothing, so the caller decides idle" {
  run "$bin" classify < "$fx/idle.txt"
  [ -z "$output" ]
}

@test "ssh hosts follow Include and skip patterns" {
  # Include paths resolve from ~/.ssh, so point HOME at the fixtures
  mkdir -p "$BATS_TEST_TMPDIR/.ssh"
  cp -R "$fx/ssh.d" "$BATS_TEST_TMPDIR/.ssh/"
  HOME="$BATS_TEST_TMPDIR" TMUX_AGENTS_SSH_CONFIG="$fx/ssh_config" run "$bin" hosts
  [ "$output" = "$(printf '100.98.64.77\nm1-max\nm1\nlegion')" ]
}
