WORKDIR ?= $$PWD

.PHONY: build run

build:
	docker build --no-cache -t claude-yolo .

run:
	docker run -it --rm \
	  --cap-add=NET_ADMIN \
	  --cap-add=NET_RAW \
	  --network=host \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v "$$(which docker):/usr/local/bin/docker:ro" \
	  -v "$(WORKDIR):/workspace" \
	  -v "$$HOME/.claude:/home/node/.claude" \
	  -v "$$HOME/.claude.json:/host/.claude.json:ro" \
	  -e GIT_USER_NAME="$$(git config user.name)" \
	  -e GIT_USER_EMAIL="$$(git config user.email)" \
	  -e TZ=$${TZ:-Europe/Istanbul} \
	  -e GITHUB_TOKEN \
	  -e HOST_HOME=$$HOME \
	  $$([ -d "$$HOME/.aws" ] && echo "-v $$HOME/.aws:/home/node/.aws:ro") \
	  claude-yolo claude --dangerously-skip-permissions
