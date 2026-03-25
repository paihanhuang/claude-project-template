#!/usr/bin/env bash
# Save Session State (SessionEnd)
# Captures deterministic workflow state to disk so the next session
# can resume without requiring claude --continue.

P="${CLAUDE_PROJECT_DIR:-.}/.claude/plans"
STATE_FILE="$P/session-state.md"

# Only save if there's an active plan
if [[ ! -f "$P/current.md" ]]; then
  # No active plan — clean up stale state file if it exists
  rm -f "$STATE_FILE"
  exit 0
fi

# Capture state
APPROVED="no"
[[ -f "$P/.approved" ]] && APPROVED="yes"

STAGE="none"
[[ -f "$P/.stage" ]] && STAGE=$(cat "$P/.stage")

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

RECENT_COMMITS=$(git -C "${CLAUDE_PROJECT_DIR:-.}" log --oneline -5 2>/dev/null || echo "no git history")

UNCOMMITTED=$(git -C "${CLAUDE_PROJECT_DIR:-.}" diff --stat 2>/dev/null || echo "unknown")

cat > "$STATE_FILE" <<EOF
# Session State
Saved: $TIMESTAMP

## Workflow Status
- Plan approved: $APPROVED
- Stage progress: $STAGE
- Plan file: .claude/plans/current.md

## Recent Commits
$RECENT_COMMITS

## Uncommitted Changes
$UNCOMMITTED

## Resume Instructions
1. Read .claude/plans/current.md for the full plan
2. If approved=yes, resume Phase 2&3 at stage $STAGE
3. If approved=no, resume Phase 1 (Design) — plan may need user approval
4. Check agent memory for lessons from prior work
EOF

exit 0
