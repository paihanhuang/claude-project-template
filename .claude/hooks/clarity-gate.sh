#!/usr/bin/env bash
# Clarity Gate Hook (UserPromptSubmit)
# Injects a reminder for non-trivial prompts to ensure the orchestrator
# runs the Clarity Gate before spawning agents.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Skip trivial prompts (very short)
if [[ ${#PROMPT} -lt 50 ]]; then
  exit 0
fi

# Skip approval/confirmation responses (only if reasonably short,
# so "Yes, build an entire auth system" still gets gated)
if [[ ${#PROMPT} -lt 80 ]] && echo "$PROMPT" | grep -iqE '^(yes|no|y|n|ok|approved|approve|reject|looks good|lgtm|go ahead|proceed)'; then
  exit 0
fi

# For non-trivial prompts, inject Clarity Gate reminder
cat <<'EOF'
CLARITY GATE REMINDER: Before spawning any agents, evaluate this request:
- If ambiguous: ask 1-3 clarifying questions and STOP.
- If underspecified: list assumptions and get confirmation.
- If clear: state key assumptions and proceed.
Do NOT skip this step. Check if context indexing is needed (Phase 0.5).
EOF

exit 0
