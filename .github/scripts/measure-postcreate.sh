#!/usr/bin/env bash
#
# measure-postcreate.sh
# Measure Codespace postCreateCommand completion time by detecting a sentinel file
# written by your devcontainer's postCreateCommand (recommended: write epoch ms).
#
# Requirements:
#  - gh CLI (authenticated user with codespaces permissions)
#  - bash, jq (optional), python (optional, used for nicer stats if available)
#
# Usage:
#  GITHUB_REPO="owner/repo" ./scripts/measure-postcreate.sh [options]
#
# Options:
#  --repo OWNER/REPO        Repository to create codespace for (or set GITHUB_REPO env)
#  --iterations N           Number of iterations (default: 5)
#  --machine NAME           Codespace machine type (e.g. standardLinux, standardLinuxLarge)
#  --devcontainer-path PATH Path to devcontainer.json in repo (relative) (passed to gh)
#  --sentinel RELPATH       Path (relative to repo root) or absolute path in codespace for the sentinel file.
#                          Default: .postcreate_ms (i.e. /workspaces/<repo>/.postcreate_ms)
#  --timeout SECONDS        Per-iteration timeout waiting for sentinel (default: 900)
#  --poll SECONDS           Poll interval in seconds (default: 5)
#  --keep                   Keep codespaces after measurement (do not delete)
#  --help                   Show this help
#
# Example (recommended devcontainer change):
#  In your devcontainer.json include:
#    "postCreateCommand": "date +%s%3N > /workspaces/${GITHUB_REPOSITORY##*/}/.postcreate_ms || true"
#
set -euo pipefail

PROGNAME="$(basename "$0")"
print_help() {
  sed -n '1,200p' "$0" | sed -n '1,200p' | sed -n '1,200p' >/dev/null 2>&1 || true
  cat <<EOF
$PROGNAME - measure Codespace postCreate completion time

Usage:
  GITHUB_REPO="owner/repo" $PROGNAME [options]

Options:
  --repo OWNER/REPO        Repository to create codespace for (or set GITHUB_REPO env)
  --iterations N           Number of iterations (default: 5)
  --machine NAME           Codespace machine type (optional)
  --devcontainer-path PATH Path to devcontainer.json in repo (optional)
  --sentinel RELPATH       Path (relative to repo root) or absolute path in codespace for the sentinel file.
                           Default: .postcreate_ms (i.e. /workspaces/<repo>/.postcreate_ms)
  --timeout SECONDS        Per-iteration timeout waiting for sentinel (default: 900)
  --poll SECONDS           Poll interval in seconds (default: 5)
  --keep                   Keep codespaces after measurement (do not delete)
  --help                   Show this help
EOF
}

# Defaults
ITERATIONS=5
MACHINE=""
DEVCONTAINER_PATH=""
SENTINEL_REL=".postcreate_ms"
TIMEOUT=900
POLL=5
KEEP=false

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --iterations) ITERATIONS="$2"; shift 2;;
    --machine) MACHINE="$2"; shift 2;;
    --devcontainer-path) DEVCONTAINER_PATH="$2"; shift 2;;
    --sentinel) SENTINEL_REL="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    --poll) POLL="$2"; shift 2;;
    --keep) KEEP=true; shift ;;
    --help) print_help; exit 0 ;;
    *) echo "Unknown arg: $1"; print_help; exit 1 ;;
  esac
done

REPO="${REPO:-${GITHUB_REPO:-}}"
if [[ -z "$REPO" ]]; then
  echo "ERROR: repository not specified. Set --repo or GITHUB_REPO."
  exit 2
fi

# utilities
epoch_ms() {
  # Try GNU date, fallback to python
  if date +%s%3N >/dev/null 2>&1; then
    date +%s%3N
  else
    python - <<'PY'
import time
print(int(time.time() * 1000))
PY
  fi
}

timestamp_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

repo_name="${REPO##*/}"
# If sentinel is absolute (starts with /) use as-is; otherwise prefix workspace path
if [[ "${SENTINEL_REL:0:1}" = "/" ]]; then
  SENTINEL_PATH="$SENTINEL_REL"
else
  SENTINEL_PATH="/workspaces/${repo_name}/${SENTINEL_REL}"
fi

echo "Repository: $REPO"
echo "Sentinel path (in codespace): $SENTINEL_PATH"
echo "Iterations: $ITERATIONS"
echo "Machine: ${MACHINE:-(default)}"
echo "Devcontainer path: ${DEVCONTAINER_PATH:-(default)}"
echo "Per-iteration timeout: ${TIMEOUT}s, poll every ${POLL}s"
echo

durations_ms=()
raw_hits=()

