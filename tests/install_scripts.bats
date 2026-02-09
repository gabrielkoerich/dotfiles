#!/usr/bin/env bats

@test "install scripts parse with bash -n" {
  run bash -n bin/install/agents
  [ "$status" -eq 0 ]

  run bash -n bin/install/security-audit
  [ "$status" -eq 0 ]

  run bash -n bin/install/doctor
  [ "$status" -eq 0 ]
}

@test "security audit strict exits 0" {
  run ./bin/install/security-audit --strict
  [ "$status" -eq 0 ]
}
