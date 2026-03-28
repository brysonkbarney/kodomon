#!/bin/bash
# Kodomon — Claude Code PostToolUse hook (Write/Edit)
# Reads JSON from stdin, writes file_write event to JSONL

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"
mkdir -p "$KODOMON_DIR"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | /usr/bin/jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "unknown")
TOOL_NAME=$(echo "$INPUT" | /usr/bin/jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
TS=$(date +%s)

if [ -n "$FILE_PATH" ]; then
  echo "{\"type\":\"file_write\",\"ts\":$TS,\"file\":\"$FILE_PATH\",\"tool\":\"$TOOL_NAME\"}" >> "$EVENT_FILE"
fi
