set dotenv-load := true

# Show available Just targets.
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
    just decrypt-private || true
    if [ -d "private/bin" ]; then
        rsync private/bin/ home/.bin/ --exclude ".git/" --exclude ".DS_Store" -avh --no-perms;
    fi
    rsync home/. ~ --exclude ".git/" --exclude ".DS_Store" -avh --no-perms;
    rm -Rf private
    exec $SHELL -l

# Install <target>, options: [brew, fonts, cask, agents, security, cron, pre-commit]
install target:
    just _{{ target }} || echo "Invalid install"

# Install Homebrew formulae from `Brewfile` (non-cask entries).
[confirm("Install brew dependencies? (y/n)")]
_brew:
    ./bin/install/brew

# Install local fonts from the repository.
[confirm("Install fonts? (y/n)")]
_fonts:
    ./bin/install/fonts

# Install Homebrew cask applications from `Brewfile`.
[confirm("Install brew cask apps? (y/n)")]
_cask:
    ./bin/install/cask

# Install coding agents and pinned skill repositories.
[confirm("Install coding agents and skills? (y/n)")]
_agents:
    ./bin/install/agents

# Run the repository security audit with default targets.
[confirm("Run security audit for install script? (y/n)")]
_security:
    ./bin/security-audit

# Install/update configured cron jobs.
[confirm("Install cron jobs? (y/n)")]
_cron:
    ./private/install/cron

# Install pre-commit hooks locally
[confirm("Install pre-commit? (y/n)")]
_pre-commit:
    pre-commit install

# Install from package profile (profiles/*.txt)
install-profile profile="minimal":
    ./bin/install/profile "{{ profile }}"

# Run strict security audit (fails on non-ignored risky patterns)
security-strict:
    ./bin/security-audit --strict

# Run CI-equivalent security audit (requires semgrep installed)
security-ci:
    SECURITY_AUDIT_REQUIRE_SEMGREP=1 ./bin/security-audit --strict

# Run system/tooling checks
doctor:
    ./bin/doctor

# Apply closest deterministic machine baseline
exact-apply:
    ./bin/install/exact-apply

# Check machine drift against repo baseline
exact-check:
    ./bin/exact-check

# Create install report under .build/reports/
report:
    ./bin/install-report

# Run pre-commit checks on all files
pre-commit-run:
    pre-commit run --all-files

# Apply Tailscale-only SSH hardening config using current user from `whoami`.
[confirm("Apply Tailscale SSH hardening config and restart sshd? (y/n)")]
tailscale-ssh-harden:
    #!/usr/bin/env bash
    set -euo pipefail
    user="$(whoami)"
    template="home/.config/ssh/sshd-hardening.tailscale.conf"
    target="/etc/ssh/sshd_config.d/99-tailscale-hardening.conf"
    sed "s/__SSH_USER__/${user}/g" "$template" | sudo tee "$target" >/dev/null
    sudo sshd -t
    sudo launchctl kickstart -k system/com.openssh.sshd
    echo "applied tailscale ssh hardening for user: $user"

# Generate a local `age` key pair used for encryption workflows.
crypto-keygen:
    ./bin/crypto/keygen

# Encrypt one file to `.age` format.
encrypt-file in out:
    ./bin/crypto/encrypt-file "{{ in }}" "{{ out }}"

# Decrypt one `.age` file to plaintext.
decrypt-file in out:
    ./bin/crypto/decrypt-file "{{ in }}" "{{ out }}"

# Archive and encrypt an entire directory.
encrypt-dir src out:
    ./bin/crypto/encrypt-dir "{{ src }}" "{{ out }}"

# Decrypt and extract an encrypted directory archive.
decrypt-dir in out_dir:
    ./bin/crypto/decrypt-dir "{{ in }}" "{{ out_dir }}"

# Encrypt root `.bin` into `.bin.tar.age`
encrypt-private:
    ./bin/crypto/encrypt-dir private private.tar.age

# Decrypt root `.bin.tar.age` into `home/.bin` when available.
decrypt-private:
    #!/usr/bin/env bash
    if [ -f "private.tar.age" ]; then
      ./bin/crypto/decrypt-dir private.tar.age .
    else
      echo "skip: private.tar.age not found"
    fi

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

# Dry-run mackup backup to preview changes.
_backup-test args="":
    mackup backup --dry-run {{ args }}

# Dry-run mackup restore to preview changes.
_restore-test args="":
    mackup restore --dry-run {{ args }}

# Run bats tests
_install-test:
    bats tests

# Test install, mackup, options [backup, restore]
test target args="":
    just _{{ target }}-test {{ args }}  || echo "Invalid test"
