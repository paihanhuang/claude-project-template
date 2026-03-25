#!/usr/bin/env bash
# Notification Hook (Notification)
# Sends desktop notification when Claude Code completes a task.
# Exits 0 silently if no display server or unknown platform.

set -euo pipefail

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Task complete"' 2>/dev/null || echo "Task complete")

case "$(uname -s)" in
  Linux)
    if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
      notify-send "Claude Code" "$MESSAGE" 2>/dev/null || true
    fi
    ;;
  Darwin)
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\"" 2>/dev/null || true
    ;;
esac

exit 0
