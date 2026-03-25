#!/usr/bin/env bash
# Dangerous Command Guard (PreToolUse Bash)
# Blocks destructive shell commands that are rarely intentional.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Block patterns
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
  'wget.*[|].*\bsh\b'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: Destructive command detected ('$pattern'). Ask the user for explicit permission before running this." >&2
    exit 2
  fi
done

exit 0
