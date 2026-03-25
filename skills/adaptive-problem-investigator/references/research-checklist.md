# Research Checklist

Use this checklist before final implementation on ambiguous problems.

## Source Quality

- Prefer official docs, specifications, or primary maintainers.
- Cross-check critical claims in at least two sources.
- Note platform/version constraints.

## Query Precision

- Include exact API names, error text, and OS/runtime version.
- Use focused queries for each hypothesis, not broad generic terms.
- Search known issue trackers/changelogs for regressions.

## Decision Quality

- Keep hypotheses explicit with confidence levels.
- Falsify highest-confidence hypothesis first.
- Choose smallest safe patch that explains all observed symptoms.

## Validation Quality

- Run at least one static check and one runtime check.
- Validate the exact user-reported path.
- Confirm no obvious regression in neighboring flows.
