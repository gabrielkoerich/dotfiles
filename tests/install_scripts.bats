#!/usr/bin/env bats

@test "install scripts parse with bash -n" {
  run bash -n bin/install/agents
  [ "$status" -eq 0 ]

  run bash -n bin/security-audit
  [ "$status" -eq 0 ]

  run bash -n bin/doctor
  [ "$status" -eq 0 ]
}

@test "security audit strict exits 0" {
  run ./bin/security-audit --strict
  [ "$status" -eq 0 ]
}
