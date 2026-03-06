# macOS Setup

## Prerequisites

Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (recommended) or Podman.

**Docker:**
```bash
brew install --cask docker
```

**Podman (alternative):**
```bash
brew install podman
podman machine init --memory 8192
podman machine start
```

> **Note on Podman:** Podman's VM on macOS has known issues with socket freezes, requiring periodic `podman machine stop && podman machine start`. The run script includes an automatic health check for this, but Docker is more reliable on macOS. Podman's default 2GB VM memory is also insufficient — 8GB minimum is required.

## Setup

```bash
git clone https://github.com/Tanz0rz/Docker-Claude.git
cd Docker-Claude
chmod +x macos/run.sh
```

## Usage

From any project directory:

```bash
~/path/to/Docker-Claude/macos/run.sh
```

On first run, the script will:
1. Build the container image (takes a few minutes)
2. Create a persistent `claude-home` volume
3. Launch Claude Code

**You must run `/login` inside the container on first launch.** Auth persists in the named volume across all future sessions.

### Pass arguments to Claude

```bash
~/path/to/Docker-Claude/macos/run.sh -p "fix the failing tests"
~/path/to/Docker-Claude/macos/run.sh --resume
```

### Alias (optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
alias cclaude="$HOME/path/to/Docker-Claude/macos/run.sh"
```

Then use `cclaude` from any project directory.

## Docker vs Podman

The run script auto-detects the runtime, preferring Docker. Both work, with trade-offs:

| | Docker | Podman |
|---|---|---|
| macOS stability | Reliable | VM socket freezes (auto-recovered by script) |
| Daemon | `dockerd` runs as root | Daemonless |
| Rootless | Requires extra setup | Default |
| Security hardening | `--cap-drop=ALL --security-opt=no-new-privileges` | `--userns=keep-id` |
