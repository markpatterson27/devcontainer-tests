#!/bin/bash
# Create timestamp file with timestamp

TIMESTAMP_FILE="${1:-./.postcreate_ms}"

# #create directory if it doesn't exist
# mkdir -p "$(dirname "$TIMESTAMP_FILE")"

date +%s.%3N > "$TIMESTAMP_FILE"
echo "Timestamp written to $TIMESTAMP_FILE"

# commit the timestamp file
git add "$TIMESTAMP_FILE"
git commit -m "Update postcreate timestamp"
echo "Timestamp file committed to git"

# push the commit
git push origin HEAD
echo "Timestamp file pushed to remote repository"