for i in $(seq 1 "$ITERATIONS"); do
  echo "=== Iteration $i/$ITERATIONS ==="
  create_ts_ms=$(epoch_ms)
  create_iso=$(timestamp_iso)
  echo "Create request @ $create_iso (${create_ts_ms} ms)"

  # Create codespace (non-blocking). Capture name.
  create_cmd=(gh codespace create --repo "$REPO" --json name --jq '.[0].name')
  if [[ -n "$MACHINE" ]]; then
    create_cmd+=(--machine "$MACHINE")
  fi
  if [[ -n "$DEVCONTAINER_PATH" ]]; then
    create_cmd+=(--devcontainer-path "$DEVCONTAINER_PATH")
  fi

  set +e
  CODESPACE_NAME="$( "${create_cmd[@]}" 2>/dev/null )"
  ret=$?
  set -e
  if [[ $ret -ne 0 || -z "$CODESPACE_NAME" ]]; then
    echo "Failed to create codespace (gh returned $ret). Output: $CODESPACE_NAME"
    exit 3
  fi
  echo "Created codespace: $CODESPACE_NAME"

  found=false
  elapsed=0
  start_wait_ts_ms="$create_ts_ms"
  while [[ $elapsed -lt $TIMEOUT ]]; do
    sleep "$POLL"
    elapsed=$((elapsed + POLL))
    # Try to exec a small test inside the codespace to read the sentinel.
    # Use 'bash -lc' so the test runs inside the codespace environment.
    out=""
    set +e
    out="$(gh codespace exec --codespace "$CODESPACE_NAME" -- bash -lc "if [ -f '$SENTINEL_PATH' ]; then cat '$SENTINEL_PATH'; fi" 2>/dev/null || true)"
    rc=$?
    set -e

    now_ms=$(epoch_ms)
    echo "  poll ${elapsed}s: exec rc=$rc, sentinel raw='${out}'"

    if [[ -n "$out" ]]; then
      # Trim whitespace
      out_trimmed="$(echo "$out" | tr -d '\r\n\t ' )"
      # If sentinel contains an integer timestamp, use it. Detect seconds vs ms
      if [[ "$out_trimmed" =~ ^[0-9]+$ ]]; then
        # Determine if sentinel is in seconds or ms
        if [[ ${#out_trimmed} -ge 13 ]]; then
          postcreate_ms="$out_trimmed"
        elif [[ ${#out_trimmed} -ge 10 ]]; then
          # likely seconds -> convert to ms
          postcreate_ms=$(( out_trimmed * 1000 ))
        else
          # too short; fallback to detection time
          postcreate_ms="$now_ms"
        fi
        duration_ms=$(( postcreate_ms - create_ts_ms ))
        echo "  Detected sentinel with timestamp ${postcreate_ms} (duration ${duration_ms} ms)"
      else
        # sentinel exists but not a timestamp: use detection time
        postcreate_ms="$now_ms"
        duration_ms=$(( postcreate_ms - create_ts_ms ))
        echo "  Sentinel exists (non-timestamp content). Using detection time ${postcreate_ms} (duration ${duration_ms} ms)"
      fi

      durations_ms+=("$duration_ms")
      raw_hits+=("$out_trimmed")
      found=true
      break
    fi

    # If the codespace is in an error state, break early
    state="$(gh codespace list --json name,state --jq ".[] | select(.name==\"$CODESPACE_NAME\") | .state" 2>/dev/null || echo "")"
    if [[ -n "$state" ]]; then
      state_clean="$(echo "$state" | tr -d '"')"
      if [[ "$state_clean" == "Deleted" || "$state_clean" == "Error" ]]; then
        echo "  Codespace entered state: $state_clean — aborting wait"
        break
      fi
    fi
  done

  if ! $found; then
    echo "  Timeout after ${TIMEOUT}s waiting for sentinel. Recording as failed (duration = -1)"
    durations_ms+=("-1")
    raw_hits+=("")
  fi

  if ! $KEEP; then
    echo "Deleting codespace $CODESPACE_NAME"
    gh codespace delete -c "$CODESPACE_NAME" --confirm || true
  else
    echo "Keeping codespace $CODESPACE_NAME (per --keep)"
  fi

  # short cooldown between iterations
  sleep 3
done

echo
echo "=== Summary ==="
# Print raw durations
for idx in "${!durations_ms[@]}"; do
  iter=$((idx+1))
  d=${durations_ms[idx]}
  echo "Iteration $iter: ${d} ms (sentinel='${raw_hits[idx]}')"
done

# Compute stats for successful runs
valid=()
for v in "${durations_ms[@]}"; do
  if [[ "$v" != "-1" ]]; then
    valid+=("$v")
  fi
done

count_total=${#durations_ms[@]}
count_ok=${#valid[@]}

echo
echo "Total iterations: $count_total"
echo "Successful detections: $count_ok"

if [[ $count_ok -eq 0 ]]; then
  echo "No successful postCreate detections. Ensure your devcontainer's postCreateCommand writes a sentinel file with epoch ms at: $SENTINEL_PATH"
  exit 0
fi

# Use python for stats if available
if command -v python >/dev/null 2>&1; then
  python - <<PY
import sys, json, statistics
vals = list(map(int, ${valid[@]:-[]}))
vals_sorted = sorted(vals)
print("Stats (ms):")
print("  min:   ", vals_sorted[0])
print("  max:   ", vals_sorted[-1])
print("  avg:   ", int(sum(vals_sorted)/len(vals_sorted)))
print("  median:", int(statistics.median(vals_sorted)))
def pxx(arr, p):
    import math
    k = max(0, min(len(arr)-1, int(math.ceil(p/100.0*len(arr))-1)))
    return arr[k]
print("  p95:   ", pxx(vals_sorted,95))
print("  samples:", len(vals_sorted))
PY
else
  # simple shell stats
  sum=0
  min=""
  max=""
  for v in "${valid[@]}"; do
    sum=$((sum + v))
    if [[ -z "$min" || v -lt "$min" ]]; then min=$v; fi
    if [[ -z "$max" || v -gt "$max" ]]; then max=$v; fi
  done
  avg=$((sum / count_ok))
  echo "Stats (ms):"
  echo "  min:   $min"
  echo "  max:   $max"
  echo "  avg:   $avg"
  echo "  samples: $count_ok"
fi

echo
echo "Finished. Tips:"
echo " - Ensure your devcontainer's postCreateCommand writes epoch ms into $SENTINEL_PATH for precise timing."
echo " - Example devcontainer.json snippet:"
cat <<'JSON'
"postCreateCommand": "date +%s%3N > /workspaces/${GITHUB_REPOSITORY##*/}/.postcreate_ms || true"
JSON

exit 0