#!/usr/bin/env bash
# Post-Write Verification Hook (PostToolUse Write|Edit)
# Runs project verify.sh after file edits to catch issues early.
# Never blocks edits -- warnings only.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

# Skip if no file path or if path is under .claude/
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

if [[ "$FILE_PATH" == */.claude/* || "$FILE_PATH" == .claude/* ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
VERIFY="$PROJECT_DIR/verify.sh"

# Run verification if script exists and is executable
if [[ -x "$VERIFY" ]]; then
  if ! timeout 5 "$VERIFY" 2>&1; then
    echo "[verify-post-write] Warning: verify.sh failed or timed out. Review recent changes."
  fi
fi

exit 0
