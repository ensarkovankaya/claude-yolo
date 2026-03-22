#!/bin/zsh

# Create symlink from host home to container home so plugin absolute paths resolve
if [ -n "$HOST_HOME" ] && [ "$HOST_HOME" != "/home/node" ]; then
  sudo mkdir -p "$(dirname "$HOST_HOME")"
  sudo ln -sfn /home/node "$HOST_HOME"
fi

# Ensure skipDangerousModePermissionPrompt in settings.json
SETTINGS="/home/node/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  tmp=$(jq '.skipDangerousModePermissionPrompt = true' "$SETTINGS")
  echo "$tmp" > "$SETTINGS"
else
  echo '{"skipDangerousModePermissionPrompt":true}' > "$SETTINGS"
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

if [ $# -gt 0 ]; then
  exec "$@"
else
  exec /bin/zsh
fi
