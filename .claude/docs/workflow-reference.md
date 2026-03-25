# Workflow Reference

Detailed step-by-step instructions for each phase of the V-Model workflow.

For standardized agent invocation templates, see [prompt-templates.md](prompt-templates.md).

---

## Phase 0.5: Context Indexing

Before spawning any agents, determine whether the task involves scanning a large codebase or many input documents. If so, create structured index files to prevent redundant scanning across agent spawns.

**When to index:**
- The task references more than ~10 files or multiple modules
- External documents (specs, requirements, RFCs) are provided as input
- The codebase is unfamiliar (first task in a new project)

**When to skip:**
- The task is scoped to 1-3 known files
- Index files already exist and sources have not been modified since indexing

**Process:**
1. Identify the relevant scope (modules, documents, areas of the codebase)
2. Scan source files and documents
3. Write structured index files to `.claude/index/`
4. One file per logical area (e.g., `auth-module.md`, `api-endpoints.md`, `requirements.md`)

**Index file format:**
```markdown
---
source: [file/path/a.py, file/path/b.py, docs/spec.md]
indexed: {ISO date}
scope: {what area/module this covers}
---

{Structured summary: key interfaces, public APIs, data flow, dependencies, constraints.
 Include only information agents need to make decisions — not full file contents.}
```

**Staleness protocol:**
Before using any index file, compare its `indexed` date against the modification times of files in its `source` list. If any source file is newer than the index, re-scan and update before passing to agents.

---

## Review Flow

Used for infrastructure reviews, setup audits, and configuration critique. Lighter than the full Phase 1 pipeline -- no architect design proposal, no approval gate for the review itself.

**When to use:**
- User asks to evaluate, audit, or revise hooks, agents, settings, or workflow config
- User asks for second opinions on infrastructure changes
- Any "what should change?" request about the template itself

**Process:**

**Step 1 -- Orchestrator analysis.**
Scan relevant files and produce an initial assessment with findings and recommendations organized by severity.

**Step 2 -- Cross-critique.**
Spawn `engineer` and `qa` agents **in parallel** (review mode).
- Pass the orchestrator's analysis **verbatim** -- do not summarize.
- Engineer evaluates for: maintainability risks, implementation gaps, efficiency concerns.
- QA evaluates for: failure modes, edge cases, robustness gaps, silent bypass scenarios.
- Verify `## Memory Entry` blocks exist -- if missing, reject and re-spawn.
- Write memory entries to each agent's memory.

**Step 3 -- Synthesis.**
Merge orchestrator findings with agent critiques:
- For each finding: note agreement or disagreement across perspectives.
- Flag anything an agent caught that the orchestrator missed.
- Produce consolidated, prioritized recommendations.

**Step 4 -- Present to user.**
User approves which recommendations to implement. Implementation of approved changes follows normal workflow (Phase 1 if non-trivial, direct edit if trivial and explicitly approved).

---

## Phase 1: Design (Detailed Steps)

**Step 1 — Architect designs.**
Spawn `architect` agent with the user request and relevant codebase context (or index files).
- Prompt must specify: **design mode**
- Receive design proposal. Verify `## Memory Entry` block exists — if missing, reject and re-spawn.
- Write the memory entry to the architect's agent memory.

**Step 2 — Engineer + QA cross-critique.**
Spawn `engineer` and `qa` agents **in parallel** with the Architect's design proposal.
- Prompt must specify: **review mode** (no code, critique only)
- Pass the Architect's design proposal **verbatim** — do not summarize.
- Receive critiques. Verify `## Memory Entry` blocks exist — if missing, reject and re-spawn.
- Write memory entries to each agent's memory.

**Step 3 — Orchestrator synthesizes.**
Review all three agent outputs. For each critique point:
- If valid: incorporate into the design
- If invalid: dismiss with explicit reasoning

Produce a **Final Proposal** containing:
- Problem Restatement
- Assumptions & Constraints
- Architecture Design (component boundaries, interfaces, data flow)
- Technical Stack (with rationale)
- Stage-Based Implementation Plan
- QA Plan (acceptance criteria per stage)
- Rationale behind key design decisions
- Addressed Critiques (what was raised, what was changed or dismissed, and why)

**Step 4 — User approval gate.**
- Write Final Proposal to `.claude/plans/current.md`
- Present the proposal to the user
- **WAIT for explicit approval.** Do not proceed without it.
- On approval: create `.claude/plans/.approved` marker file

---

## Phase 2 & 3: Stage-Based Implementation and Verification (Detailed Steps)

Prerequisite: `.claude/plans/.approved` must exist.

The approved plan contains a Stage-Based Implementation Plan. Execute each stage sequentially, with verification after every stage. Do not begin stage N+1 until stage N passes verification.

**For each stage in the plan, repeat:**

**Step 1 — Engineer implements the stage.**
Spawn `engineer` agent with:
- The approved plan from `.claude/plans/current.md`
- The **current stage number and scope** (what to implement in this stage only)
- Relevant codebase context (file contents, existing patterns, prior stage outputs, or index files)
- Prompt must specify: **implementation mode**

**Step 2 — Orchestrator reviews the stage.**
- Verify `## Memory Entry` block exists — if missing, reject and re-spawn.
- Write memory entry to the engineer's agent memory.
- Review implementation against the stage's scope in the approved plan.
- If non-compliant: re-spawn engineer with specific feedback on what deviates.

**Step 3 — QA verifies the stage.**
Spawn `qa` agent with:
- The approved plan from `.claude/plans/current.md`
- The **current stage number and its acceptance criteria**
- The implementation diff for this stage
- Prompt must specify: **verification mode**

**Step 4 — Orchestrator processes stage results.**
- Verify `## Memory Entry` block exists — if missing, reject and re-spawn.
- Write memory entry to the qa's agent memory.
- If verdict is **pass**: proceed to next stage.
- If verdict is **fail**: spawn engineer to fix identified issues, then re-spawn qa to verify. Loop until pass.

**Step 5 — Orchestrator refreshes context indexes.**
Before starting the next stage, check if any index files in `.claude/index/` are stale (source files modified by the current stage's implementation). Re-index affected areas before proceeding.

**After all stages pass:** remove `.claude/plans/.approved` marker. Task is complete.
