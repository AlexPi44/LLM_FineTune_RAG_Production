#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${CODESPACE_WORKSPACE_FOLDER:-$(pwd)}"
PROJECT_DIR="$WORKSPACE_ROOT/LLM-Engineers-Handbook"
REPO_URL="https://github.com/PacktPublishing/LLM-Engineers-Handbook.git"

cd "$WORKSPACE_ROOT"

if [ ! -d "$PROJECT_DIR/.git" ]; then
  git clone "$REPO_URL" "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

poetry config virtualenvs.in-project true --local
poetry env use "$(which python)"
poetry install --without aws --no-interaction --no-ansi

[ -f .env ] || [ ! -f .env.example ] || cp .env.example .env
