#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
WORKDIR="${WORKDIR:-$PWD}"

_docker_run() {
	mkdir -p "$HOME/.claude"
	docker run -it --rm \
	  --cap-add=NET_ADMIN \
	  --cap-add=NET_RAW \
	  --network=host \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v "$WORKDIR:/workspace" \
	  -v "$HOME/.claude:/home/node/.claude" \
	  -e GIT_USER_NAME="$(git config user.name)" \
	  -e GIT_USER_EMAIL="$(git config user.email)" \
	  -e TZ=${TZ:-Europe/Istanbul} \
	  -e GITHUB_TOKEN \
	  -e GREPTILE_API_KEY \
	  -e HOST_HOME=$HOME \
	  -e HOST_WORKDIR="$WORKDIR" \
	  $([ -d "$HOME/.aws" ] && echo "-v $HOME/.aws:/home/node/.aws:ro") \
	  claude-yolo "$@"
}

cmd_claude() {
	_docker_run claude --dangerously-skip-permissions --append-system-prompt "$(cat "$SCRIPT_DIR/CLAUDE.local.md")" "$@"
}

cmd_sh() {
	_docker_run bash
}

case "${1:-claude}" in
	sh) cmd_sh ;;
	*)  cmd_claude "$@" ;;
esac
