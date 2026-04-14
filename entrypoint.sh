#!/bin/zsh

# Grant Docker socket access to the node user
if [ -S /var/run/docker.sock ]; then
  DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
  if ! getent group "$DOCKER_GID" > /dev/null 2>&1; then
    sudo groupadd -g "$DOCKER_GID" docker
  fi
  DOCKER_GROUP=$(getent group "$DOCKER_GID" | cut -d: -f1)
  if ! id -nG node | grep -qw "$DOCKER_GROUP"; then
    sudo usermod -aG "$DOCKER_GROUP" node
  fi
fi

# Create symlink from host home to container home so plugin absolute paths resolve
if [ -n "$HOST_HOME" ] && [ "$HOST_HOME" != "/home/node" ]; then
  sudo mkdir -p "$(dirname "$HOST_HOME")"
  sudo ln -sfn /home/node "$HOST_HOME"
fi

# Merge container defaults into host-mounted .claude (never overwrite existing)
if [ ! -f /home/node/.claude/settings.json ] && [ -f /etc/claude-defaults/settings.json ]; then
  cp /etc/claude-defaults/settings.json /home/node/.claude/settings.json
fi

if [ -d /etc/claude-defaults/skills ]; then
  mkdir -p /home/node/.claude/skills
  for skill_dir in /etc/claude-defaults/skills/*/; do
    skill_name=$(basename "$skill_dir")
    if [ ! -d "/home/node/.claude/skills/$skill_name" ]; then
      cp -r "$skill_dir" "/home/node/.claude/skills/$skill_name"
    fi
  done
fi

# Pre-approve custom API key to skip "Detected a custom API key" prompt
if [ -n "$ANTHROPIC_API_KEY" ]; then
  KEY_PREFIX=$(echo "$ANTHROPIC_API_KEY" | grep -o '.\{20\}$')
  CLAUDE_JSON="/home/node/.claude.json"
  if [ -f "$CLAUDE_JSON" ]; then
    # Add key prefix to customApiKeyResponses.approved if not already present
    tmp=$(jq --arg kp "$KEY_PREFIX" '.customApiKeyResponses.approved = ((.customApiKeyResponses.approved // []) + [$kp] | unique)' "$CLAUDE_JSON")
    echo "$tmp" > "$CLAUDE_JSON"
  fi
fi

# Configure git user from environment variables
[ -n "$GIT_USER_NAME" ] && git config --global user.name "$GIT_USER_NAME"
[ -n "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"

# Configure git with GitHub token if provided
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
  git config --global url."https://github.com/".insteadOf "git@github.com:"
  echo "$GITHUB_TOKEN" | gh auth login --with-token
  gh auth setup-git
fi

# Re-exec with Docker group membership if needed
DOCKER_GROUP_EXEC=()
if [ -S /var/run/docker.sock ]; then
  DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
  DOCKER_GROUP=$(getent group "$DOCKER_GID" | cut -d: -f1)
  # Use sg if the socket's group isn't active in this process
  if ! id -Gn 2>/dev/null | grep -qw "$DOCKER_GROUP"; then
    DOCKER_GROUP_EXEC=(sg "$DOCKER_GROUP" -c)
  fi
fi

if [ $# -gt 0 ]; then
  if [ ${#DOCKER_GROUP_EXEC[@]} -gt 0 ]; then
    exec "${DOCKER_GROUP_EXEC[@]}" "$(printf '%q ' "$@")"
  else
    exec "$@"
  fi
else
  if [ ${#DOCKER_GROUP_EXEC[@]} -gt 0 ]; then
    exec "${DOCKER_GROUP_EXEC[@]}" /bin/zsh
  else
    exec /bin/zsh
  fi
fi
