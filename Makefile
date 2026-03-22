.PHONY: build run

build:
	docker build --no-cache -t claude-yolo .

run:
	docker run -it --rm \
	  --cap-add=NET_ADMIN \
	  --cap-add=NET_RAW \
	  --network=host \
	  -v "$$PWD:/workspace" \
	  -v "$$HOME/.claude/.credentials.json:/home/node/.claude/.credentials.json:ro" \
	  -v "$$HOME/.claude/plugins:/home/node/.claude/plugins:ro" \
	  -e GIT_USER_NAME="$$(git config user.name)" \
	  -e GIT_USER_EMAIL="$$(git config user.email)" \
	  -e TZ=$${TZ:-Europe/Istanbul} \
	  -e GITHUB_TOKEN \
	  -e HOST_HOME=$$HOME \
	  claude-yolo claude --dangerously-skip-permissions
