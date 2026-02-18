# Cloudflare Tunnel SSH

Cloudflare Tunnel proxies SSH through Cloudflare's network — no ports exposed to the internet. The `cloudflared` CLI is free for this use case.

## Prerequisites

- `cloudflared` installed (`brew install cloudflared`)
- Cloudflare account with a domain (DNS managed by Cloudflare)
- SSH enabled on the Mac: `sudo systemsetup -setremotelogin on`

## Server Setup

### 1. Authenticate cloudflared

```bash
cloudflared tunnel login
```

Opens the browser to authenticate with your Cloudflare account. Pick the domain you want to use.

### 2. Create a tunnel

```bash
cloudflared tunnel create my-ssh
```

Note the **tunnel ID** from the output.

### 3. Configure the tunnel

Create `~/.cloudflared/config.yml`:

```yaml
tunnel: my-ssh
credentials-file: /Users/gb/.cloudflared/<tunnel-id>.json
ingress:
  - hostname: ssh.gabrielkoerich.com
    service: ssh://localhost:22
  - service: http_status:404
```

Replace `<tunnel-id>` with the ID from step 2.

**Important:** All top-level keys (`tunnel`, `credentials-file`, `ingress`) must start at column 0 — no leading spaces.

### 4. Route DNS

```bash
cloudflared tunnel route dns my-ssh ssh.gabrielkoerich.com
```

### 5. Apply SSH hardening

```bash
just cloudflare-ssh-harden
```

This substitutes your username into `home/.config/ssh/sshd-hardening.cloudflare.conf`, copies it to `/etc/ssh/sshd_config.d/99-cloudflare-hardening.conf`, validates the config, and restarts sshd.

The hardening config makes sshd listen only on `127.0.0.1` / `::1` (localhost), disables password auth, and restricts access to your user.

### 6. Run the tunnel

```bash
cloudflared tunnel run my-ssh
```

## Desktop Client Setup

On any client machine:

1. Install cloudflared (`brew install cloudflared`)
2. Add to `~/.ssh/config`:
   ```
   Host ssh.gabrielkoerich.com
     ProxyCommand cloudflared access ssh --hostname %h
     User gb
   ```
3. Connect:
   ```bash
   ssh ssh.gabrielkoerich.com
   ```

## Termius (iPhone / iPad)

Termius on iOS can't run `cloudflared` as a ProxyCommand, so you need the **Cloudflare WARP app** to route traffic through the tunnel.

### 1. Add SSH key to the Mac

Create or import a dedicated SSH key in Termius, then add the public key to the Mac:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# append the Termius public key to ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 2. Install WARP on iPhone

Download [1.1.1.1 / WARP](https://apps.apple.com/app/id1423538627) from the App Store.

### 3. Set up Zero Trust enrollment

In the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com):

- Go to **Settings > WARP Client > Device enrollment permissions**
- Add an enrollment rule (e.g., email matching your Cloudflare account)

### 4. Connect WARP to your Zero Trust org

On iPhone, open the 1.1.1.1/WARP app:

- Go to **Settings > Account > Login to Cloudflare Zero Trust**
- Enter your Zero Trust org name and authenticate

### 5. Create the host in Termius

| Field | Value |
|-------|-------|
| Host | `ssh.gabrielkoerich.com` |
| Port | `22` |
| User | `gb` |
| Auth | SSH key from step 1 |

### 6. Connect and attach tmux

Once connected, run `tmx` to attach to your persistent tmux session.

## How It Works

- WARP routes iPhone traffic through Cloudflare's network, which reaches the tunnel — Termius connects to the hostname directly, no ProxyCommand needed.
- The tunnel connects to `ssh://localhost:22` on the server side, so sshd only listens on localhost.
- Key-only auth is enforced. Do not enable password auth.

## Notes

- If you also use Tailscale SSH hardening (`99-tailscale-hardening.conf`), both configs set `ListenAddress` which may conflict. Choose one profile or merge them manually.
- The hardening template lives at `home/.config/ssh/sshd-hardening.cloudflare.conf`.
- The `just cloudflare-ssh-harden` recipe is defined in the Justfile.
