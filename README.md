# Gabriel's dotfiles

My dotfiles, mac setup, apps & backups configs.

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. This config uses [zsh](http://www.zsh.org), [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) and [tmux](https://github.com/tmux/tmux), if you don't want to use any of those, check [Brew install file](./bin/install/brew).

## Dependencies
 - [Just command runner](https://github.com/casey/just)
 - [Brew](https://brew.sh) (mac setup)

## Instructions

Read [all](./bin/install/) scripts *before* executing them.

1. Configure iCloud, SSH, etc.
2. `git clone https://github.com/gabrielkoerich/dotfiles.git`
3. `just setup` to setup macos
4. `just install brew` to install brew & dependencies
5. `just install fonts` to install fonts
6. `just install cask` to install cask apps
7. `just install agents` to install coding agents & base skills
8. `just sync` to sync the dotfiles to `~`
9. Run `just restore` to restore app settings

To sync the dotfiles, run step 8 again.
Note: sync intentionally excludes `~/.ssh` so keys and SSH host/user config stay local. Public SSH hardening template is versioned at `home/.config/ssh/sshd-hardening.public.conf`.

## Dotfiles Sync

Main config coverage:

- Shell:
  - `home/.zshrc`
  - `home/.zprofile`
  - `home/.aliases`
  - `home/.functions`
  - `home/.exports`
  - `home/.path`
- Tmux:
  - `home/.tmux.conf`
  - `home/.tmux/*` helpers (`renew.sh`, `yank.sh`, remote profile)
  - `home/.tmux/tmx` session helper
- Neovim:
  - `home/.config/nvim`
- Terminal:
  - `home/.config/ghostty`
- Mackup:
  - `home/.mackup.cfg`
  - `home/.mackup/*.cfg`
- Agent tooling:
  - `home/.codex`
  - `home/.claude`
  - `home/.config/opencode`
- SSH templates:
  - `home/.config/ssh/sshd-hardening.public.conf`
  - `home/.config/ssh/sshd-hardening.tailscale.conf`

If you want to skip parts of this setup, selectively run install targets and remove unneeded config files before `just sync`.

### Available Just commands

```bash
backup              # Run mackup backup & uninstall
doctor              # Validate tooling + pinned refs + security files
exact-apply         # Apply closest deterministic machine baseline
exact-check         # Check drift against repo baseline
install target      # Install <target>, options: [brew, fonts, cask, agents, security, cron]
install-profile     # Install package set from profiles/*.txt
install-report      # Generate machine/tool report in .build/reports/
pre-commit-install  # Install local pre-commit hooks
pre-commit-run      # Run pre-commit checks on all files
restore             # Restore mackup backup
security-all        # Audit dotfiles scripts including vendored private/
security-ci         # Run strict audit with semgrep required (CI-equivalent)
security-strict     # Run strict repo-wide security audit
setup               # Run macos setup
sync                # Sync dotfiles to home directory
test target args="" # Test mackup, options [backup, restore]
test-install        # Run bats tests for install/security scripts

# Encrypted file workflows (age)
crypto-keygen
encrypt-file <in> <out.age>
decrypt-file <in.age> <out>
encrypt-dir <src-dir> <out.tar.age>
decrypt-dir <in.tar.age> <out-dir>
```

Encryption commands use `AGE_RECIPIENT` when set; otherwise they derive the recipient from `AGE_KEY_FILE` (default: `~/.config/age/dotfiles.agekey`).

## Security Tooling

- `bin/security-audit`: repo-wide shell/security audit (`--strict` for CI mode)
- `.github/workflows/security-audit.yml`: strict security checks on push/PR
- `.github/workflows/quality.yml`: matrix quality checks (shell syntax, strict audit, tests, gitleaks)
- `.pre-commit-config.yaml`: local hooks for hygiene + secrets + strict audit
- `.gitleaks.toml`: secrets scanning configuration

Recommended bootstrap:

1. `brew bundle --file Brewfile`
2. `just pre-commit-install`
3. `just security-ci`
4. `just doctor`

## Exact Machine Baseline

Goal: reproduce the closest deterministic match from this repository.

- `just exact-apply`: applies Brewfile (with cleanup), fonts, agents, dotfiles sync, and final checks.
- `just exact-check`: verifies drift against Brewfile + doctor + strict security audit.

Important limits:

1. macOS version/hardware-specific defaults may differ.
2. App-internal state and cloud-synced settings may differ.
3. External services and credentials are not reproduced automatically.

## Agent Skills Supply-Chain Policy

`bin/install/agents` installs external repositories at pinned commit SHAs:

- `gabrielkoerich/orchestrator`
- `gabrielkoerich/skills`
- `anthropics/skills`

To update a pin safely:

1. Review upstream changes.
2. Update the ref constant in `bin/install/agents`.
3. Run `just security-strict`.
4. Re-run `just install agents` on a clean machine/test profile.

## Public Repo + Encrypted Files

You can safely keep encrypted artifacts in a public repository if:

1. plaintext never gets committed
2. private key is stored outside git
3. encryption keys/recipients are rotated when needed

This repo uses `age` helpers in `bin/crypto/` and ignores common plaintext/decrypted artifacts in `.gitignore`.

Suggested layout:

- `secrets/encrypted/*.age` committed
- `secrets/plain/*` local-only (ignored)
- key in `~/.config/age/dotfiles.agekey` (ignored)

## Tmux Workflow

- Defined prefix: `ctrl + A`
- Split horizontal: `prefix + |`
- Split vertical: `prefix + _`

The tmux config now supports durable sessions:

- Manual save: `prefix + S`
- Manual restore: `prefix + T`
- Auto-save: every 15 minutes (`tmux-continuum`)
- Auto-restore on tmux start (`tmux-continuum` + `tmux-resurrect`)

Helper command:

- `~/.tmux/tmx` -> ensures/attaches to a long-lived `main` session
- `~/.tmux/tmx ensure` -> creates `main` session if missing, without attaching

Optional env overrides:

- `TMX_SESSION_NAME` (default: `main`)
- `TMX_SESSION_ROOT` (default: `$HOME`)

## Tailscale Hardening Template

Install and sign in:

1. `brew install --cask tailscale`
2. `tailscale up --ssh`

Apply the Tailscale-only SSH hardening template:

1. `just tailscale-ssh-harden` (uses `whoami` for `__SSH_USER__`)
2. Optional manual path:
   `export SSH_USER="<your-user>"`
   `sed "s/__SSH_USER__/${SSH_USER}/g" home/.config/ssh/sshd-hardening.tailscale.conf | sudo tee /etc/ssh/sshd_config.d/99-tailscale-hardening.conf >/dev/null`
   `sudo sshd -t`
   `sudo launchctl kickstart -k system/com.openssh.sshd`

Verify from a non-Tailscale network that SSH is denied, then verify access via Tailscale still works.

### Termius Setup

Recommended path: SSH over Tailscale, then attach to tmux.

1. Enable SSH on Mac:
   `sudo systemsetup -setremotelogin on`
2. Create/import a dedicated SSH key in Termius.
3. Add Termius public key to Mac:
   `mkdir -p ~/.ssh && chmod 700 ~/.ssh`
   append key to `~/.ssh/authorized_keys`
   `chmod 600 ~/.ssh/authorized_keys`
4. Harden SSH on Mac (`/etc/ssh/sshd_config`):
   - `PasswordAuthentication no`
   - `PubkeyAuthentication yes`
   - `PermitRootLogin no`
   - `AllowUsers <your-user>`
5. Restart SSH service (or reboot).
6. In Termius, connect using:
   - Host: Mac LAN/Tailscale IP
   - User: your macOS user
   - Auth: the key from step 2
7. Attach persistent session:
   `tmx`

Notes:
- If you do not use Tailscale, ensure firewall/network rules allow SSH.
- Keep key-only auth (disable password auth).

## License

#### The MIT License (MIT)

Copyright (c) Gabriel Koerich

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
