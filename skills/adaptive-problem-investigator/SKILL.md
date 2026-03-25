---
name: adaptive-problem-investigator
description: Investigate and solve complex technical problems using iterative root-cause analysis, precise web research, hypothesis testing, and implementation validation. Use when requests involve unknown causes, regressions, architecture decisions, UI/UX defects, performance issues, integration failures, or feature implementation that needs high-confidence research before coding.
---

# Adaptive Problem Investigator

## Overview

Use this skill to move from unclear symptoms to a validated solution with minimal guesswork.
Prioritize: isolate -> hypothesize -> research -> test -> implement -> verify.

## Workflow

### 1) Frame The Problem

Define a concrete target before researching:

- Current behavior (what is happening).
- Expected behavior (what should happen).
- Scope boundaries (what is in/out for this turn).
- Environment facts (OS, runtime, library versions, build mode).

Ask only high-impact clarifying questions if local exploration cannot answer them.

### 2) Isolate The Smallest Repro

- Identify the exact layer of failure (UI, app logic, bridge, OS API, infra).
- Reduce to minimum reproducible path.
- Capture evidence (error text, logs, screenshots, failing command).

Do not broad-refactor before isolating the defect path.

### 3) Research Cycle 1 (Precision Batch)

Run at least 5 precise, technical searches:

1. Official API/doc source for the failing subsystem.
2. Official platform-specific behavior/rules.
3. Library/framework issue tracker or changelog.
4. A second authoritative source to cross-check.
5. A targeted query for your exact error signature.

For each source, record:

- Claim.
- Confidence.
- Relevance to current repro.
- Required code change (if any).

### 4) Compute + Reframe

Synthesize findings into explicit hypotheses:

- H1, H2, H3 with expected observable consequences.
- Pick the highest-probability hypothesis first.
- Define the smallest safe experiment to falsify it.

### 5) Research Cycle 2 (Refined Batch)

Run a second search batch focused on unresolved ambiguities:

- Follow-up query per unresolved assumption.
- Query with concrete API names, error codes, and platform version.
- Query for known caveats/limitations and supported workarounds.

Update confidence scoring per hypothesis after this pass.

### 6) Implement Minimal, Layered Fix

Apply changes in smallest viable units, ordered by dependency:

- Core root-cause fix first.
- Compatibility/build/link fixes second.
- UX/polish adjustments last.

Avoid mixing unrelated refactors in the same patch.

### 7) Validate With Multiple Methods

Always run multiple check modalities:

- Static/type checks.
- Unit/integration/build checks.
- Runtime/manual behavior check for the affected user flow.
- Regression check for adjacent behavior.

If one check fails due environment lock (e.g., binary in use), resolve and rerun.

### 8) Report With Auditability

Return:

- What was broken.
- Why it broke (root cause).
- What changed and where.
- What evidence proves it is fixed.
- Residual risks and next-step hardening.

## Question Bank (for extracting better research targets)

Use these prompts internally before coding:

1. Which exact layer owns this bug?
2. What is the minimum failing path?
3. What would disprove my top hypothesis quickly?
4. Which official API behavior is relevant and version-sensitive?
5. Which fix changes the least while solving the cause?
6. Which checks prove fix + no regression?

## Failure Modes To Avoid

- Guessing root cause before repro isolation.
- Relying on one source only.
- Implementing broad UI/code changes without hypothesis test.
- Declaring fixed without runtime validation of the reported scenario.

## References

Load [research-checklist.md](references/research-checklist.md) when the task is high-stakes or ambiguous.
