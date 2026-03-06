# Linux Setup

## Prerequisites

Install Docker or Podman using your distro's package manager.

**Docker (Debian/Ubuntu):**
```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
```

Log out and back in for the group change to take effect, then verify:

```bash
docker run hello-world
```

**Docker (Fedora/RHEL):**
```bash
sudo dnf install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**Podman (any distro):**
```bash
# Debian/Ubuntu
sudo apt-get install -y podman

# Fedora/RHEL
sudo dnf install -y podman
```

Podman runs natively on Linux (no VM) and is rootless by default.

## Setup

```bash
git clone https://github.com/Tanz0rz/Docker-Claude.git
cd Docker-Claude
chmod +x linux/run.sh
```

## Usage

From any project directory:

```bash
~/path/to/Docker-Claude/linux/run.sh
```

On first run, the script will:
1. Build the container image (takes a few minutes)
2. Create a persistent `claude-home` volume
3. Launch Claude Code

**You must run `/login` inside the container on first launch.** Auth persists in the named volume across all future sessions.

### Pass arguments to Claude

```bash
~/path/to/Docker-Claude/linux/run.sh -p "fix the failing tests"
~/path/to/Docker-Claude/linux/run.sh --resume
```

### Alias (optional)

Add to your `~/.bashrc`:

```bash
alias cclaude="$HOME/path/to/Docker-Claude/linux/run.sh"
```

Then use `cclaude` from any project directory.

## Docker vs Podman

The run script auto-detects the runtime, preferring Docker.

| | Docker | Podman |
|---|---|---|
| Linux stability | Reliable | Reliable (native, no VM) |
| Daemon | `dockerd` runs as root | Daemonless |
| Rootless | Requires `usermod -aG docker` | Default |
| Security hardening | `--cap-drop=ALL --security-opt=no-new-privileges` | `--userns=keep-id` |
