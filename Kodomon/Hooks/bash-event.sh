#!/bin/bash
# Kodomon — Claude Code PostToolUse hook (Bash)
# Detects git commits and captures diff stats

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"
mkdir -p "$KODOMON_DIR"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | /usr/bin/jq -r '.tool_input.command // empty' 2>/dev/null)
TS=$(date +%s)

# Only track git commits
if echo "$COMMAND" | grep -qE '(^|[;&|])\s*git\s+commit'; then
  CWD=$(echo "$INPUT" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null)
  GIT_DIR="${CWD:-.}"

  LINES_ADDED=0
  LINES_REMOVED=0
  FILES_CHANGED=0
  HASH=""

  # Extract diff stats from the commit that just happened
  SHORTSTAT=$(cd "$GIT_DIR" 2>/dev/null && git log -1 --pretty=format: --shortstat 2>/dev/null)
  HASH=$(cd "$GIT_DIR" 2>/dev/null && git log -1 --pretty=format:'%h' 2>/dev/null)

  if [ -n "$SHORTSTAT" ]; then
    FILES_CHANGED=$(echo "$SHORTSTAT" | grep -oE '[0-9]+ file' | head -1 | grep -oE '[0-9]+')
    LINES_ADDED=$(echo "$SHORTSTAT" | grep -oE '[0-9]+ insertion' | head -1 | grep -oE '[0-9]+')
    LINES_REMOVED=$(echo "$SHORTSTAT" | grep -oE '[0-9]+ deletion' | head -1 | grep -oE '[0-9]+')
  fi

  /usr/bin/jq -n \
    --arg type "git_commit" \
    --argjson ts "$TS" \
    --arg hash "$HASH" \
    --argjson lines_added "${LINES_ADDED:-0}" \
    --argjson lines_removed "${LINES_REMOVED:-0}" \
    --argjson files "${FILES_CHANGED:-0}" \
    '{type: $type, ts: $ts, hash: $hash, lines_added: $lines_added, lines_removed: $lines_removed, files: $files}' >> "$EVENT_FILE"
fi
