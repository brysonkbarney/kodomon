#!/bin/bash
# Kodomon — Claude Code PostToolUse hook (Write/Edit)
# Reads JSON from stdin, writes file_write event with line count to JSONL

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"
mkdir -p "$KODOMON_DIR"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | /usr/bin/jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "unknown")
TOOL_NAME=$(echo "$INPUT" | /usr/bin/jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
TS=$(date +%s)

# Count lines written
LINES=0
if [ "$TOOL_NAME" = "Write" ]; then
  LINES=$(echo "$INPUT" | /usr/bin/jq -r '.tool_input.content // empty' 2>/dev/null | wc -l | tr -d ' ')
elif [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "MultiEdit" ]; then
  LINES=$(echo "$INPUT" | /usr/bin/jq -r '.tool_input.new_string // empty' 2>/dev/null | wc -l | tr -d ' ')
fi

if [ -n "$FILE_PATH" ]; then
  /usr/bin/jq -n \
    --arg type "file_write" \
    --argjson ts "$TS" \
    --arg file "$FILE_PATH" \
    --arg tool "$TOOL_NAME" \
    --argjson lines "${LINES:-0}" \
    '{type: $type, ts: $ts, file: $file, tool: $tool, lines: $lines}' >> "$EVENT_FILE"
fi
