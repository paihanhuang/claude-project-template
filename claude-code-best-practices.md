# Claude Code Best Practices Summary

> Source: https://code.claude.com/docs/en/best-practices
> Last revised: 2026-04-12
> Reviewed by: Architect, Engineer, QA-Robustness, QA-Quality agents

---

## Core Principle

**Context is your most important resource.** Claude's context window holds your entire conversation, every file read, and every command output. Performance degrades as it fills. Most best practices flow from managing this constraint.

**Architect's framing:** Context behaves like a bounded buffer in a streaming processor. Every file read and command output is an allocation. Budget accordingly — you must process and discard context continuously, not accumulate it.

**Quality note:** Context is non-renewable within a session. There is no "garbage collection." Once consumed, tokens are gone until you `/clear` or `/compact`.

---

## 1. Give Claude a Way to Verify Its Work

The single highest-leverage thing you can do. Claude performs dramatically better when it can check itself.

- **Provide verification criteria** — include test cases, expected outputs, or acceptance criteria in your prompt.
- **Verify UI changes visually** — paste screenshots, ask Claude to take screenshots and compare.
- **Address root causes** — paste the actual error, ask Claude to fix and verify the build succeeds.
- Verification can be a test suite, a linter, a bash command, or the [Claude in Chrome extension](https://code.claude.com/docs/en/chrome) for UI work.

| Before | After |
|--------|-------|
| "add tests for foo.py" | "write a test for foo.py covering the edge case where the user is logged out. avoid mocks." |
| "fix the login bug" | "users report login fails after session timeout. check src/auth/, especially token refresh. write a failing test, then fix it" |

### Multi-Role Insights

- **Engineer:** Verification + knowing common failure patterns (Section 8) = highest ROI combo. No criteria means no confidence.
- **QA-Robustness:** The doc says "provide tests" but doesn't address who validates the tests themselves. Flaky or poorly-scoped tests create a false sense of safety. Always inspect the test logic, not just that tests pass.
- **QA-Quality:** Verification runs consume tokens. Prefer fast, targeted checks (single test file, specific linter rule) over full suite runs to conserve context.

---

## 2. Explore First, Then Plan, Then Code

Separate research and planning from implementation to avoid solving the wrong problem. Use **Plan Mode** (`Shift+Tab` to toggle).

1. **Explore** — enter Plan Mode, read files, ask questions (no changes made).
2. **Plan** — ask Claude to create a detailed implementation plan. Press `Ctrl+G` to edit the plan in your editor.
3. **Implement** — switch to Normal Mode, let Claude code against the plan.
4. **Commit** — ask Claude to commit and open a PR.

**When to skip planning:** If the scope is clear and the fix is small (typo, log line, rename). If you could describe the diff in one sentence, skip the plan.

### Multi-Role Insights

- **Architect:** Plan Mode is sequential and single-threaded. For large features requiring parallel design tracks, there is no guidance on composing or merging plans. The escape hatches (skip for trivial tasks) prevent the rigidity from becoming a bottleneck.
- **Engineer:** The real heuristic — if the change touches more than two files or you're uncertain about approach, plan. Otherwise skip. Most engineers apply planning ceremony uniformly; that's wasteful.
- **QA-Robustness:** The transition from Implement to Commit is underspecified. There's no explicit verification gate between "code is written" and "commit is made." This is where bugs slip through.

---

## 3. Provide Specific Context in Prompts

The more precise your instructions, the fewer corrections needed.

- **Scope the task** — specify files, scenarios, testing preferences.
- **Point to sources** — direct Claude to git history, docs, or specific files.
- **Reference existing patterns** — point to example implementations in your codebase.
- **Describe symptoms** — provide the error, likely location, and what "fixed" looks like.

### Provide Rich Content

- **`@` references** — `@path/to/file` to include file contents.
- **Images** — copy/paste or drag-and-drop screenshots directly.
- **URLs** — give documentation links; use `/permissions` to allowlist domains.
- **Pipe data** — `cat error.log | claude` to send contents directly.
- **Let Claude fetch** — tell it to pull context via Bash, MCP, or file reads.

### Multi-Role Insights

- **Engineer:** Vague prompts are useful when exploring. "What would you improve in this file?" can surface things you wouldn't have asked about. Precision is for execution; openness is for discovery.
- **QA-Quality:** Every `@` reference and piped file costs tokens. Be deliberate — reference only what's needed, not "everything in the directory."

---

## 4. Configure Your Environment

### CLAUDE.md

A special file Claude reads at the start of every conversation. Run `/init` to generate a starter.

**Include:** bash commands Claude can't guess, code style deviations from defaults, testing instructions, repo etiquette, architectural decisions, common gotchas.

**Exclude:** anything Claude can infer from code, standard conventions it already knows, detailed API docs (link instead), info that changes frequently, self-evident practices.

Keep it concise — bloated files cause Claude to ignore your instructions. Treat it like code: review, prune, and test regularly.

**Locations:**
- `~/.claude/CLAUDE.md` — applies globally
- `./CLAUDE.md` — project root, shared via git
- `./CLAUDE.local.md` — personal, gitignored
- Parent/child directories — monorepo and subdirectory support

### Permissions

- **Auto mode** — a classifier reviews commands, blocks risky ones.
- **Allowlists** — `/permissions` to permit specific safe commands.
- **Sandboxing** — `/sandbox` for OS-level isolation.

### CLI Tools

Tell Claude to use CLI tools (`gh`, `aws`, `gcloud`, `sentry-cli`) for context-efficient external service interaction. Claude can also learn new CLIs via `--help`.

### MCP Servers

`claude mcp add` to connect Notion, Figma, databases, etc.

### Hooks

Deterministic scripts that run at specific points in Claude's workflow. Unlike CLAUDE.md (advisory), hooks are guaranteed. Claude can write hooks for you.

### Skills

`.claude/skills/` directories with `SKILL.md` files for domain knowledge and reusable workflows. Loaded on demand, not every session.

### Subagents

`.claude/agents/` with specialized assistants that run in isolated context with scoped tools.

### Plugins

`/plugin` to browse the marketplace for bundled skills, hooks, agents, and MCP servers.

### Multi-Role Insights

- **Architect:** CLAUDE.md is a flat-file monolith. For large teams (20+ engineers), it becomes a merge-conflict magnet. The doc acknowledges hierarchy (home/project/child dirs) but offers no decomposition strategy. Treat it with infrastructure-as-code rigor.
- **Engineer:** CLAUDE.md value is in what you *remove*, not what you add. Skills and subagents are code — they need maintenance ownership or they become misleading noise.
- **QA-Robustness:** CLAUDE.md staleness is a silent failure. If a rule references a deleted file or outdated pattern, Claude follows stale instructions without warning. Schedule periodic reviews.
- **QA-Quality:** CLAUDE.md is a per-session token tax. Every session pays the cost. In fan-out patterns (`claude -p` in a loop), this cost multiplies by the number of invocations. Keep it minimal, especially for automated workflows. Permission model configuration is the dominant DX lever — getting it right eliminates the most interruptions.

---

## 5. Communicate Effectively

### Ask Codebase Questions

Use Claude like a senior engineer: "How does logging work?", "How do I make a new API endpoint?", "Why does this code call foo() instead of bar()?"

### Let Claude Interview You

For larger features, start with a minimal prompt and ask Claude to interview you:

```
I want to build [brief description]. Interview me in detail using the AskUserQuestion tool.
Ask about technical implementation, UI/UX, edge cases, concerns, and tradeoffs.
Keep interviewing until we've covered everything, then write a complete spec to SPEC.md.
```

Then start a fresh session to execute the spec with clean context.

---

## 6. Manage Your Session

### Course-Correct Early

- **`Esc`** — stop Claude mid-action, context preserved.
- **`Esc + Esc`** or **`/rewind`** — restore previous conversation and code state.
- **"Undo that"** — have Claude revert changes.
- **`/clear`** — reset context between unrelated tasks.

If you've corrected Claude 2+ times on the same issue, `/clear` and start fresh with a better prompt.

### Manage Context Aggressively

- `/clear` frequently between tasks.
- `/compact <instructions>` for controlled summarization (e.g., `/compact Focus on the API changes`).
- `/rewind` > "Summarize from here" to condense part of the conversation.
- `/btw` for quick questions that don't enter conversation history.
- Add compaction instructions to CLAUDE.md (e.g., "When compacting, preserve the full list of modified files").

### Use Subagents for Investigation

Delegate research to subagents — they explore in separate context windows and report back summaries, keeping your main conversation clean.

```
Use subagents to investigate how our auth system handles token refresh,
and whether we have any existing OAuth utilities I should reuse.
```

### Rewind with Checkpoints

Every Claude action creates a checkpoint. Double-tap `Esc` or `/rewind` to restore conversation, code, or both. Checkpoints persist across sessions.

### Resume Conversations

- `claude --continue` — resume most recent conversation.
- `claude --resume` — select from recent sessions.
- `/rename` — give sessions descriptive names for later retrieval.

### Multi-Role Insights

- **Architect:** The doc treats sessions as isolated, but real projects have cross-session state (partial implementations, design decisions, discovered constraints). No guidance on persistence or handoff — architect your own continuity layer.
- **Engineer:** After 2 failed corrections, the problem is the *prompt*, not the response. Accumulated bad context compounds; it doesn't cancel.
- **QA-Robustness:** Checkpoints only track changes made by Claude, not external processes. This creates a gap where external state changes (database migrations, dependency updates) can make a checkpoint restoration inconsistent.

---

## 7. Automate and Scale

### Non-Interactive Mode

```bash
claude -p "prompt"                              # One-off query
claude -p "prompt" --output-format json          # Structured output
claude -p "prompt" --output-format stream-json   # Streaming
```

### Parallel Sessions

- **Desktop app** — multiple local sessions with isolated worktrees.
- **Web** — cloud infrastructure in isolated VMs.
- **Agent teams** — automated coordination with shared tasks and messaging.

**Writer/Reviewer pattern:** One session implements, another reviews with fresh context.

### Fan Out Across Files

```bash
for file in $(cat files.txt); do
  claude -p "Migrate $file from React to Vue. Return OK or FAIL." \
    --allowedTools "Edit,Bash(git commit *)"
done
```

### Auto Mode for Autonomous Runs

```bash
claude --permission-mode auto -p "fix all lint errors"
```

### Multi-Role Insights

- **Architect:** Horizontal scaling (parallel sessions) beats vertical scaling (longer context). Each session is stateless and independent, avoiding coordination overhead. But divergent parallel sessions have no merge/reconciliation pattern.
- **Engineer:** The Writer/Reviewer pattern is the most underrated practice. A separate review session forces an independent code read, not a continuation of the writing session's assumptions. Non-interactive runs need well-scoped, deterministic prompts — vague prompts in CI produce non-deterministic results.
- **QA-Robustness:** Fan-out automation has no built-in partial failure handling. If 3 out of 200 files fail, there's no retry/resume mechanism described. Corrupted intermediate state from partial failures can go undetected.
- **QA-Quality:** Fan-out multiplies CLAUDE.md token cost per invocation. At 200 parallel runs, even a modest CLAUDE.md becomes a significant cost multiplier. Factor in per-spawn startup overhead when estimating automation costs.

---

## 8. Common Failure Patterns to Avoid

| Pattern | Symptom | Fix |
|---------|---------|-----|
| **Kitchen sink session** | Context full of unrelated tasks | `/clear` between unrelated tasks |
| **Correction spiral** | 2+ failed corrections, polluted context | `/clear`, write a better initial prompt |
| **Over-specified CLAUDE.md** | Claude ignores rules | Ruthlessly prune; convert to hooks if needed |
| **Trust-then-verify gap** | Plausible code that misses edge cases | Always provide verification criteria |
| **Infinite exploration** | Unscoped "investigate" fills context | Scope narrowly or use subagents |

### Additional Failure Modes (from agent analysis)

| Pattern | Source | Description |
|---------|--------|-------------|
| **Stale CLAUDE.md** | QA-Robustness | Rules reference deleted files or outdated patterns; Claude follows silently |
| **Unmaintained skills/agents** | Engineer | `.claude/skills/` and `.claude/agents/` drift from codebase reality; become misleading context |
| **Fan-out partial failure** | QA-Robustness | Some iterations fail silently in batch automation; no built-in detection |
| **Hidden cost multiplication** | QA-Quality | CLAUDE.md token cost multiplied across parallel/fan-out invocations |
| **Checkpoint-external state mismatch** | QA-Robustness | Restoring a checkpoint after external changes (DB, deps) creates inconsistency |

---

## 9. Develop Your Intuition

These are starting points, not rigid rules. Pay attention to what works:

- When Claude produces great output, notice the prompt structure, context, and mode.
- When Claude struggles, ask: was the context too noisy? The prompt too vague? The task too big?
- Sometimes accumulated context is valuable. Sometimes a vague prompt is exactly right.
- Over time, you'll know when to be specific vs. open-ended, when to plan vs. explore, when to clear vs. accumulate.

---

## Cross-Role Key Takeaways

### Architect

1. Context is memory — manage it like a system resource with explicit lifecycle management.
2. Isolation (subagents, `/clear`, separate sessions) is the primary scaling mechanism.
3. Verification is load-bearing infrastructure, not optional polish.
4. CLAUDE.md is system configuration — version it, review it, prune it with infra-as-code rigor.
5. Horizontal scaling (parallel sessions) beats vertical scaling (longer context).
6. The doc is silent on cross-session state management — architect your own persistence layer.

### Engineer

1. Verification criteria before starting is the single highest-leverage practice.
2. Context is a resource. Treat `/clear` like freeing memory, not losing work.
3. CLAUDE.md value is in what you remove, not what you add. Prune ruthlessly.
4. Plan only when uncertain about approach or scope crosses two or more files.
5. Writer/Reviewer split across sessions gives you an independent review, not a self-review.
6. Skills and subagents are code. They need maintenance ownership or they become noise.
7. After two failed corrections, the problem is the prompt, not the response.

### QA-Robustness

1. The doc optimizes for happy-path adoption; highest-risk gaps are in phase transitions and automation.
2. "Tests pass" is not sufficient verification — inspect that tests actually cover the right conditions.
3. CLAUDE.md staleness is a silent failure mode with no built-in detection.
4. Fan-out automation needs explicit partial-failure handling and intermediate state validation.
5. Checkpoint restoration can create inconsistencies with external state changes.
6. The Implement-to-Commit transition lacks an explicit verification gate.

### QA-Quality

1. Context window is a non-renewable resource — every token matters, budget deliberately.
2. CLAUDE.md is a per-session token tax that multiplies across fan-out invocations.
3. Subagent isolation is the highest-ROI pattern for preserving context efficiency.
4. Permission model configuration is the dominant DX lever — reduces interruption frequency the most.
5. Hidden cost multipliers (fan-out x CLAUDE.md size, per-spawn overhead) are not addressed in the doc.
6. Prefer targeted verification (single test, specific linter rule) over full-suite runs for context efficiency.
