#!/bin/bash
# Kodomon — one-time hook installer
# Copies hook scripts and wires up Claude Code + Codex hooks
# Does NOT touch git config or any repos

set -e

KODOMON_DIR="$HOME/.kodomon"
HOOKS_DIR="$KODOMON_DIR/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Kodomon hooks..."

# Create directories with restricted permissions
mkdir -p "$HOOKS_DIR"
chmod 700 "$KODOMON_DIR"

# Copy hook scripts (agent hooks only — no git hooks)
cp "$SCRIPT_DIR/session-start.sh" "$HOOKS_DIR/"
cp "$SCRIPT_DIR/file-event.sh" "$HOOKS_DIR/"
cp "$SCRIPT_DIR/bash-event.sh" "$HOOKS_DIR/"
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
        # Existing settings.json has no kodomon hooks — merge via jq if available
        if command -v jq >/dev/null 2>&1; then
            BACKUP="$CLAUDE_SETTINGS.kodomon-backup-$(date +%s)"
            cp "$CLAUDE_SETTINGS" "$BACKUP"
            echo "  • Backed up existing settings to $BACKUP"
            KODOMON_HOOKS=$(cat <<'JSON'
{
  "hooks": {
    "SessionStart": [{"hooks":[{"type":"command","command":"~/.kodomon/hooks/session-start.sh"}]}],
    "PostToolUse": [
      {"matcher":"Write|Edit|MultiEdit","hooks":[{"type":"command","command":"~/.kodomon/hooks/file-event.sh"}]},
      {"matcher":"Bash","hooks":[{"type":"command","command":"~/.kodomon/hooks/bash-event.sh"}]}
    ],
    "Stop": [{"hooks":[{"type":"command","command":"~/.kodomon/hooks/session-stop.sh"}]}]
  }
}
JSON
)
            MERGED=$(jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" <(echo "$KODOMON_HOOKS"))
            if [ -n "$MERGED" ]; then
                echo "$MERGED" > "$CLAUDE_SETTINGS"
                echo "  ✓ Merged Kodomon hooks into existing settings.json"
            else
                echo "  ⚠ Merge failed — original settings restored"
            fi
        else
            echo "  ⚠ Claude Code settings exist and jq is not installed."
            echo "    Install jq (brew install jq) and re-run, or add these to $CLAUDE_SETTINGS manually:"
            echo '    "hooks": {'
            echo '      "SessionStart": [{"hooks":[{"type":"command","command":"~/.kodomon/hooks/session-start.sh"}]}],'
            echo '      "PostToolUse": [{"matcher":"Write|Edit|MultiEdit","hooks":[{"type":"command","command":"~/.kodomon/hooks/file-event.sh"}]},{"matcher":"Bash","hooks":[{"type":"command","command":"~/.kodomon/hooks/bash-event.sh"}]}],'
            echo '      "Stop": [{"hooks":[{"type":"command","command":"~/.kodomon/hooks/session-stop.sh"}]}]'
            echo '    }'
        fi
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
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.kodomon/hooks/bash-event.sh"
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

# Install Codex hooks into ~/.codex/hooks.json. Codex also supports hooks in
# config.toml, but hooks.json lets us avoid touching existing user config.
CODEX_DIR="$HOME/.codex"
CODEX_HOOKS="$CODEX_DIR/hooks.json"
KODOMON_CODEX_HOOKS=$(cat <<'JSON'
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
        "matcher": "Edit|Write|apply_patch",
        "hooks": [
          {
            "type": "command",
            "command": "~/.kodomon/hooks/file-event.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.kodomon/hooks/bash-event.sh"
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
JSON
)

mkdir -p "$CODEX_DIR"
if [ -f "$CODEX_HOOKS" ]; then
    if command -v jq >/dev/null 2>&1; then
        BACKUP="$CODEX_HOOKS.kodomon-backup-$(date +%s)"
        TMP=$(mktemp)
        cp "$CODEX_HOOKS" "$BACKUP"
        if jq '
          def without_kodomon:
            map(select(((.hooks // []) | map(.command // "") | join(" ") | test("kodomon")) | not));
          . // {} |
          .hooks //= {} |
          .hooks.SessionStart = ((.hooks.SessionStart // []) | without_kodomon) |
          .hooks.PostToolUse = ((.hooks.PostToolUse // []) | without_kodomon) |
          .hooks.Stop = ((.hooks.Stop // []) | without_kodomon) |
          .hooks.SessionStart += [{"hooks":[{"type":"command","command":"~/.kodomon/hooks/session-start.sh"}]}] |
          .hooks.PostToolUse += [
            {"matcher":"Edit|Write|apply_patch","hooks":[{"type":"command","command":"~/.kodomon/hooks/file-event.sh"}]},
            {"matcher":"Bash","hooks":[{"type":"command","command":"~/.kodomon/hooks/bash-event.sh"}]}
          ] |
          .hooks.Stop += [{"hooks":[{"type":"command","command":"~/.kodomon/hooks/session-stop.sh"}]}]
        ' "$CODEX_HOOKS" > "$TMP"; then
            mv "$TMP" "$CODEX_HOOKS"
            echo "  ✓ Codex hooks configured"
        else
            rm -f "$TMP"
            echo "  ⚠ Codex hooks merge failed — original hooks.json left at $CODEX_HOOKS"
        fi
    else
        echo "  ⚠ Codex hooks.json exists and jq is not installed."
        echo "    Install jq (brew install jq) and re-run, or merge Kodomon hooks into $CODEX_HOOKS manually."
    fi
else
    echo "$KODOMON_CODEX_HOOKS" > "$CODEX_HOOKS"
    echo "  ✓ Codex hooks configured"
fi

echo ""
echo "Kodomon hooks installed!"
echo "If Codex asks to review hooks, open /hooks and trust the Kodomon commands."
