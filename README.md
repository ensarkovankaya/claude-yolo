```
      _                 _
  ___| | __ _ _   _  __| | ___       _   _  ___  | | ___
 / __| |/ _` | | | |/ _` |/ _ \_____| | | |/ _ \ | |/ _ \
| (__| | (_| | |_| | (_| |  __/_____| |_| | (_) || | (_) |
 \___|_|\__,_|\__,_|\__,_|\___|      \__, |\___/ |_|\___/
                                      |___/
```

> Dockerized [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — network firewall, GitHub integration, dangerous mode, batteries included.

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Included Tools](#included-tools)
- [Configuration](#configuration)
- [Firewall](#firewall)
- [How It Works](#how-it-works)
- [Notes](#notes)

---

## Features

- **Dangerous mode** — all permission prompts skipped, zero friction
- **Network firewall** — optional whitelist-only outbound traffic via iptables
- **GitHub integration** — token-based auth for git + gh CLI, auto-configured
- **Docker-in-Docker** — host socket forwarded, Docker CLI pre-installed
- **Playwright + Chromium** — headless browser automation via MCP
- **Multi-language** — Node 20, Go 1.24, Python 3 + uv, all pre-installed

---

## Quick Start

```bash
make install   # symlink `yolo` to /usr/local/bin
make build     # build the Docker image
yolo           # run Claude Code in current directory
```

**Step by step:**

1. **Install** — `make install` creates a `yolo` symlink in `/usr/local/bin` pointing to `manage.sh`
2. **Build** — `make build` runs `docker build --no-cache -t claude-yolo .`
3. **Run** — `yolo` launches a container, mounts your current directory to `/workspace`, and starts Claude Code with `--dangerously-skip-permissions`

---

## Usage

### Commands

| Command        | Description                                            |
|----------------|--------------------------------------------------------|
| `yolo`         | run Claude Code in current directory (default)         |
| `yolo [args]`  | forward args to `claude --dangerously-skip-permissions` |
| `yolo sh`      | open a bash shell inside the container                 |
| `make build`   | build the Docker image (`docker build --no-cache`)     |
| `make install` | symlink `manage.sh` as `yolo` in `/usr/local/bin`      |

### Examples

```bash
# start Claude in current project
yolo

# pass arguments to claude CLI
yolo --model sonnet "explain this repo"

# resume a conversation
yolo --continue

# open a shell to inspect the container
yolo sh

# mount a different project directory
WORKDIR=~/projects/myapp yolo

# rebuild the image from scratch
make build
```

---

## Included Tools

| Category  | Tool                        | Details                         |
|-----------|-----------------------------|---------------------------------|
| AI        | Claude Code                 | latest, dangerous mode          |
| Runtime   | Node.js 20                  | base image                      |
| Runtime   | Go 1.24.1                   | + golangci-lint 2.11.3          |
| Runtime   | Python 3                    | + uv package manager            |
| Browser   | Playwright + Chromium       | MCP browser automation          |
| Container | Docker CLI                  | talks to host daemon via socket |
| Cloud     | AWS CLI v2                  | amd64 + arm64                   |
| Git       | git, gh, git-delta          | syntax-highlighted diffs        |
| Shell     | Zsh                         | robbyrussell, git + fzf plugins |
| Editor    | vim, nano                   | default `EDITOR=vim`            |
| Utility   | fzf, jq, less, unzip, procps | general dev tools              |
| Firewall  | iptables, ipset, aggregate  | network restriction support     |

---

## Configuration

### Environment Variables

| Variable            | Required | Description                                      |
|---------------------|----------|--------------------------------------------------|
| `ANTHROPIC_API_KEY` | yes      | Claude API key, auto-approved at startup         |
| `GITHUB_TOKEN`      | no       | GitHub auth for git + gh CLI                     |
| `GIT_USER_NAME`     | no       | git user.name (auto-read from host git config)   |
| `GIT_USER_EMAIL`    | no       | git user.email (auto-read from host git config)  |
| `TZ`                | no       | timezone (default: `Europe/Istanbul`)            |
| `HOST_HOME`         | auto     | set by manage.sh for plugin path resolution      |
| `HOST_WORKDIR`      | auto     | set by manage.sh for nested Docker volume mounts |

### Volumes

| Host                   | Container                  | Description                       |
|------------------------|----------------------------|-----------------------------------|
| `$PWD`                 | `/workspace`               | current project directory         |
| `~/.claude`            | `/home/node/.claude`       | Claude state (sessions, settings) |
| `/var/run/docker.sock` | `/var/run/docker.sock`     | Docker daemon socket              |
| `~/.aws`               | `/home/node/.aws:ro`       | AWS credentials (if dir exists)   |

### Docker Flags

| Flag                   | Purpose                                |
|------------------------|----------------------------------------|
| `-it`                  | interactive TTY                        |
| `--rm`                 | auto-remove container on exit          |
| `--network=host`       | share host network stack               |
| `--cap-add=NET_ADMIN`  | required for iptables firewall         |
| `--cap-add=NET_RAW`    | required for firewall ICMP reject      |

---

## Firewall

Optional network restriction that blocks all outbound traffic except whitelisted destinations.

```bash
# run inside the container
sudo /usr/local/bin/init-firewall.sh
```

### Whitelist

Everything not listed below is **rejected**.

| Destination                        | Ports    | Purpose                  |
|------------------------------------|----------|--------------------------|
| GitHub (web, API, git)             | 443      | IPs from GitHub meta API |
| registry.npmjs.org                 | 443      | npm packages             |
| api.anthropic.com                  | 443      | Claude API               |
| sentry.io                          | 443      | error monitoring         |
| statsig.anthropic.com, statsig.com | 443      | feature flags            |
| marketplace.visualstudio.com       | 443      | VS Code extensions       |
| vscode.blob.core.windows.net       | 443      | VS Code CDN              |
| update.code.visualstudio.com       | 443      | VS Code updates          |
| DNS                                | UDP 53   | name resolution          |
| SSH                                | TCP 22   | git over SSH             |
| Docker DNS + host network          | internal | container networking     |

The script auto-verifies by confirming `example.com` is blocked and `api.github.com` is reachable.

---

## How It Works

### Entrypoint Sequence

On container start, `entrypoint.sh` runs:

1. **Docker socket** — detect socket GID, create group if needed, add `node` user
2. **Host path symlink** — `$HOST_HOME` -> `/home/node` so host plugin absolute paths resolve
3. **Settings merge** — copy default `settings.json` + skills to `~/.claude` if not present (never overwrites existing)
4. **API key approval** — pre-approve `ANTHROPIC_API_KEY` in `.claude.json` to skip the "custom API key detected" prompt
5. **Git config** — set `user.name` and `user.email` from env vars
6. **GitHub auth** — `gh auth login --with-token` + `gh auth setup-git` if `GITHUB_TOKEN` set
7. **Group re-exec** — re-execute with Docker group membership via `sg` if socket group not yet active

### System Prompt

`CLAUDE.local.md` contains container-specific instructions (env vars, nested Docker usage, available tools). It is injected at runtime via `--append-system-prompt` by `manage.sh` — no files written to host or workspace.

### Architecture

```
Host                          Container (claude-yolo)
 |                             |
 |  docker run --network=host  |
 |  -v $PWD:/workspace         |
 |  -v ~/.claude:/home/node/.. |
 +---------------------------->|
                               |  entrypoint.sh
                               |    -> socket permissions
                               |    -> settings merge
                               |    -> git/gh config
                               |  manage.sh
                               |    -> append CLAUDE.local.md as system prompt
                               |    -> exec claude --dangerously-skip-permissions
                               |
                               |  [optional] sudo init-firewall.sh
                               |    -> iptables whitelist
                               |    -> all other traffic rejected
```

---

## Notes

- **Concurrent writes** — don't run host Claude and container Claude simultaneously. `.claude.json` concurrent write corruption is a [known upstream bug](https://github.com/anthropics/claude-code/issues/29217).
- **Working directory** — set `WORKDIR` shell variable to mount a different directory: `WORKDIR=~/other/project yolo`
- **AWS credentials** — `~/.aws` is mounted read-only only if the directory exists on the host.
- **Firewall requires capabilities** — `--cap-add=NET_ADMIN` and `--cap-add=NET_RAW` are already set by `manage.sh`, no extra flags needed.
