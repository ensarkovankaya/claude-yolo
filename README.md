# claude-yolo

Dockerized [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with network firewall, GitHub integration, and dangerous mode pre-configured.

## What's Inside

### Dockerfile

Builds a development container based on `node:20` with:

- **Dev tools**: git, zsh, fzf, vim, nano, gh, python3, Go, uv
- **Claude Code**: installed globally via npm
- **Firewall support**: iptables, ipset, iproute2, dnsutils for network restriction
- **Pre-configured**: skips onboarding prompts, dark theme, dangerous mode permission prompt disabled
- **Non-root**: runs as `node` user with sudo access for firewall setup

### entrypoint.sh

Runs on container start:

- Creates symlink from host home to container home so plugin paths resolve
- Pre-approves custom `ANTHROPIC_API_KEY` to skip the API key prompt
- Copies host `.gitconfig` if mounted
- Configures git and `gh` CLI with `GITHUB_TOKEN` if provided

### init-firewall.sh

Optional network firewall that restricts outbound traffic to only:

- GitHub (web, API, git — IPs fetched from GitHub meta API)
- npm registry
- Anthropic API & stats
- VS Code marketplace
- DNS and SSH
- Docker internal DNS and host network

All other outbound traffic is **rejected**. Verified at the end by confirming `example.com` is blocked and `api.github.com` is reachable.

Run it inside the container with:

```bash
sudo /usr/local/bin/init-firewall.sh
```

> Requires `--cap-add=NET_ADMIN` when starting the container.

## Build

```bash
make build
```

Or directly:

```bash
docker build -t claude-yolo .
```

## Usage

Add this alias to your `~/.zshrc` or `~/.bashrc`:

```bash
alias claude-yolo='docker run -it --rm \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --network=host \
  -v "$PWD:/workspace" \
  -v "$HOME/.claude/.credentials.json:/home/node/.claude/.credentials.json:ro" \
  -v "$HOME/.claude/plugins:/home/node/.claude/plugins:ro" \
  -v "$HOME/.gitconfig:/home/node/.gitconfig.host:ro" \
  -e TZ=${TZ:-Europe/Istanbul} \
  -e GITHUB_TOKEN=${GITHUB_TOKEN} \
  -e HOST_HOME=${HOME} \
  claude-yolo claude --dangerously-skip-permissions'
```

Then run from any directory:

```bash
claude-yolo
```

### Environment Variables

| Variable       | Description                                              |
|----------------|----------------------------------------------------------|
| `GITHUB_TOKEN` | GitHub token for git operations and `gh` CLI             |
| `TZ`           | Timezone (default: `Europe/Istanbul`)                    |
| `HOME`         | Used to mount credentials, plugins, and gitconfig from host |

### Mounted Volumes

| Host Path                      | Container Path                           | Description                  |
|--------------------------------|------------------------------------------|------------------------------|
| `$PWD`                         | `/workspace`                             | Current directory            |
| `~/.claude/.credentials.json`  | `/home/node/.claude/.credentials.json`   | Claude credentials (read-only) |
| `~/.claude/plugins`            | `/home/node/.claude/plugins`             | Claude plugins (read-only)   |
| `~/.gitconfig`                 | `/home/node/.gitconfig.host`             | Git config (read-only)       |
