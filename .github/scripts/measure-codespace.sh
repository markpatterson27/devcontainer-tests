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
MACHINE="${CODESPACE_MACHINE:-standardLinux32gb}"  # optional, e.g. "standardLinuxLarge"

DEVCONTAINER_PATH="${DEVCONTAINER_PATH:-}"  # path to devcontainer.json inside repo
if [[ -z "$DEVCONTAINER_PATH" ]]; then
  echo "DEVCONTAINER_PATH is not set"
  exit 1
fi
if [[ ! -f "$DEVCONTAINER_PATH" ]]; then
  echo "DEVCONTAINER_PATH '$DEVCONTAINER_PATH' does not exist"
  exit 1
fi

TIMEOUT_SEC="${TIMEOUT_SEC:-900}"  # optional timeout for codespace creation
POLL_INTERVAL_SEC="${POLL_INTERVAL_SEC:-5}"  # optional poll interval for checking codespace status

POSTCREATE_FILE_PATH=".postcreate_ms"


echo "Measure Codespace with following parameters:
  Repo: $REPO
  Iterations: $ITERATIONS
  Machine: $MACHINE
  Devcontainer Path: $DEVCONTAINER_PATH
"

# get devcontainer name from path: .devcontainer/<name>/devcontainer.json
DEVCONTAINER_NAME=$(basename $(dirname "$DEVCONTAINER_PATH"))

# measure codespace creation times
results=()
for (( i=1; i<=ITERATIONS; i++ )); do
  echo "=== Iteration $i of $ITERATIONS ==="

  # create branch for this iteration
  ITER_BRANCH="codespace-measure-${DEVCONTAINER_NAME}-iter${i}"
  git checkout -b "$ITER_BRANCH"
  git push -u origin "$ITER_BRANCH"
  echo "Created and switched to branch $ITER_BRANCH"

  # creation timestamp
  create_ts_ms=$(date +%s.%3N)
  create_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "Codespace creation started at ${create_iso} (${create_ts_ms} ms)"

  # create codespace (non-blocking)
  set +e
  CODESPACE_NAME=$(gh codespace create --repo "$REPO" --machine "$MACHINE" --devcontainer-path "$DEVCONTAINER_PATH" --branch "$ITER_BRANCH" --default-permissions 2>/dev/null)
  ret=$?
  set -e
  if [[ $ret -ne 0 || -z "$CODESPACE_NAME" ]]; then
    echo "Failed to create codespace. (gh codespace create exited with code $ret)"
    exit 1
  fi
  echo "Codespace '$CODESPACE_NAME' creation initiated."

  # measure provisioning time: state available
  timeout_time=$(( $(date +%s) + TIMEOUT_SEC )) # timeout: now + TIMEOUT_SEC
  found=false
  while [[ $(date +%s) -lt $TIMEOUT_TIME ]]; do
    sleep "$POLL_INTERVAL_SEC"
    status=$(gh codespace view -c "$CODESPACE_NAME" --json state --jq ".state")
    if [[ "$status" == "Available" ]]; then
      end_time=$(date +%s)
      available_elapsed=$((end_time - ${create_ts_ms%.*}))
      echo "Codespace '$CODESPACE_NAME' is available after ${available_elapsed}s"
      found=true
      break
    fi

    # if codespace is in error state, break and report
    if [[ "$status" == "Error" || "$status" == "Deleted" ]]; then
      echo "Codespace '$CODESPACE_NAME' entered error state: $status"
      break
    fi

    echo "Current status: $status. Elapsed time: $(( $(date +%s) - ${create_ts_ms%.*} ))s. Checking again in ${POLL_INTERVAL_SEC}s..."
  done

  if [[ $(date +%s) -ge $TIMEOUT_TIME ]]; then
    echo "Timeout waiting for codespace to be Available after ${TIMEOUT_SEC}s"
  fi

  # get postcreate timestamp from branch
  if [[ "$found" == true ]]; then
    sleep 10  # wait a bit for postcreate script to finish
    git pull origin "$ITER_BRANCH"
    if [[ -f "$POSTCREATE_FILE_PATH" ]]; then
      postcreate_time=$(cat "$POSTCREATE_FILE_PATH")
      postcreate_iso=$(date -u -d "@${postcreate_time%.*}" +"%Y-%m-%dT%H:%M:%SZ")
      postcreate_elapsed=$(( ${postcreate_time%.*} - ${create_ts_ms%.*} ))
      echo "Post-create script completed at ${postcreate_iso} (${postcreate_time} ms), elapsed time: ${postcreate_elapsed}s"
    else
      echo "Post-create timestamp file '$POSTCREATE_FILE_PATH' not found in branch."
    fi
  else
    echo "Skipping post-create timestamp retrieval due to codespace not being available."
  fi

  # cleanup: delete codespace and branch
  gh codespace delete -c "$CODESPACE_NAME" --force
  git checkout main
  git branch -D "$ITER_BRANCH"
  git push origin --delete "$ITER_BRANCH"
  echo "Cleaned up codespace and branch '$ITER_BRANCH'"

  # store results
  results+=("Iteration $i: Available after ${available_elapsed:-N/A}s, Post-create after ${postcreate_elapsed:-N/A}s")
     
done
echo "=== Finished all iterations ==="
echo ""

# print results
echo "Results:"
for result in "${results[@]}"; do
  echo "$result"
done
echo ""
echo "Measurement completed."
