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

# Enable VPN proxy (decrypt creds, start gluetun, set macOS system proxy).
[group('proxy')]
proxy-enable:
    #!/usr/bin/env bash
    set -euo pipefail
    proxy_dir="$HOME/.config/proxy"
    env_file="$proxy_dir/.env"
    encrypted="$proxy_dir/vpn.env.age"

    if [ ! -f "$env_file" ]; then
      if [ -f "$encrypted" ]; then
        echo "decrypting vpn credentials..."
        ./bin/crypto/decrypt-file "$encrypted" "$env_file"
      else
        echo "error: no $env_file or $encrypted found" >&2
        echo "create $env_file with VPN_PROVIDER, VPN_USERNAME, VPN_PASSWORD, VPN_COUNTRIES, VPN_TIMEZONE" >&2
        exit 1
      fi
    fi

    echo "starting gluetun..."
    docker compose -f "$proxy_dir/compose.yml" --env-file "$env_file" up -d

    echo "waiting for proxy to be ready..."
    for i in $(seq 1 15); do
      if curl -sf --connect-timeout 2 -x http://127.0.0.1:8888 http://httpbin.org/ip >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done

    echo "setting macOS system proxy (HTTP + SOCKS)..."
    net_service="$(networksetup -listallnetworkservices | grep -m1 'Wi-Fi\|Ethernet')"
    sudo networksetup -setwebproxy "$net_service" 127.0.0.1 8888
    sudo networksetup -setsecurewebproxy "$net_service" 127.0.0.1 8888
    sudo networksetup -setwebproxystate "$net_service" on
    sudo networksetup -setsecurewebproxystate "$net_service" on
    echo "proxy enabled (HTTP: 8888, Shadowsocks: 8388)"

# Disable VPN proxy (unset macOS system proxy, stop gluetun).
[group('proxy')]
proxy-disable:
    #!/usr/bin/env bash
    set -euo pipefail
    proxy_dir="$HOME/.config/proxy"

    echo "unsetting macOS system proxy..."
    net_service="$(networksetup -listallnetworkservices | grep -m1 'Wi-Fi\|Ethernet')"
    sudo networksetup -setwebproxystate "$net_service" off
    sudo networksetup -setsecurewebproxystate "$net_service" off

    echo "stopping gluetun..."
    docker compose -f "$proxy_dir/compose.yml" down

    echo "proxy disabled"

# Encrypt VPN credentials for safe storage in the repo.
[group('proxy')]
proxy-encrypt:
    #!/usr/bin/env bash
    set -euo pipefail
    proxy_dir="$HOME/.config/proxy"
    env_file="$proxy_dir/.env"
    encrypted="$proxy_dir/vpn.env.age"
    if [ ! -f "$env_file" ]; then
      echo "error: $env_file not found" >&2
      exit 1
    fi
    ./bin/crypto/encrypt-file "$env_file" "$encrypted"
    echo "encrypted vpn creds: $encrypted"

