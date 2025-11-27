#!/bin/bash
# Create timestamp file with timestamp

TIMESTAMP_FILE="${1:-./.measure/postcreate_ms}"

#create directory if it doesn't exist
mkdir -p "$(dirname "$TIMESTAMP_FILE")"

date +%s.%3N > "$TIMESTAMP_FILE"
echo "Timestamp written to $TIMESTAMP_FILE"
