# Tailscale SSH

Tailscale creates a mesh VPN between your devices. SSH traffic stays on the Tailscale network — no ports exposed to the public internet.

## Prerequisites

- `tailscale` installed (`brew install --cask tailscale`)
- Tailscale account
- SSH enabled on the Mac: `sudo systemsetup -setremotelogin on`

## Server Setup

### 1. Start Tailscale with SSH

```bash
tailscale up --ssh
```

This enables Tailscale SSH, which allows connections over the Tailscale network.

### 2. Apply SSH hardening

```bash
just tailscale-ssh-harden
```

This substitutes your username into `home/.config/ssh/sshd-hardening.tailscale.conf`, copies it to `/etc/ssh/sshd_config.d/99-tailscale-hardening.conf`, validates the config, and restarts sshd.

The hardening config:
- Enforces key-only auth, disables root login
- Disables forwarding/tunnels
- Restricts SSH access to Tailscale IP ranges only (`100.64.0.0/10`, `fd7a:115c:a1e0::/48`)
- Denies your user from any non-Tailscale address

### 3. Get your Tailscale IP

```bash
tailscale ip -4
```

Note the `100.x.x.x` address — clients will connect using this.

## Desktop Client Setup

On any client machine with Tailscale installed:

```bash
ssh gb@<tailscale-ip>
```

Or add to `~/.ssh/config`:

```
Host mac-tailscale
  HostName 100.x.x.x
  User gb
```

Then connect with `ssh mac-tailscale`.

## Termius (iPhone / iPad)

### 1. Add SSH key to the Mac

Create or import a dedicated SSH key in Termius, then add the public key to the Mac:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# append the Termius public key to ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 2. Install Tailscale on iPhone

Download [Tailscale](https://apps.apple.com/app/tailscale/id1470499037) from the App Store and sign in with your account.

### 3. Create the host in Termius

| Field | Value |
|-------|-------|
| Host | `100.x.x.x` (Mac's Tailscale IP) |
| Port | `22` |
| User | `gb` |
| Auth | SSH key from step 1 |

### 4. Connect and attach tmux

Once connected, run `tmx` to attach to your persistent tmux session.

## Enable / Disable

Quick toggle using Just recipes:

```bash
just tailscale-ssh-enable    # turn on SSH + Tailscale
just tailscale-ssh-disable   # turn off Tailscale + SSH
```

## How It Works

- Tailscale creates a WireGuard-based mesh VPN between your devices.
- Traffic stays on the Tailscale network, never touching the public internet.
- The hardening config uses a `Match Address` block to deny SSH from non-Tailscale IPs.
- Key-only auth is enforced. Do not enable password auth.

## Notes

- If you also use Cloudflare Tunnel SSH hardening (`99-cloudflare-hardening.conf`), both configs may conflict (e.g., `ListenAddress` settings). Choose one profile or merge them manually.
- The hardening template lives at `home/.config/ssh/sshd-hardening.tailscale.conf`.
- The `just tailscale-ssh-harden` recipe is defined in the Justfile.