# Scan $HOME for exposed secrets and update ~/.config/vault/paths.
[group('security')]
vault-scan:
    #!/usr/bin/env bash
    set -euo pipefail
    config="$HOME/.config/vault/paths"
    mkdir -p "$(dirname "$config")"
    touch "$config"

    found=0
    add_path() {
      local p="$1"
      local label="$2"
      # normalize to $HOME prefix for the config file
      local entry="\$HOME/${p#$HOME/}"
      if ! grep -qF "$entry" "$config"; then
        echo "$entry" >> "$config"
        echo "  added: $entry ($label)"
        found=$((found + 1))
      fi
    }

    echo "scanning for exposed secrets..."

    # check candidates from local config
    candidates_file="$HOME/.config/vault/scan-candidates"
    if [ -f "$candidates_file" ]; then
      while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        type="${line%%:*}"
        raw="${line#*:}"
        p="$(eval echo "$raw")"
        case "$type" in
          f) [ -f "$p" ] && add_path "$p" "candidate" ;;
          d) [ -d "$p" ] && add_path "$p" "candidate" ;;
          g) file="${p%%:*}"; pattern="${p#*:}"; [ -f "$file" ] && grep -q "$pattern" "$file" 2>/dev/null && add_path "$file" "candidate" ;;
        esac
      done < "$candidates_file"
    fi

    # scan shell files for exported secrets
    for f in "$HOME/.exports" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.extra" "$HOME/.private"; do
      if [ -f "$f" ] && grep -qiE '(API_KEY|SECRET|TOKEN|PASSWORD|PRIVATE_KEY)=' "$f" 2>/dev/null; then
        add_path "$f" "secrets in shell config"
      fi
    done

    # scan for private keys (PEM, age, solana-style JSON arrays)
    while IFS= read -r -d '' keyfile; do
      dir="$(dirname "$keyfile")"
      add_path "$dir" "private key found"
    done < <(grep -rlZ --include='*.pem' --include='*.key' --include='*.p12' -e 'PRIVATE KEY' "$HOME/.config" "$HOME/.local" 2>/dev/null || true)

    if [ "$found" -eq 0 ]; then
      echo "no new paths found — vault config is up to date"
    else
      echo ""
      echo "added $found new path(s) to $config"
    fi

# Lock down sensitive files before a call/screen share (passphrase-encrypted).
[confirm("Encrypt and remove all sensitive files from disk? (y/n)")]
[group('security')]
lockdown:
    #!/usr/bin/env bash
    set -euo pipefail
    vault="$HOME/.vault.tar.age"
    manifest="$HOME/.vault-manifest"

    if [ -f "$vault" ]; then
      echo "error: $vault already exists — already locked? run 'just unlock' first" >&2
      exit 1
    fi

    # read sensitive paths from local config (not committed)
    config="$HOME/.config/vault/paths"
    if [ ! -f "$config" ]; then
      echo "error: $config not found" >&2
      echo "create it with one sensitive path per line (supports ~ and \$HOME)" >&2
      exit 1
    fi

    paths=()
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      expanded="$(eval echo "$line")"
      if [ -e "$expanded" ]; then
        paths+=("$expanded")
      fi
    done < "$config"

    # collect .env files from ~/Projects
    while IFS= read -r -d '' envfile; do
      paths+=("$envfile")
    done < <(find "$HOME/Projects" -name '.env' -type f -print0 2>/dev/null)

    if [ ${#paths[@]} -eq 0 ]; then
      echo "nothing to lock — no sensitive files found"
      exit 0
    fi

    echo "locking ${#paths[@]} sensitive path(s):"
    printf '  %s\n' "${paths[@]}"

    # save manifest for unlock
    printf '%s\n' "${paths[@]}" > "$manifest"

    # tar relative to $HOME so we can restore in place
    echo ""
    echo "enter a passphrase to encrypt the vault:"
    tar -cf - -C "$HOME" "${paths[@]/#$HOME\//}" | age -p -o "$vault"

    # verify the vault was created before removing
    if [ ! -f "$vault" ]; then
      echo "error: vault not created, aborting — files are safe" >&2
      rm -f "$manifest"
      exit 1
    fi

    # remove originals (using trash for safety during early iterations)
    for p in "${paths[@]}"; do
      trash "$p"
    done

    echo ""
    echo "locked. sensitive files encrypted to $vault"
    echo "run 'just unlock' with your passphrase to restore"
    echo ""
    read -p "empty trash now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      osascript -e 'tell application "Finder" to empty the trash'
      echo "trash emptied"
    fi

# Restore sensitive files after a call/screen share.
[group('security')]
unlock:
    #!/usr/bin/env bash
    set -euo pipefail
    vault="$HOME/.vault.tar.age"
    manifest="$HOME/.vault-manifest"

    if [ ! -f "$vault" ]; then
      echo "error: $vault not found — not locked?" >&2
      exit 1
    fi

    echo "enter your passphrase to decrypt the vault:"
    age --decrypt -o - "$vault" | tar -xf - -C "$HOME"

    rm -f "$vault" "$manifest"
    echo "unlocked. all sensitive files restored"


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
