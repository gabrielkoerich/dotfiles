# Gabriel's dotfiles

[![Quality](https://github.com/gabrielkoerich/dotfiles/actions/workflows/quality.yml/badge.svg)](https://github.com/gabrielkoerich/dotfiles/actions/workflows/quality.yml)

Dotfiles, mac setup, apps & backups configs.

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. This config uses [zsh](http://www.zsh.org), [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) and [tmux](https://github.com/tmux/tmux), if you don't want to use any of those, check [Brew install file](./bin/install/brew).

## Dependencies
 - [Just command runner](https://github.com/casey/just)
 - [Brew](https://brew.sh) (mac setup)

## Dotfiles Sync

Check [`home`](./home) directory to check everything that is rsynced to `~` directory.

If you want to skip parts of this setup, selectively run install targets and remove unneeded config files before `just sync`.

## Instructions

Read [all](./bin/install/) scripts *before* executing them.

1. Configure iCloud, SSH, etc.
2. `git clone https://github.com/gabrielkoerich/dotfiles.git`
3. `just setup` to setup macos
4. `just install brew` to install brew & dependencies
5. `just install fonts` to install fonts
6. `just install cask` to install cask apps
7. `just install agents` to install coding agents & base skills
8. `just install touchid` to enable Touch ID for `sudo` (also inside tmux)
9. `just sync` to sync the dotfiles to `~`
10. Run `just restore` to restore app settings

To sync the dotfiles, run step 9 again.

Note: sync intentionally excludes `~/.ssh` so keys and SSH host/user config stay local.

### Linux boxes

`just sync` also works on a Linux/bash machine, where only `just` and `rsync` are needed:

- `.path`, `.exports` and `.aliases` guard the macOS-only bits (Homebrew prefix, SDK headers,
  `scutil` proxy lookup, BSD `ls -G`) and add Linux equivalents.
- `.bash_aliases` is the bash entry point: the distro default `~/.bashrc` sources it, and it
  loads `.path`, `.exports`, `.aliases` and `.functions` like `.zshrc` does.
- The private `.bin` merge is skipped when `age` or the key is missing.
- A server that runs agents does not need these dotfiles. `just tmux-host <host>` runs `bin/install/tmux-host` there over ssh: it installs tmux (Homebrew, apt, dnf, pacman or apk), writes `~/.tmux/agents-host.conf` so pane titles reach the Mac, and a hook that titles the shell `user@host: dir`. It only adds one `source` line to the server's own `.tmux.conf` and `.bashrc`, writes every file atomically, and a second run changes nothing. On a server without this repo, fetch it from GitHub. `$(…)` downloads the whole script before it runs, so a dropped connection never runs half of it, and a commit SHA in place of `main` pins the version you reviewed:

  ```sh
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/gabrielkoerich/dotfiles/main/bin/install/tmux-host)"
  ```
- Everything else (`just setup`, `install brew|cask|touchid`, `backup`, `restore`) stays macOS-only.

Encryption commands read the age key from passbox as `age/dotfiles`. `AGE_RECIPIENT` sets the recipient and `AGE_KEY_FILE` uses a plaintext key file instead.

## Security Tooling

- `bin/security-audit`: repo-wide shell/security audit (`--strict` for CI mode)
- `.github/workflows/quality.yml`: quality + security checks (shell syntax, strict audit, semgrep, tests, gitleaks)
- `.pre-commit-config.yaml`: local hooks for hygiene + secrets + strict audit
- `.gitleaks.toml`: secrets scanning configuration

Recommended local checks:

1. `just security-ci`
2. `just doctor`

### Just encryption workflows

```bash
crypto-keygen
encrypt-file <in> <out.age>
decrypt-file <in.age> <out>
encrypt-dir <src-dir> <out.tar.age>
decrypt-dir <in.tar.age> <out-dir>
```

Encryption commands read the age key from passbox as `age/dotfiles`. `AGE_RECIPIENT` sets the recipient and `AGE_KEY_FILE` uses a plaintext key file instead.

## Exact Machine Baseline

Goal: reproduce the closest deterministic match from this repository.

- `just exact-apply`: applies Brewfile (with cleanup), fonts, agents, dotfiles sync, and final checks.
- `just exact-check`: verifies drift against Brewfile + doctor + strict security audit.

Important limits:

1. macOS version/hardware-specific defaults may differ.
2. App-internal state and cloud-synced settings may differ.
3. External services and credentials are not reproduced automatically.

## Agent Instructions

Mackup backs up the agent configs and skills. `~/.claude/CLAUDE.md` is the one instruction file. `bin/install/agents` links `~/.codex/AGENTS.md` and `~/.config/opencode/AGENTS.md` to it. Run it after `mackup restore`, because the restore writes those two files back as copies.

## Tmux Workflow

The prefix is `Ctrl+A`. `prefix + h` opens a cheat sheet of every key, read live from `tmux list-keys -N`, so it lists exactly what is bound. Each binding in `.tmux.conf` carries its note (`bind -N "…"`), so a new key shows up there once it has one.

| Key | Action |
|---|---|
| `prefix + h` | This cheat sheet |
| `prefix + Space` | Go to anywhere: agents, sessions, windows and ssh hosts ([tmux-agents](https://github.com/gabrielkoerich/tmux-agents)) |
| `prefix + a` | Agents sidebar, open or close |
| `prefix + \|` / `prefix + _` | Split side by side / top and bottom, on the server too in an ssh pane |
| `prefix + t` | File tree, of the server in an ssh pane |
| `prefix + n` | New window in this folder |
| `prefix + +` | Zoom the pane in or out |
| `prefix + x` / `prefix + w` | Close the pane / the window, asking first |
| `prefix + r` / `prefix + R` | Rename the window / the session |
| `prefix + C-t` | Colour theme menu: Black, Mocha, Ink |
| `prefix + C-s` | Show or hide the status bar |
| `prefix + C-r` / `prefix + C-e` | Reload tmux.conf / edit it, then reload |
| `Cmd+1` … `Cmd+9`, `prefix + 1` … `5` | The Nth tab |
| `Option+1` … `Option+9` | The Nth item in the sidebar |
| `Shift+←` / `Shift+→` | Previous / next window |
| `Option+arrows` | Move between panes |
| `Option+V` | Spoken replies on or off |
| `F12` | Send keys to a nested tmux, `F12` again to come back |

`@agents-tabs` decides what the tabs on top are. With `sessions` they are your sessions and the sidebar lists the windows of the current one; with `windows` it is the other way round. `Cmd+N` always picks a tab and `Option+N` a sidebar item, so the keys mean the same in both layouts. Ghostty sends `Cmd+N` to tmux as `ESC [ 900N ~`, which needs these lines in `~/.config/ghostty/config`, `digit_N` since Ghostty matches the physical key first:

```
keybind = cmd+digit_1=text:\x1b[9001~
…
keybind = cmd+digit_9=text:\x1b[9009~
```

The tmux config now supports durable sessions:

- Manual save: `prefix + S`
- Manual restore: `prefix + T`
- Auto-save: every 15 minutes (`tmux-continuum`)
- Auto-restore on tmux start (`tmux-continuum` + `tmux-resurrect`)

Helper command:

- `~/.tmux/tmx` -> ensures/attaches to a long-lived `main` session
- `~/.tmux/tmx ensure` -> creates `main` session if missing, without attaching
- `~/.tmux/tmx restore` -> manually restores all saved sessions (rarely needed)
- `switch <session>` -> switch to any session (e.g., `switch work`)

Optional env overrides:

- `TMX_SESSION_NAME` (default: `main`)
- `TMX_SESSIONS` (default: `$TMX_SESSION_NAME`) space-separated list of sessions to ensure/restore
- `TMX_SESSION_ROOT` (default: `$HOME`)

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
