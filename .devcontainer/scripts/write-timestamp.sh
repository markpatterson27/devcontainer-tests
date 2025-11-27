#!/bin/bash

# Create timestamp file with timestamp
TIMESTAMP_FILE="${1:-./.postcreate_ms}"
date +%s.%3N > "$TIMESTAMP_FILE"
echo "Timestamp written to $TIMESTAMP_FILE"
