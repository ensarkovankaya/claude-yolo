#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${WORKDIR:-$PWD}"

cmd_build() {
	docker build --no-cache -t claude-yolo "$SCRIPT_DIR"
}

cmd_start() {
	docker run -it --rm \
	  --cap-add=NET_ADMIN \
	  --cap-add=NET_RAW \
	  --network=host \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v "$(which docker):/usr/local/bin/docker:ro" \
	  -v "$WORKDIR:/workspace" \
	  -v "$SCRIPT_DIR/.claude:/home/node/.claude:ro" \
	  -e GIT_USER_NAME="$(git config user.name)" \
	  -e GIT_USER_EMAIL="$(git config user.email)" \
	  -e TZ=${TZ:-Europe/Istanbul} \
	  -e GITHUB_TOKEN \
	  -e HOST_HOME=$HOME \
	  $([ -d "$HOME/.aws" ] && echo "-v $HOME/.aws:/home/node/.aws:ro") \
	  claude-yolo claude --dangerously-skip-permissions
}

case "${1:-help}" in
	build) cmd_build ;;
	start) cmd_start ;;
	*)
		echo "Usage: $(basename "$0") {build|start}"
		exit 1
		;;
esac
