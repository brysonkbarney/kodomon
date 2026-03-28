#!/bin/bash
# Kodomon — Claude Code SessionStart hook
# Writes a session_start event to the shared JSONL file

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"

mkdir -p "$KODOMON_DIR"

SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
CWD="${PWD:-unknown}"
TS=$(date +%s)

echo "{\"type\":\"session_start\",\"ts\":$TS,\"session_id\":\"$SESSION_ID\",\"cwd\":\"$CWD\"}" >> "$EVENT_FILE"
