# claude-yolo Environment

You are running inside a `claude-yolo` Docker container with `--dangerously-skip-permissions`.

## Container Environment

| Variable         | Value                    | Purpose                              |
| ---------------- | ------------------------ | ------------------------------------ |
| `DEVCONTAINER`   | `true`                   | indicates containerized environment  |
| `HOST_WORKDIR`   | host path of `/workspace`| use for nested `docker run -v` calls |
| `HOST_HOME`      | host user's `$HOME`      | plugin path resolution               |
| `TZ`             | `Europe/Istanbul`        | container timezone                   |
| `GIT_USER_NAME`  | from host git config     | auto-configured at startup           |
| `GIT_USER_EMAIL` | from host git config     | auto-configured at startup           |
| `GITHUB_TOKEN`   | if set on host           | gh CLI + git HTTPS auth              |

## Nested Docker

The host Docker socket is mounted. Run nested containers with:

```bash
docker run --rm -v "$HOST_WORKDIR:/workspace" <image> <cmd>
```

Use `$HOST_WORKDIR` (not `/workspace`) — the Docker daemon resolves paths on the **host**, not inside this container.

To mount a subfolder:

```bash
docker run --rm -v "$HOST_WORKDIR/subdir:/app" <image> <cmd>
```

## Available Tools

Node 20, Go 1.24, Python 3 + uv, AWS CLI v2, Docker CLI, Playwright + Chromium, gh, git-delta, fzf, jq, vim, nano.

## Firewall

Optional whitelist-only outbound firewall:

```bash
sudo /usr/local/bin/init-firewall.sh
```

Blocks all traffic except GitHub, npm, PyPI, Anthropic API, Sentry, and DNS.
