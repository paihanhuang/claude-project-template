#!/usr/bin/env bash
# guard-bash.sh - Bash PreToolUse guard (merged)
#
# Combines:
#   1. Dangerous command blocking
#   2. Heredoc + inline-interpreter detection
#   3. File-write approval gate (mirrors check-approval.sh policy for Bash path)
#
# Policy: allow-on-ambiguity -- only blocks clear, unquoted write patterns.
#
# Known accepted bypasses (by design):
#   - eval / bash -c wrapping
#   - sudo prefix before write commands
#   - Variable expansion in paths ($VAR/file)
#   - Quoted strings containing write operators

set -euo pipefail

# --- M4: jq existence check (fail-closed) ---
if ! command -v jq &>/dev/null; then
  echo "[guard-bash] ERROR: jq is not available. Cannot parse tool input -- blocking command to fail closed. Install jq to allow Bash hook enforcement." >&2
  exit 2
fi

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# --- Resolve project dirs ---
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "[guard-bash] WARNING: CLAUDE_PROJECT_DIR is not set, falling back to $(pwd)" >&2
  CLAUDE_PROJECT_DIR="$(pwd)"
fi

CLAUDE_DIR="$CLAUDE_PROJECT_DIR/.claude"
APPROVED="$CLAUDE_PROJECT_DIR/.claude/plans/.approved"

# ---------------------------------------------------------------------------
# SECTION 1: Dangerous command guard
# ---------------------------------------------------------------------------
BLOCKED_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.'
  'rm -rf \*'
  'git push --force'
  'git push -f'
  'git reset --hard'
  'git clean -fd'
  'git checkout -- \.'
  'git restore \.'
  'git branch -D'
  'mkfs\.'
  'dd if='
  '> /dev/sd'
  'chmod -R 777'
  ':(){:|:&};:'
  'sudo rm'
  'curl.*[|].*\bsh\b'
  'wget.*[|].*\bsh\b')

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "[guard-bash] BLOCKED: Destructive command detected ('$pattern'). Ask the user for explicit permission before running this." >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# SECTION 2: Inline interpreter warning (H1)
# Detect python3 -c / python -c / perl -e / ruby -e / node -e patterns.
# These may contain inline write operations we cannot parse safely.
# Warn only -- do NOT block (too many false positives).
# ---------------------------------------------------------------------------
if echo "$COMMAND" | grep -qP '\b(python3?|perl|ruby|node)\s+-[ceE]\s'; then
  echo "[guard-bash] WARNING: Command contains an inline interpreter (-c/-e flag) that may write files. Review it carefully before allowing." >&2
fi

# ---------------------------------------------------------------------------
# SECTION 3: File-write approval gate
# ---------------------------------------------------------------------------

# check_target: resolve a path and decide whether to allow or block.
# Mirrors check-approval.sh policy for the Bash execution path.
check_target() {
  local target="$1"

  # Skip empty targets or targets with variable/backtick expansion (ambiguity -> allow)
  if [[ -z "$target" || "$target" == *'$'* || "$target" == *'`'* ]]; then
    return 0
  fi

  local abs_path
  abs_path=$(realpath -m "$target" 2>/dev/null || echo "$target")

  # --- C1: Block writes to gate artifacts (orchestrator-only) ---
  if [[ "$abs_path" == "$CLAUDE_DIR/plans/.approved" || "$abs_path" == "$CLAUDE_DIR/plans/.stage" ]]; then
    echo "[guard-bash] BLOCKED: Bash command writes to gate artifact '$target'. Gate markers (.approved, .stage) must only be created by the orchestrator." >&2
    exit 2
  fi

  # Allow writes within .claude/ working directories
  if [[ "$abs_path" == "$CLAUDE_DIR"* ]]; then
    return 0
  fi

  # --- M1: Allow .md files outside source directories ---
  if [[ "$abs_path" == *.md ]]; then
    SOURCE_DIRS=(
      "${CLAUDE_PROJECT_DIR}/src/"
      "${CLAUDE_PROJECT_DIR}/lib/"
      "${CLAUDE_PROJECT_DIR}/app/"
    )
    local is_source_adjacent=false
    for dir in "${SOURCE_DIRS[@]}"; do
      if [[ "$abs_path" == "$dir"* ]]; then
        is_source_adjacent=true
        break
      fi
    done
    if [[ "$is_source_adjacent" == false ]]; then
      return 0
    fi
  fi

  # Block project files unless approved plan exists
  if [[ -f "$APPROVED" ]]; then
    return 0
  fi

  echo "[guard-bash] BLOCKED: Bash command writes to '$target' but no approved plan exists. Complete V-Model Phase 1 (Design) and get user approval first." >&2
  exit 2
}

# ---------------------------------------------------------------------------
# SECTION 4: Write-target extraction
# ---------------------------------------------------------------------------

# --- H1: Heredoc with write operator detection ---
# Scan for: <<WORD > dest  and  <<WORD >> dest  forms.
while IFS= read -r heredoc_target; do
  check_target "$heredoc_target"
done < <(echo "$COMMAND" | grep -oP '<<\s*['"'"'"]?\w+['"'"'"]?[^>]*>>?\s*\K[^\s;|&]+' 2>/dev/null || true)

# --- Redirection: > and >> ---
# Two-pass: strip quoted regions first to avoid false positives on: echo "text > here"
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
