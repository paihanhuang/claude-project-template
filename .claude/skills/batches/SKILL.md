---
name: batches
description: Guidance for using Message Batches API (50% cost savings) for non-urgent parallel tasks
---

# Message Batches (50% Cost Savings)

For non-urgent tasks that can wait up to 1 hour, use the `claude-mcp:submit_batch` MCP tool instead of processing inline. This routes work through the Anthropic Message Batches API at 50% reduced cost.

**When to use batches:**
- Cross-critique phase (Engineer + QA reviewing a design)
- QA verification of multiple acceptance criteria
- Documentation generation or review
- Any parallel, independent subtasks that don't block the current conversation

**When NOT to use batches:**
- Tasks requiring immediate response
- Interactive/iterative work (debugging, live coding)
- Tasks that depend on each other sequentially

**Workflow:** `claude-mcp:submit_batch(tasks)` -> work on other things -> `claude-mcp:check_batch(id)` -> `claude-mcp:get_batch_results(id)`
