#!/usr/bin/env bash
# Save Compact State (PreCompact)
# Injects V-Model state preservation message before context compaction.

P="${CLAUDE_PROJECT_DIR:-.}/.claude/plans"

[[ -f "$P/current.md" ]] || exit 0

APPROVED="NO (design phase)"
[[ -f "$P/.approved" ]] && APPROVED="YES (implementation phase)"

STAGE="none"
[[ -f "$P/.stage" ]] && STAGE=$(cat "$P/.stage")

cat <<EOF
V-MODEL STATE PRESERVATION:
- Active plan: .claude/plans/current.md
- Approval: $APPROVED
- Stage progress: $STAGE
After compaction, read these files to resume the workflow.
EOF

exit 0
