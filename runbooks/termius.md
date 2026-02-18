# Termius (iPhone / iPad)

Connect to your Mac from Termius on iOS using either Tailscale or Cloudflare Tunnel.

## Prerequisites

- SSH enabled on Mac: `sudo systemsetup -setremotelogin on`
- One of the following configured:
  - [Tailscale SSH](./tailscale-ssh.md)
  - [Cloudflare Tunnel SSH](./cloudflare-ssh.md)

## SSH Key Setup

1. Create or import a dedicated SSH key in Termius.
2. Add the Termius public key to your Mac:
   ```bash
   mkdir -p ~/.ssh && chmod 700 ~/.ssh
   # append the Termius public key to ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

## Option A: Tailscale

1. Install [Tailscale](https://apps.apple.com/app/tailscale/id1470499037) on your iPhone and sign in.
2. Apply hardening on the Mac: `just tailscale-ssh-harden`
3. Create the host in Termius:

| Field | Value |
|-------|-------|
| Host | `100.x.x.x` (Mac's Tailscale IP — run `tailscale ip -4`) |
| Port | `22` |
| User | `gb` |
| Auth | SSH key from step 1 |

4. Connect and run `tmx` to attach your persistent tmux session.

## Option B: Cloudflare Tunnel

Requires the [Cloudflare WARP app](https://apps.apple.com/app/id1423538627) on your iPhone/iPad.

1. Apply hardening on the Mac: `just cloudflare-ssh-harden`
2. In the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com):
   - Go to **Settings > WARP Client > Device enrollment permissions**
   - Add an enrollment rule (e.g., email matching your account)
3. On iPhone, open the 1.1.1.1/WARP app:
   - Go to **Settings > Account > Login to Cloudflare Zero Trust**
   - Enter your Zero Trust org name and authenticate
4. Create the host in Termius:

| Field | Value |
|-------|-------|
| Host | `ssh.gabrielkoerich.com` |
| Port | `22` |
| User | `gb` |
| Auth | SSH key from step 1 |

5. Connect and run `tmx` to attach your persistent tmux session.

## Notes

- Both profiles enforce key-only auth. Do not enable password auth.
- Tailscale routes traffic over the mesh VPN. Cloudflare routes traffic through Cloudflare's network via WARP.
- Quick toggle: `just tailscale-ssh-enable` / `just cloudflare-ssh-enable` to bring services up before connecting.
