#!/bin/bash
# Documentation Update Reminder Hook
# Triggers after Edit/Write operations on key files

# Read stdin (JSON with tool_input containing file_path)
INPUT=$(cat)

# Extract file_path from JSON
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//' | sed 's/"$//')

# Check if this is a significant file change (not documentation itself)
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Skip if editing documentation files themselves
if [[ "$FILE_PATH" == *"CLAUDE.md"* ]] || \
   [[ "$FILE_PATH" == *"TODO.md"* ]] || \
   [[ "$FILE_PATH" == *"README.md"* ]]; then
    exit 0
fi

# Check if this is a significant code file
SIGNIFICANT_DIRS=("Core/" "Features/" "DesignSystem/" "Engine/" "Services/")
IS_SIGNIFICANT=false

for DIR in "${SIGNIFICANT_DIRS[@]}"; do
    if [[ "$FILE_PATH" == *"$DIR"* ]]; then
        IS_SIGNIFICANT=true
        break
    fi
done

# Output reminder to stderr (which Claude sees)
if [[ "$IS_SIGNIFICANT" == true ]]; then
    echo "DOCS REMINDER: Consider updating documentation after significant changes:" >&2
    echo "  - TODO.md: Update task status or add new tasks" >&2
    echo "  - CLAUDE.md: Update File Index if new files added" >&2
    echo "  - README.md: Update if architecture changed" >&2
fi

exit 0
