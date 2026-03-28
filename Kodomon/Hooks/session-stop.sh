#!/bin/bash
# Kodomon — Claude Code Stop hook
# Writes a session_stop event to the shared JSONL file

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"

mkdir -p "$KODOMON_DIR"

SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TS=$(date +%s)

echo "{\"type\":\"session_stop\",\"ts\":$TS,\"session_id\":\"$SESSION_ID\"}" >> "$EVENT_FILE"
