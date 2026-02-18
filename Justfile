set dotenv-load := true

# Show available Just targets.
_default:
    just --list

# Setup & Sync

# Run macos setup
[confirm("Setup Mac? This should be only done on a fresh install. (y/n)")]
[group('setup')]
setup:
    ./macos

# Sync dotfiles to home directory
[confirm("This may overwrite existing files in your home directory. Are you sure? (y/n)")]
[group('setup')]
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
[group('install')]
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
    ./bin/install/cron

# Install pre-commit hooks locally
[confirm("Install pre-commit? (y/n)")]
_pre-commit:
    pre-commit install

# Install from package profile (profiles/*.txt)
[group('install')]
install-profile profile="minimal":
    ./bin/install/profile "{{ profile }}"

# Apply closest deterministic machine baseline
[group('install')]
exact-apply:
    ./bin/install/exact-apply

# Check machine drift against repo baseline
[group('check')]
exact-check:
    ./bin/exact-check

# Run system/tooling checks
[group('check')]
doctor:
    ./bin/doctor

# Create install report under .build/reports/
[group('check')]
report:
    ./bin/install-report

# Run pre-commit checks on all files
[group('check')]
pre-commit-run:
    pre-commit run --all-files

# Run strict security audit (fails on non-ignored risky patterns)
[group('security')]
security-strict:
    ./bin/security-audit --strict

# Run CI-equivalent security audit (requires semgrep installed)
[group('security')]
security-ci:
    SECURITY_AUDIT_REQUIRE_SEMGREP=1 ./bin/security-audit --strict

# Enable Tailscale SSH (turn on SSH + bring up Tailscale with SSH).
[confirm("Enable SSH and start Tailscale? (y/n)")]
[group('ssh')]
tailscale-ssh-enable:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "enabling remote login (SSH)..."
    sudo systemsetup -setremotelogin on
    echo "starting tailscale with SSH..."
    tailscale up --ssh
    echo "tailscale ssh enabled ($(tailscale ip -4))"

# Disable Tailscale SSH (bring down Tailscale + turn off SSH).
[confirm("Disable SSH and stop Tailscale? (y/n)")]
[group('ssh')]
tailscale-ssh-disable:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "stopping tailscale..."
    tailscale down
    echo "disabling remote login (SSH)..."
    echo 'yes' | sudo systemsetup -setremotelogin off
    echo "tailscale ssh disabled"

# Apply Tailscale-only SSH hardening config using current user from `whoami`.
[confirm("Apply Tailscale SSH hardening config and restart sshd? (y/n)")]
[group('ssh')]
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

# Enable Cloudflare Tunnel SSH (turn on SSH + start tunnel service).
[confirm("Enable SSH and start Cloudflare tunnel? (y/n)")]
[group('ssh')]
cloudflare-ssh-enable:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "enabling remote login (SSH)..."
    sudo systemsetup -setremotelogin on
    echo "installing cloudflared service..."
    cloudflared service install
    echo "cloudflare tunnel ssh enabled"

# Disable Cloudflare Tunnel SSH (stop tunnel service + turn off SSH).
[confirm("Disable SSH and stop Cloudflare tunnel? (y/n)")]
[group('ssh')]
cloudflare-ssh-disable:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "uninstalling cloudflared service..."
    cloudflared service uninstall || true
    echo "disabling remote login (SSH)..."
    echo 'yes' | sudo systemsetup -setremotelogin off
    echo "cloudflare tunnel ssh disabled"

# Apply Cloudflare Tunnel SSH hardening config using current user from `whoami`.
[confirm("Apply Cloudflare Tunnel SSH hardening config and restart sshd? (y/n)")]
[group('ssh')]
cloudflare-ssh-harden:
    #!/usr/bin/env bash
    set -euo pipefail
    user="$(whoami)"
    template="home/.config/ssh/sshd-hardening.cloudflare.conf"
    target="/etc/ssh/sshd_config.d/99-cloudflare-hardening.conf"
    sed "s/__SSH_USER__/${user}/g" "$template" | sudo tee "$target" >/dev/null
    sudo sshd -t
    sudo launchctl kickstart -k system/com.openssh.sshd
    echo "applied cloudflare tunnel ssh hardening for user: $user"

# Generate a local `age` key pair used for encryption workflows.
[group('encryption')]
crypto-keygen:
    ./bin/crypto/keygen

# Encrypt one file to `.age` format.
[group('encryption')]
encrypt-file in out:
    ./bin/crypto/encrypt-file "{{ in }}" "{{ out }}"

# Decrypt one `.age` file to plaintext.
[group('encryption')]
decrypt-file in out:
    ./bin/crypto/decrypt-file "{{ in }}" "{{ out }}"

# Archive and encrypt an entire directory.
[group('encryption')]
encrypt-dir src out:
    ./bin/crypto/encrypt-dir "{{ src }}" "{{ out }}"

# Decrypt and extract an encrypted directory archive.
[group('encryption')]
decrypt-dir in out_dir:
    ./bin/crypto/decrypt-dir "{{ in }}" "{{ out_dir }}"

# Encrypt root `.bin` into `.bin.tar.age`
[group('encryption')]
encrypt-private:
    ./bin/crypto/encrypt-dir private private.tar.age

# Decrypt root `.bin.tar.age` into `home/.bin` when available.
[group('encryption')]
decrypt-private:
    #!/usr/bin/env bash
    if [ -f "private.tar.age" ]; then
      ./bin/crypto/decrypt-dir private.tar.age .
    else
      echo "skip: private.tar.age not found"
    fi

# Run mackup backup (copy mode, no symlinks since 0.9.0)
[confirm("Run mackup backup? (y/n)")]
[group('backup')]
backup:
    mackup backup --force

# Restore mackup backup
[confirm("Restore mackup backup? This should be only done on a fresh install. (y/n)")]
[group('backup')]
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
[group('check')]
test target args="":
    just _{{ target }}-test {{ args }}  || echo "Invalid test"
