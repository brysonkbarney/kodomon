#!/bin/bash
# Kodomon — Claude Code PostToolUse hook (Write/Edit)
# Writes a file_write event to the shared JSONL file

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"

mkdir -p "$KODOMON_DIR"

# Tool input is passed via CLAUDE_TOOL_INPUT env var
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-unknown}"
TS=$(date +%s)

echo "{\"type\":\"file_write\",\"ts\":$TS,\"file\":\"$FILE_PATH\"}" >> "$EVENT_FILE"
