#!/usr/bin/env bash
# Approval Gate + Protected File Guard (PreToolUse Write|Edit)
#
# 1. Blocks edits to template infrastructure files (agents, hooks, rules, docs)
# 2. Allows writes to .claude/ working directories (plans, index, agent-memory)
# 3. Blocks writes to project files unless an approved plan exists

set -euo pipefail

# Guard: warn if CLAUDE_PROJECT_DIR is unset, fall back to $(pwd)
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "[check-approval] WARNING: CLAUDE_PROJECT_DIR is not set, falling back to \$(pwd)" >&2
  CLAUDE_PROJECT_DIR="$(pwd)"
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# If no file path extracted, allow (non-file tool call)
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Resolve to absolute path for comparison
ABS_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
CLAUDE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude"

# --- Protected file guard ---
# Block edits to template infrastructure (agents, hooks, rules, docs)
PROTECTED_PATTERNS=(
  "$CLAUDE_DIR/agents/"
  "$CLAUDE_DIR/hooks/"
  "$CLAUDE_DIR/rules/"
  "$CLAUDE_DIR/docs/"
  "$CLAUDE_DIR/settings.json"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$ABS_PATH" == "$pattern"* || "$ABS_PATH" == "$pattern" ]]; then
    echo "BLOCKED: $FILE_PATH is a protected template file. These define the workflow infrastructure and must not be modified during normal operation. Edit manually if changes are needed." >&2
    exit 2
  fi
done

# --- Allow .claude/ working directories ---
# Plans, index, agent-memory, skills are writable
if [[ "$ABS_PATH" == "$CLAUDE_DIR"* ]]; then
  exit 0
fi

# --- Approval gate ---
# Project files require an approved plan
if [[ -f "${CLAUDE_PROJECT_DIR:-.}/.claude/plans/.approved" ]]; then
  exit 0
fi

echo "BLOCKED: No approved implementation plan. Complete V-Model Phase 1 (Design) and get user approval before writing code." >&2
exit 2
