# Agent Prompt Templates

All templates end with: `Include the ## Memory Entry block.`

## Architect -- Design Mode

- **Mode:** `You are in DESIGN MODE.`
- **Task:** {user request, paraphrased with clarified scope}
- **Context:** {relevant index files or codebase context -- verbatim, not summarized}
- **Constraints:** {from Clarity Gate} + {technology or architecture constraints}
- **Deliverable:** Design proposal per output format.

## Architect -- Review Mode

- **Mode:** `You are in REVIEW MODE.`
- **Design Under Review:** {Architect's design proposal -- verbatim, not summarized}
- **Focus:** Scalability risks, flexibility gaps, over-engineering.
- **Deliverable:** Architecture review per output format.

## Engineer -- Review Mode

- **Mode:** `You are in REVIEW MODE.`
- **Design Under Review:** {Architect's design proposal -- verbatim, not summarized}
- **Focus:** Implementation feasibility, maintainability risks, performance concerns, missing edge cases.
- **Deliverable:** Engineering review per output format.

## Engineer -- Implementation Mode

- **Mode:** `You are in IMPLEMENTATION MODE.`
- **Approved Plan:** {full content of .claude/plans/current.md -- verbatim}
- **Current Stage:** Stage {N}: {stage title} / Scope: {what to implement in this stage only}
- **Codebase Context:** {relevant index files or file contents for this stage}
- **Prior Stage Output:** {summary of what was implemented in previous stages, if any}
- **Deliverable:** Implement this stage exactly per the plan. No deviations.

## QA -- Review Mode

- **Mode:** `You are in REVIEW MODE.`
- **Design Under Review:** {Architect's design proposal -- verbatim, not summarized}
- **Focus:** Testability gaps, missing acceptance criteria, edge cases, failure modes.
- **Deliverable:** QA review per output format.

## QA -- Verification Mode

- **Mode:** `You are in VERIFICATION MODE.`
- **Approved Plan:** {full content of .claude/plans/current.md -- verbatim}
- **Current Stage:** Stage {N}: {stage title} / Acceptance Criteria: {list from plan}
- **Implementation Diff:** {git diff or file changes from Engineer's implementation}
- **Deliverable:** Verify this stage against acceptance criteria.

## Engineer -- Infrastructure Review Mode

- **Mode:** `You are in REVIEW MODE (Infrastructure).`
- **Analysis Under Review:** {Orchestrator's analysis -- verbatim, not summarized}
- **Scope:** {area being reviewed: hooks, agents, settings, workflow, etc.}
- **Focus:** Missed maintainability risks, implementation gaps, efficiency concerns, practical issues overlooked.
- **Deliverable:** Engineering review per output format.

## QA -- Infrastructure Review Mode

- **Mode:** `You are in REVIEW MODE (Infrastructure).`
- **Analysis Under Review:** {Orchestrator's analysis -- verbatim, not summarized}
- **Scope:** {area being reviewed: hooks, agents, settings, workflow, etc.}
- **Focus:** Missed failure modes, edge cases in workflow enforcement, robustness gaps, silent bypass scenarios.
- **Deliverable:** QA review per output format.
