# Containerized Claude Code

Run [Claude Code](https://claude.ai) in a container with `--dangerously-skip-permissions` safely isolated from your host system.

## Why

Running Claude Code with `--dangerously-skip-permissions` gives the AI agent full autonomy but also full access to your system. A container restricts it to only the mounted project directory — Claude can't touch anything else on your host.

## Quick start

Pick your OS:

| OS | Guide | Script |
|---|---|---|
| [macOS](macos/) | [macos/README.md](macos/README.md) | `run.sh` |
| [Linux](linux/) | [linux/README.md](linux/README.md) | `run.sh` |
| [Windows](windows/) | [windows/README.md](windows/README.md) | `run.bat` |

## How it works

- **Containerfile** — Debian-based image with Node.js 22, Claude Code CLI, gh CLI, and common dev tools (git, curl, jq, python3, build-essential)
- **run.sh / run.bat** — Builds the image, creates a persistent volume, and runs the container with your project mounted at `/workspace`. Each OS directory has its own run script.
- **Named volume** (`claude-home`) — Persists `/home/claude` across runs, including auth tokens, settings, memory, and history
- **Project mount** — Your current directory is bind-mounted to `/workspace/<project>` so Claude can read and edit your code

## What's isolated

| | Host | Container |
|---|---|---|
| Filesystem | Protected | Only `/workspace` (your project) is mounted |
| Processes | Protected | No access to host processes |
| Network | Protected | Outbound web access only (bridge mode) |
| Privilege escalation | Protected | Capabilities dropped, no-new-privileges |

## What's shared

- **Git config** — Copied from host at startup so commits use your identity
- **SSH keys** — Copied from host at startup for private repo access
- **Project directory** — Read-write mount of your current directory

## Managing dependencies

The container comes with common dev tools (git, curl, jq, python3, build-essential). When Claude needs something else, there are two approaches:

### 1. Add to the Containerfile (permanent)

For tools you always need, add them to the `apt-get install` line in the Containerfile and rebuild:

```
docker rmi claude-code
cclaude  # rebuilds with new packages
```

### 2. Install to the named volume (persistent, no rebuild)

Tools installed to `/home/claude` (the named volume) persist across sessions. For example, Claude could install Go without a rebuild:

```bash
curl -fsSL https://go.dev/dl/go1.24.1.linux-arm64.tar.gz | tar -C ~/.local -xz
echo 'export PATH=$HOME/.local/go/bin:$PATH' >> ~/.bashrc
```

This works for any tool that supports user-level installation (pip, cargo, npm globals, language version managers, etc.).

## Updating Claude Code

The Claude Code binary is baked into the image. To update:

```
docker rmi claude-code
cclaude  # rebuilds automatically
```

## Migrating from native Claude Code

Switching to the containerized approach starts with a fresh `~/.claude` inside the named volume. **Your existing project memories (`MEMORY.md` files) will not carry over automatically.**

Your host memories are stored in `~/.claude/projects/` with paths like `-Users-you-projects-myapp/memory/MEMORY.md`. The container uses a different path scheme based on the mount point: `-workspace-myapp/memory/MEMORY.md`.

To preserve your memories, copy them from your host's `~/.claude/projects/` into the `claude-home` Docker volume, renaming the project directories to match the container's `-workspace-<project>` format. The `<project>` portion is the basename of the directory you run the script from.
