---
mode: agent
description: Generate implementation specs from PRD
---

# Ralph Plan - PRD to Specs

Convert PRD into actionable implementation specs.

## Prerequisites

- `docs/PRD.md` must exist (run `/prompt:ralph-idea` first)

## Instructions

1. Read `docs/PRD.md`
2. Break down into atomic, testable specs
3. Create `.ralph-specs/` directory
4. Generate numbered spec files: `01-*.md`, `02-*.md`, etc.

## Spec Format

Each spec file should contain:

```markdown
# Spec: {Title}

## Objective
{What this spec accomplishes}

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Notes
{Implementation hints}
```

## When Done

```
✅ PLAN_COMPLETE

Specs saved to: .ralph-specs/

Generated {count} specs:
- 01-project-setup.md
- 02-{feature}.md
- ...

Next step: Run /prompt:ralph-preflight
```
