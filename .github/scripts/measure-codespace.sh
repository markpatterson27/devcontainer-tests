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
RESULTS_FILE_PATH="${RESULTS_FILE_PATH:-./codespace_measurement_results.csv}"


echo "Measure Codespace with following parameters:
  Repo: $REPO
  Iterations: $ITERATIONS
  Machine: $MACHINE
  Devcontainer Path: $DEVCONTAINER_PATH
  Results File: $RESULTS_FILE_PATH
"

# get devcontainer name from path: .devcontainer/<name>/devcontainer.json
DEVCONTAINER_NAME=$(basename $(dirname "$DEVCONTAINER_PATH"))

# initialize CSV file with headers if it doesn't exist
if [[ ! -f "$RESULTS_FILE_PATH" ]]; then
  echo "Iteration,DevContainer,Machine,Available_Time_Sec,Poll_Interval_Sec,PostCreate_Time_Sec,Timestamp" > "$RESULTS_FILE_PATH"
  echo "Created CSV file: $RESULTS_FILE_PATH"
fi

# measure codespace creation times
results=()
for (( i=1; i<=ITERATIONS; i++ )); do
  echo "=== Iteration $i of $ITERATIONS ==="

  # create branch for this iteration
  ITER_BRANCH="codespace-measure-${DEVCONTAINER_NAME}-iter${i}"
  CODESPACE_NAME=""
  available_elapsed=""
  postcreate_elapsed=""
  
  # trap cleanup to ensure it runs even on error
  cleanup() {
    echo "Running cleanup..."
    if [[ -n "$CODESPACE_NAME" ]]; then
      echo "Deleting codespace '$CODESPACE_NAME'..."
      gh codespace delete -c "$CODESPACE_NAME" --force 2>/dev/null || echo "Failed to delete codespace (may not exist)"
    fi
    
    if [[ -n "$ITER_BRANCH" ]]; then
      echo "Cleaning up branch '$ITER_BRANCH'..."
      git checkout main 2>/dev/null || true
      git branch -D "$ITER_BRANCH" 2>/dev/null || echo "Failed to delete local branch (may not exist)"
      git push origin --delete "$ITER_BRANCH" 2>/dev/null || echo "Failed to delete remote branch (may not exist)"
    fi
    echo "Cleanup completed for iteration $i"
  }
  trap cleanup EXIT
  
  # Create branch, overwriting if it already exists
  git checkout -B "$ITER_BRANCH" > /dev/null
  git push -u origin "$ITER_BRANCH" --force > /dev/null
  echo "Created and switched to branch $ITER_BRANCH"

  # creation timestamp
  create_ts_ms=$(date +%s.%3N)
  create_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "Codespace creation started at ${create_iso} (${create_ts_ms} ms)"

  # create codespace (non-blocking)
  cs_cmd=(gh codespace create --repo "$REPO" --machine "$MACHINE" --devcontainer-path "$DEVCONTAINER_PATH" --branch "$ITER_BRANCH" --default-permissions)
  echo "Running: ${cs_cmd[*]}"
  set +e
  CODESPACE_NAME=$("${cs_cmd[@]}" 2>/dev/null)
  ret=$?
  set -e
  if [[ $ret -ne 0 || -z "$CODESPACE_NAME" ]]; then
    echo "Failed to create codespace. (gh codespace create exited with code $ret)"
    trap - EXIT
    cleanup
    continue
  fi
  echo "** Codespace '$CODESPACE_NAME' creation initiated."

  # measure provisioning time: state available
  timeout_time=$(( $(date +%s) + TIMEOUT_SEC )) # timeout: now + TIMEOUT_SEC
  found=false
  while [[ $(date +%s) -lt $timeout_time ]]; do
    sleep "$POLL_INTERVAL_SEC"
    set +e
    status=$(gh codespace view -c "$CODESPACE_NAME" --json state --jq ".state" 2>/dev/null)
    view_ret=$?
    set -e
    
    if [[ $view_ret -ne 0 ]]; then
      echo "Error viewing codespace. (gh codespace view exited with code $view_ret)"
    
    elif [[ "$status" == "Available" ]]; then
      end_time=$(date +%s)
      available_elapsed=$((end_time - ${create_ts_ms%.*}))
      echo "Codespace '$CODESPACE_NAME' is available after ${available_elapsed}s"
      found=true
      break

    # if codespace is in error state, break and report
    elif [[ "$status" == "Error" || "$status" == "Deleted" ]]; then
      echo "Codespace '$CODESPACE_NAME' entered error state: $status"
      break
    
    else
      echo "Current status: $status. Elapsed time: $(( $(date +%s) - ${create_ts_ms%.*} ))s. Checking again in ${POLL_INTERVAL_SEC}s..."
    fi
  done

  if [[ $(date +%s) -ge $timeout_time ]]; then
    echo "Timeout waiting for codespace to be Available after ${TIMEOUT_SEC}s"
  fi

  # get postcreate timestamp from branch
  if [[ "$found" == true ]]; then
    sleep 10  # wait a bit for postcreate script to finish
    echo "Retrieving post-create timestamp from branch '$ITER_BRANCH'..."
    set +e
    git pull origin "$ITER_BRANCH" 2>/dev/null
    set -e
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

  # store results
  results+=("$i, ${available_elapsed:-N/A}, ${postcreate_elapsed:-N/A}")
  
  # append to CSV file
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "$i,$DEVCONTAINER_NAME,$MACHINE,${available_elapsed:-N/A},$POLL_INTERVAL_SEC,${postcreate_elapsed:-N/A},$timestamp" >> "$RESULTS_FILE_PATH"
  echo "Results appended to $RESULTS_FILE_PATH"

  # cleanup for this iteration
  trap - EXIT
  cleanup
     
done
echo "=== Finished all iterations ==="
echo ""

# if all iterations failed exit with error
if [[ ${#results[@]} -eq 0 ]]; then
  echo "All iterations failed."
  exit 1
fi

# print results in table format
echo "Results:"
echo "-----------------------------------------------------------"
printf "%-12s | %-20s | %-20s\n" "Iteration" "Available Time (s) (accuracy ±${POLL_INTERVAL_SEC}s)" "Post-create Time (s)"
echo "-----------------------------------------------------------"
for result in "${results[@]}"; do
  printf "%-12s | %-20s | %-20s\n" $(echo "$result" | tr ',' ' ')
done
echo "-----------------------------------------------------------"
echo ""
echo "Measurement completed."
echo "Results written to: $RESULTS_FILE_PATH"
