set dotenv-load

_default:
  just --list

# Run macos setup
[confirm("Setup Mac? This should be only done on a fresh install. (y/n)")]
setup:
  ./macos

# Sync dotfiles to home directory
[confirm("This may overwrite existing files in your home directory. Are you sure? (y/n)")]
sync:
  #!/usr/bin/env bash
  if [ -d "private/bin" ]; then
    rm -Rf home/.bin/
    rsync private/bin/ home/.bin/ --exclude ".git/" --exclude ".DS_Store" -avh --no-perms;
  fi

  rsync home/. ~ --exclude ".git/" --exclude ".DS_Store" -avh --no-perms;
  exec $SHELL -l

[confirm("Install brew dependencies? (y/n)")]
_brew:
  ./bin/install/brew

[confirm("Install fonts? (y/n)")]
_fonts:
  ./bin/install/fonts

[confirm("Install brew cask apps? (y/n)")]
_cask:
  ./bin/install/cask

[confirm("Install coding agents and skills? (y/n)")]
_agents:
  ./bin/install/agents

[confirm("Run security audit for install script? (y/n)")]
_security:
  ./bin/install/security-audit

# Run strict security audit (fails on non-ignored risky patterns)
security-strict:
  ./bin/install/security-audit --strict

[confirm("Install cron jobs? (y/n)")]
_cron:
  ./private/install/cron

# Install <target>, options: [brew, fonts, cask, agents, security, cron]
install target:
  just _{{ target }} || echo "Invalid install"

# Run mackup backup & uninstall due to https://github.com/lra/mackup/issues/1924#issuecomment-1743072813
[confirm("Run mackup backup & uninstall? (y/n)")]
backup:
  @echo "\n\033[1mBacking up...\n"
  mackup backup --force
  @echo "\n\033[1mUninstalling...\n"
  mackup uninstall --force

# Restore mackup backup
[confirm("Restore mackup backup? This should be only done on a fresh install. (y/n)")]
restore:
  mackup restore

_backup-test args="":
    mackup backup --dry-run {{ args }}

_restore-test args="":
    mackup restore --dry-run {{ args }}

# Test mackup, options [backup, restore]
test target args="":
    just _{{ target }}-test {{ args }}  || echo "Invalid test"
