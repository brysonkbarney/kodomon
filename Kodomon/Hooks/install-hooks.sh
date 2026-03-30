#!/bin/bash
# Kodomon — one-time hook installer
# Copies hook scripts and wires up Claude Code hooks
# Does NOT touch git config or any repos

set -e

KODOMON_DIR="$HOME/.kodomon"
HOOKS_DIR="$KODOMON_DIR/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Kodomon hooks..."

# Create directories
mkdir -p "$HOOKS_DIR"

# Copy hook scripts (Claude Code only — no git hooks)
cp "$SCRIPT_DIR/session-start.sh" "$HOOKS_DIR/"
cp "$SCRIPT_DIR/file-event.sh" "$HOOKS_DIR/"
cp "$SCRIPT_DIR/session-stop.sh" "$HOOKS_DIR/"

# Make executable
chmod +x "$HOOKS_DIR"/*.sh

# Create empty events file if it doesn't exist
touch "$KODOMON_DIR/events.jsonl"

echo "  ✓ Hook scripts installed to $HOOKS_DIR"

# Install Claude Code hooks into ~/.claude/settings.json
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    if grep -q "kodomon" "$CLAUDE_SETTINGS" 2>/dev/null; then
        echo "  ✓ Claude Code hooks already configured"
    else
        echo "  ⚠ Claude Code settings exist — please add hooks manually"
        echo "    See: ~/.kodomon/hooks/README for the config to add"
    fi
else
    mkdir -p "$HOME/.claude"
    cat > "$CLAUDE_SETTINGS" << 'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.kodomon/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.kodomon/hooks/file-event.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.kodomon/hooks/session-stop.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
    echo "  ✓ Claude Code hooks configured"
fi

echo ""
echo "Kodomon hooks installed!"
