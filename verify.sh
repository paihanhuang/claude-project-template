#!/usr/bin/env bash
# Project verification script. Customize for your project.
# Called by .claude/hooks/verify-post-write.sh after file edits.
# Should complete in <2s to avoid slowing the editing workflow.
# Exit 0 = pass, non-zero = warning (does not block edits).
echo "No verification configured. Edit verify.sh to add linting, type-checking, or tests."
exit 0
