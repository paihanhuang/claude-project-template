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

## QA-Robustness -- Review Mode

- **Mode:** `You are in REVIEW MODE.`
- **Design Under Review:** {Architect's design proposal -- verbatim, not summarized}
- **Focus:** Testability gaps, missing acceptance criteria, edge cases, failure modes, input handling gaps, order-of-operations vulnerabilities, regression risks from feature interactions.
- **Boundary Crossing:** If you find efficiency/performance/UX issues, report them tagged with `[out-of-scope: quality]`.
- **Deliverable:** Robustness review per output format.

## QA-Quality -- Review Mode

- **Mode:** `You are in REVIEW MODE.`
- **Design Under Review:** {Architect's design proposal -- verbatim, not summarized}
- **Focus:** Performance risks, resource usage concerns, UX degradation paths, efficiency gaps, quality regression risks from feature interactions.
- **Boundary Crossing:** If you find functional correctness/edge case/failure mode issues, report them tagged with `[out-of-scope: robustness]`.
- **Deliverable:** Quality review per output format.

## QA-Robustness -- Verification Mode

- **Mode:** `You are in VERIFICATION MODE.`
- **Approved Plan:** {full content of .claude/plans/current.md -- verbatim}
- **Current Stage:** Stage {N}: {stage title} / Robustness Acceptance Criteria: {list from plan}
- **Implementation Diff:** {git diff or file changes from Engineer's implementation}
- **Boundary Crossing:** If you find efficiency/performance/UX issues, report them tagged with `[out-of-scope: quality]`.
- **Deliverable:** Verify this stage against robustness acceptance criteria.

## QA-Quality -- Verification Mode

- **Mode:** `You are in VERIFICATION MODE.`
- **Approved Plan:** {full content of .claude/plans/current.md -- verbatim}
- **Current Stage:** Stage {N}: {stage title} / Quality Acceptance Criteria: {list from plan}
- **Implementation Diff:** {git diff or file changes from Engineer's implementation}
- **Boundary Crossing:** If you find functional correctness/edge case/failure mode issues, report them tagged with `[out-of-scope: robustness]`.
- **Deliverable:** Verify this stage against quality acceptance criteria.

## Engineer -- Infrastructure Review Mode

- **Mode:** `You are in REVIEW MODE (Infrastructure).`
- **Analysis Under Review:** {Orchestrator's analysis -- verbatim, not summarized}
- **Scope:** {area being reviewed: hooks, agents, settings, workflow, etc.}
- **Focus:** Missed maintainability risks, implementation gaps, efficiency concerns, practical issues overlooked.
- **Deliverable:** Engineering review per output format.

## QA-Robustness -- Infrastructure Review Mode

- **Mode:** `You are in REVIEW MODE (Infrastructure).`
- **Analysis Under Review:** {Orchestrator's analysis -- verbatim, not summarized}
- **Scope:** {area being reviewed: hooks, agents, settings, workflow, etc.}
- **Focus:** Missed failure modes, edge cases in workflow enforcement, robustness gaps, silent bypass scenarios.
- **Boundary Crossing:** If you find efficiency/performance/UX issues, report them tagged with `[out-of-scope: quality]`.
- **Deliverable:** QA robustness review per output format.

Note: QA-Quality does not participate in infrastructure reviews (no meaningful UX/performance surface). Only QA-Robustness is spawned for infrastructure review cross-critique.
