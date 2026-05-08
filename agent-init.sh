#!/bin/bash
set -e

# ==========================================
# 1. Identity Configuration
# ==========================================
export GIT_USER_NAME="${GIT_USER_NAME:-"agent"}"
export GIT_USER_EMAIL="${GIT_USER_EMAIL:-"agent@local"}"

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# ==========================================
# 2. Local LLM Server Configuration
# ==========================================
export OPENAI_API_BASE="${OPENAI_API_BASE:-"http://llm-server:8080/v1"}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-"sk-no-key-required"}"

# ==========================================
# 3. External API Key Placeholders
# ==========================================
# If you decide to bypass the local LLM and use remote models:
export AIDER_API_KEY="${AIDER_API_KEY:-""}"
export OPENCODE_API_KEY="${OPENCODE_API_KEY:-""}"

# Execute the container's main process (e.g. /bin/bash)
exec "$@"

