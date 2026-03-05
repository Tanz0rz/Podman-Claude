# Podman Claude

Run [Claude Code](https://claude.ai) in a rootless Podman container with `--dangerously-skip-permissions` safely isolated from your host system.

## Why

Running Claude Code with `--dangerously-skip-permissions` gives the AI agent full autonomy but also full access to your system. A container restricts it to only the mounted project directory — Claude can't touch anything else on your host.

Podman is preferred over Docker because it runs **rootless by default** — no daemon, no root process, minimal attack surface.

## Prerequisites

```bash
brew install podman
podman machine init --memory 8192
podman machine start
```

> **Note:** The default 2GB VM memory is insufficient to build the image. 8GB is recommended.

## Setup

```bash
git clone https://github.com/Tanz0rz/Podman-Claude.git
cd Podman-Claude
chmod +x run.sh
```

## Usage

From any project directory:

```bash
~/path/to/Podman-Claude/run.sh
```

On first run, the script will:
1. Build the container image (takes a few minutes)
2. Create a persistent `claude-home` volume
3. Launch Claude Code

**You must run `/login` inside the container on first launch.** Auth persists in the named volume across all future sessions.

### Pass arguments to Claude

```bash
./run.sh -p "fix the failing tests"
./run.sh --resume
```

### Alias (optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
alias cclaude="$HOME/path/to/Podman-Claude/run.sh"
```

Then use `cclaude` from any project directory.

## How it works

- **Containerfile** — Debian-based image with Node.js 22, Claude Code native binary, and common dev tools (git, curl, jq, python3, build-essential)
- **run.sh** — Builds the image, creates a persistent volume, and runs the container with your project mounted at `/workspace`
- **Named volume** (`claude-home`) — Persists `/home/claude` across runs, including auth tokens, settings, memory, and history
- **Project mount** — `$(pwd)` is bind-mounted to `/workspace` so Claude can read and edit your code

## What's isolated

| | Host | Container |
|---|---|---|
| Filesystem | Protected | Only `/workspace` (your project) is mounted |
| Processes | Protected | No access to host processes |
| Network | Protected | Outbound web access only (bridge mode) |
| Privilege escalation | Protected | Rootless + no capabilities |

## What's shared

- **Git config** — `~/.gitconfig` mounted read-only so commits use your identity
- **SSH keys** — `~/.ssh` mounted read-only for private repo access
- **Project directory** — Read-write mount of your current directory

## Updating Claude Code

The Claude Code binary is baked into the image. To update:

```bash
podman rmi claude-code
cclaude  # rebuilds automatically
```

## Docker fallback

The run script auto-detects the runtime. If Podman isn't installed, it falls back to Docker with `--cap-drop=ALL --security-opt=no-new-privileges` for hardening.
