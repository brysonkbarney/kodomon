#!/bin/bash
# Kodomon — Claude Code Stop hook
# Reads JSON from stdin, writes session_stop event to JSONL

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"
mkdir -p "$KODOMON_DIR"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | /usr/bin/jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TS=$(date +%s)

echo "{\"type\":\"session_stop\",\"ts\":$TS,\"session_id\":\"$SESSION_ID\"}" >> "$EVENT_FILE"
