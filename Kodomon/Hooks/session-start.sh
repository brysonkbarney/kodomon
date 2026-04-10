#!/bin/bash
# Kodomon — Claude Code SessionStart hook
# Reads JSON from stdin, writes session_start event to JSONL

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"
mkdir -p "$KODOMON_DIR"
JQ=$(command -v jq 2>/dev/null || echo /usr/bin/jq)

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | "${JQ:-jq}" -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | "${JQ:-jq}" -r '.cwd // "unknown"' 2>/dev/null || echo "unknown")
TS=$(date +%s)

"${JQ:-jq}" -nc \
  --arg type "session_start" \
  --argjson ts "$TS" \
  --arg sid "$SESSION_ID" \
  --arg cwd "$CWD" \
  '{type: $type, ts: $ts, session_id: $sid, cwd: $cwd}' >> "$EVENT_FILE"
