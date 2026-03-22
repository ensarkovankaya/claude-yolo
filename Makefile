WORKDIR ?= $$PWD

.PHONY: build run

build:
	docker build --no-cache -t claude-yolo .

run:
	docker run -it --rm \
	  --cap-add=NET_ADMIN \
	  --cap-add=NET_RAW \
	  --network=host \
	  -v "$(WORKDIR):/workspace" \
	  -v "$$HOME/.claude:/home/node/.claude" \
	  -v "$$HOME/.claude.json:/home/node/.claude.json" \
	  -e GIT_USER_NAME="$$(git config user.name)" \
	  -e GIT_USER_EMAIL="$$(git config user.email)" \
	  -e TZ=$${TZ:-Europe/Istanbul} \
	  -e GITHUB_TOKEN \
	  -e HOST_HOME=$$HOME \
	  claude-yolo claude --dangerously-skip-permissions
