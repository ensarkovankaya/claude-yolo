#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${WORKDIR:-$PWD}"

_docker_run() {
	docker run -it --rm \
	  --cap-add=NET_ADMIN \
	  --cap-add=NET_RAW \
	  --network=host \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v "$(which docker):/usr/local/bin/docker:ro" \
	  -v "$WORKDIR:/workspace" \
	  -e GIT_USER_NAME="$(git config user.name)" \
	  -e GIT_USER_EMAIL="$(git config user.email)" \
	  -e TZ=${TZ:-Europe/Istanbul} \
	  -e GITHUB_TOKEN \
	  -e HOST_HOME=$HOME \
	  $([ -d "$HOME/.aws" ] && echo "-v $HOME/.aws:/home/node/.aws:ro") \
	  claude-yolo "$@"
}

cmd_start() {
	_docker_run claude --dangerously-skip-permissions "$@"
}

cmd_sh() {
	_docker_run bash
}

case "${1:-help}" in
	start) shift; cmd_start "$@" ;;
	sh)    cmd_sh ;;
	*)
		echo "Usage: $(basename "$0") {start|sh}"
		exit 1
		;;
esac
