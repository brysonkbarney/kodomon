#!/bin/bash
# Kodomon — Claude Code / Codex PostToolUse hook
# Reads JSON from stdin, writes file_write events with line counts to JSONL

KODOMON_DIR="$HOME/.kodomon"
EVENT_FILE="$KODOMON_DIR/events.jsonl"
mkdir -p "$KODOMON_DIR"
JQ=$(command -v jq 2>/dev/null || echo /usr/bin/jq)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | "${JQ:-jq}" -r '.tool_input.file_path // empty' 2>/dev/null || echo "unknown")
TOOL_NAME=$(echo "$INPUT" | "${JQ:-jq}" -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | "${JQ:-jq}" -r '.cwd // empty' 2>/dev/null)
TS=$(date +%s)

write_event() {
  local file="$1"
  local tool="$2"
  local lines="${3:-0}"

  if [ -n "$file" ]; then
    if [[ "$file" != /* && -n "$CWD" ]]; then
      file="$CWD/$file"
    fi
    "${JQ:-jq}" -nc \
      --arg type "file_write" \
      --argjson ts "$TS" \
      --arg file "$file" \
      --arg tool "$tool" \
      --argjson lines "$lines" \
      '{type: $type, ts: $ts, file: $file, tool: $tool, lines: $lines}' >> "$EVENT_FILE"
  fi
}

# Count lines written
LINES=0
if [ "$TOOL_NAME" = "Write" ]; then
  LINES=$(echo "$INPUT" | "${JQ:-jq}" -r '.tool_input.content // empty' 2>/dev/null | wc -l | tr -d ' ')
elif [ "$TOOL_NAME" = "Edit" ]; then
  LINES=$(echo "$INPUT" | "${JQ:-jq}" -r '.tool_input.new_string // empty' 2>/dev/null | wc -l | tr -d ' ')
elif [ "$TOOL_NAME" = "MultiEdit" ]; then
  LINES=$(echo "$INPUT" | "${JQ:-jq}" -r '[.tool_input.edits[]?.new_string // empty | split("\n") | length] | add // 0' 2>/dev/null || echo 0)
elif [ "$TOOL_NAME" = "apply_patch" ]; then
  PATCH=$(echo "$INPUT" | "${JQ:-jq}" -r '.tool_input.patch // .tool_input.command // empty' 2>/dev/null)

  # Codex reports file edits as apply_patch. Emit one Kodomon file_write
  # event per touched path, using changed patch lines as the activity size.
  while IFS="$(printf '\t')" read -r patch_file patch_lines; do
    write_event "$patch_file" "$TOOL_NAME" "${patch_lines:-0}"
  done < <(
    printf '%s\n' "$PATCH" | awk '
      /^\*\*\* (Add|Update|Delete) File: / {
        file = $0
        sub(/^\*\*\* (Add|Update|Delete) File: /, "", file)
        current = file
        seen[file] = 1
        next
      }
      /^\*\*\* / {
        current = ""
        next
      }
      current != "" && /^[+-]/ {
        counts[current]++
      }
      END {
        for (file in seen) {
          printf "%s\t%d\n", file, counts[file] + 0
        }
      }
    '
  )
  exit 0
fi

write_event "$FILE_PATH" "$TOOL_NAME" "${LINES:-0}"
