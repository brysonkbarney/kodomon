#!/bin/bash
# Kodomon — git post-commit hook
# Writes a git_commit event to the shared JSONL file

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"

mkdir -p "$KODOMON_DIR"

ADDED=$(git diff HEAD~1 HEAD --numstat 2>/dev/null | awk '{s+=$1} END {print s+0}')
REMOVED=$(git diff HEAD~1 HEAD --numstat 2>/dev/null | awk '{s+=$2} END {print s+0}')
FILES=$(git diff HEAD~1 HEAD --name-only 2>/dev/null | wc -l | tr -d ' ')
HASH=$(git rev-parse --short HEAD 2>/dev/null)
TS=$(date +%s)

echo "{\"type\":\"git_commit\",\"ts\":$TS,\"hash\":\"${HASH:-unknown}\",\"lines_added\":${ADDED:-0},\"lines_removed\":${REMOVED:-0},\"files\":${FILES:-0}}" >> "$EVENT_FILE"
