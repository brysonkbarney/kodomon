#!/bin/bash
# Kodomon — Claude Code / Codex PostToolUse hook (Bash)
# Detects git commits and captures diff stats

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"
mkdir -p "$KODOMON_DIR"
JQ=$(command -v jq 2>/dev/null || echo /usr/bin/jq)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | "${JQ:-jq}" -r '.tool_input.command // empty' 2>/dev/null)
TS=$(date +%s)
GIT_COMMIT_RE='(^|[;&|])[[:space:]]*git[[:space:]]+((-C[[:space:]]+("[^"]+"|[^[:space:];&|]+)[[:space:]]+)?)commit'
GIT_C_DOUBLE_RE='(^|[;&|])[[:space:]]*git[[:space:]]+-C[[:space:]]+"([^"]+)"[[:space:]]+commit'
GIT_C_PLAIN_RE='(^|[;&|])[[:space:]]*git[[:space:]]+-C[[:space:]]+([^[:space:];&|]+)[[:space:]]+commit'

# Only track git commits
if [[ "$COMMAND" =~ $GIT_COMMIT_RE ]]; then
  CWD=$(echo "$INPUT" | "${JQ:-jq}" -r '.cwd // empty' 2>/dev/null)
  GIT_DIR="${CWD:-.}"
  if [[ "$COMMAND" =~ $GIT_C_DOUBLE_RE ]]; then
    GIT_DIR="${BASH_REMATCH[2]}"
  elif [[ "$COMMAND" =~ $GIT_C_PLAIN_RE ]]; then
    GIT_DIR="${BASH_REMATCH[2]}"
  fi

  if [[ "$GIT_DIR" != /* && -n "$CWD" ]]; then
    GIT_DIR="$CWD/$GIT_DIR"
  fi

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

  "${JQ:-jq}" -nc \
    --arg type "git_commit" \
    --argjson ts "$TS" \
    --arg hash "$HASH" \
    --argjson lines_added "${LINES_ADDED:-0}" \
    --argjson lines_removed "${LINES_REMOVED:-0}" \
    --argjson files "${FILES_CHANGED:-0}" \
    '{type: $type, ts: $ts, hash: $hash, lines_added: $lines_added, lines_removed: $lines_removed, files: $files}' >> "$EVENT_FILE"
fi
