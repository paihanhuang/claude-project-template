#!/usr/bin/env bash
# Load Session State (SessionStart)
# Injects saved workflow state into the new session context.

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/plans/session-state.md"

if [[ -f "$STATE_FILE" ]]; then
  echo "PRIOR SESSION STATE DETECTED — read this before proceeding:"
  echo ""
  cat "$STATE_FILE"
  echo ""
  echo "Ask the user if they want to resume this work or start fresh."
fi

exit 0
