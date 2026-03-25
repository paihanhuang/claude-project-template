#!/usr/bin/env bash
# Approval Gate for Bash Commands (PreToolUse Bash)
#
# Detects file-write patterns in shell commands and enforces the approval gate.
# Policy: allow-on-ambiguity -- only blocks clear, unquoted write patterns.
#
# Known accepted bypasses (by design):
#   - eval / bash -c wrapping
#   - sudo prefix before write commands
#   - Variable expansion in paths ($VAR/file)
#   - Python/Ruby/Perl inline scripts (-c "...")
#   - Quoted strings containing write operators

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Resolve CLAUDE_PROJECT_DIR with fallback
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "[check-approval-bash] WARNING: CLAUDE_PROJECT_DIR is not set, falling back to \$(pwd)" >&2
  CLAUDE_PROJECT_DIR="$(pwd)"
fi

CLAUDE_DIR="$CLAUDE_PROJECT_DIR/.claude"
APPROVED="$CLAUDE_PROJECT_DIR/.claude/plans/.approved"

# check_target: resolve a path and decide whether to allow or block.
# Allows .claude/ paths. Blocks project files unless .approved exists.
check_target() {
  local target="$1"

  # Skip empty targets or targets with variable expansion (ambiguity -> allow)
  if [[ -z "$target" || "$target" == *'$'* || "$target" == *'`'* ]]; then
    return 0
  fi

  local abs_path
  abs_path=$(realpath -m "$target" 2>/dev/null || echo "$target")

  # Allow writes to .claude/ working directories
  if [[ "$abs_path" == "$CLAUDE_DIR"* ]]; then
    return 0
  fi

  # Block project files unless approved plan exists
  if [[ -f "$APPROVED" ]]; then
    return 0
  fi

  echo "[check-approval-bash] BLOCKED: Bash command writes to '$target' but no approved plan exists. Complete V-Model Phase 1 (Design) and get user approval first." >&2
  exit 2
}

# Extract write targets from the command.
# Each pattern extracts the destination path from unquoted, clear write operations.

# --- Redirection: > and >> ---
# Two-pass: strip quoted regions first, then scan for redirects.
# This avoids false positives on `echo "text > here"`.
STRIPPED_CMD=$(echo "$COMMAND" | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g')
while IFS= read -r redir_target; do
  check_target "$redir_target"
done < <(echo "$STRIPPED_CMD" | grep -oP '>>?\s*\K[^\s;|&]+' 2>/dev/null || true)

# --- tee ---
while IFS= read -r tee_target; do
  check_target "$tee_target"
done < <(echo "$COMMAND" | grep -oP '\btee\s+(?:-a\s+)?(?:-\w+\s+)*\K[^\s;|&]+' 2>/dev/null || true)

# --- cp and mv (last argument is destination) ---
while IFS= read -r cp_mv_match; do
  # Extract last argument as target
  target=$(echo "$cp_mv_match" | awk '{print $NF}')
  check_target "$target"
done < <(echo "$COMMAND" | grep -oP '\b(?:cp|mv)\s+(?:-\w+\s+)*\K[^\s;|&]+(?:\s+[^\s;|&]+)+' 2>/dev/null || true)

# --- install (last argument is destination) ---
while IFS= read -r install_match; do
  target=$(echo "$install_match" | awk '{print $NF}')
  check_target "$target"
done < <(echo "$COMMAND" | grep -oP '\binstall\s+(?:-\w+\s+)*\K[^\s;|&]+(?:\s+[^\s;|&]+)+' 2>/dev/null || true)

# --- dd of=<path> ---
while IFS= read -r dd_target; do
  check_target "$dd_target"
done < <(echo "$COMMAND" | grep -oP '\bdd\b.*\bof=\K[^\s;|&]+' 2>/dev/null || true)

exit 0
