---
name: reset
description: Clear all transient workflow state and start fresh
disable-model-invocation: true
---

Clear all transient workflow state so the next task starts from a clean slate.

Delete the following files if they exist:
- `.claude/plans/session-state.md` (saved session state)
- `.claude/plans/current.md` (active plan)
- `.claude/plans/.approved` (approval marker)
- `.claude/plans/.stage` (stage progress)
- `.claude/index/*` (context index cache)

After clearing, confirm to the user what was removed and that the workspace is ready for a new task.

Do NOT delete:
- Agent definitions (`.claude/agents/`)
- Agent memory (`.claude/agent-memory/`) — lessons persist across tasks
- Hooks, rules, docs, settings, or any template infrastructure
