#!/usr/bin/env bash
# measure-codespace.sh
# Prereqs:
#  - gh CLI installed and authenticated (PAT or gh auth login) with codespaces scope
# Usage:
#  GITHUB_REPO="owner/repo" ./measure-codespace.sh 10
#  First arg = number of iterations (default 5)
set -euo pipefail

REPO="${GITHUB_REPO:-}"
if [[ -z "$REPO" ]]; then
  echo "Set GITHUB_REPO env var to owner/repo (e.g. my-org/my-repo)"
  exit 1
fi

ITERATIONS="${ITERATIONS:-5}"
MACHINE="${CODESPACE_MACHINE:-standardLinux32gb}"       # optional, e.g. "standardLinuxLarge"

DEVCONTAINER_PATH="${DEVCONTAINER_PATH:-}" # path to devcontainer.json inside repo
if [[ -z "$DEVCONTAINER_PATH" ]]; then
  echo "DEVCONTAINER_PATH is not set"
  exit 1
fi


echo "Measure Codespace with following parameters:
  Repo: $REPO
  Iterations: $ITERATIONS
  Machine: $MACHINE
  Devcontainer Path: $DEVCONTAINER_PATH
"
