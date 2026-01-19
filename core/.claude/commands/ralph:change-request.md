# /ralph:change-request - Brownfield Entry Point

Entry point för ändringar i existerande app. Analyserar scope och skapar plan.

## Usage
```
/ralph:change-request                    # Interactive
/ralph:change-request "add dark mode"    # With description
/ralph:change-request --bug              # Bug fix mode (after testing)
```

## When to Use

| Scenario | Command |
|----------|---------|
| New app from scratch | `/ralph:idea` → `/ralph:discover` |
| Changes to existing app | `/ralph:change-request` → `/ralph:plan` |
| Bug fixes after testing | `/ralph:change-request --bug` |

## Language Setting

**FIRST: Detect language automatically**
```bash
LANG=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
echo "Language: ${LANG:-en}"
```

Use the detected language for ALL output.

---

## STEP 1: Analyze Existing Codebase

```
🔍 ANALYZING CODEBASE
```

Read key files to understand the project:

```bash
# Project config
cat package.json 2>/dev/null | head -50
cat CLAUDE.md 2>/dev/null | head -100

# Structure
ls -la src/ 2>/dev/null
ls -la src/components/ 2>/dev/null

# Existing docs
cat docs/PRD.md 2>/dev/null | head -50
cat docs/IMPLEMENTATION_PLAN.md 2>/dev/null | head -50
```

**Output:** Project summary:
- Tech stack detected
- Existing structure
- Previous specs (if any)

---

## STEP 2: Collect Change Request

### Mode A: Feature/Enhancement (default)

```
What changes do you want to make?

Describe the change in detail:
- What should be added/changed?
- Why is this needed?
- Any specific requirements?

Your description:
```

### Mode B: Bug Fix (--bug flag)

```
🐛 Bug Fix Mode

Describe the problems you found:
1. What didn't work as expected?
2. Steps to reproduce?
3. Expected vs actual behavior?

Your observations:
```

---

## STEP 3: Scope Assessment

```
📊 ASSESSING SCOPE
```

Analyze the change request and categorize:

| Scope | Criteria | Analysis Depth |
|-------|----------|----------------|
| **Small** | 1-3 files, no new dependencies, < 2h work | Minimal - direct to spec |
| **Medium** | 4-10 files, minor architecture changes, 2-8h work | Impact analysis |
| **Large** | 10+ files, new patterns/dependencies, 8h+ work | Full analysis, mini-PRD |

**Factors to consider:**
- Number of files affected
- New dependencies needed?
- Database changes?
- Breaking changes?
- New patterns introduced?

Show assessment:
```
Scope Assessment: {SMALL/MEDIUM/LARGE}

Rationale:
- Files affected: ~{N}
- New dependencies: {yes/no}
- Database changes: {yes/no}
- Breaking changes: {yes/no}
- Estimated complexity: {low/medium/high}

1) Agree with assessment
2) Override to different scope

Reply with number:
```

---

## STEP 4: Analysis Based on Scope

### SMALL Scope - Direct to Spec

```
✅ SMALL SCOPE - Creating spec directly
```

Create single spec file:
```markdown
# CR: {Brief description}

{What needs to change}

## Requirements
- {Requirement 1}
- {Requirement 2}

## Files to modify
- {file1.tsx}
- {file2.ts}

## Done when
- [ ] Build passes
- [ ] {Specific verification}
```

→ Skip to STEP 6

---

### MEDIUM Scope - Impact Analysis

```
🔍 MEDIUM SCOPE - Running impact analysis
```

**Analyze:**
1. Which files will be affected?
2. Which components need changes?
3. Any shared utilities impacted?
4. Database/API changes needed?
5. Test coverage implications?

**Output Impact Report:**
```markdown
## Impact Analysis

### Files to Modify
| File | Change Type | Risk |
|------|-------------|------|
| {file} | {modify/create/delete} | {low/med/high} |

### Dependencies
- {New packages needed}
- {Existing packages affected}

### Database
- {Schema changes}
- {Migration needed?}

### Breaking Changes
- {List any breaking changes}

### Test Impact
- {Which tests need updating}
- {New tests needed}
```

→ Continue to STEP 5

---

### LARGE Scope - Full Analysis + Mini-PRD

```
📋 LARGE SCOPE - Full analysis required
```

**Run mini-discovery:**

1. **Technical Feasibility**
   - Can this be done with current stack?
   - New patterns needed?
   - Architectural implications?

2. **Risk Assessment**
   - What could go wrong?
   - Rollback strategy?
   - Feature flag needed?

3. **Dependency Analysis**
   - Affected systems
   - Integration points
   - Breaking changes

4. **Effort Estimation**
   - Number of specs needed
   - Critical path

**WebSearch** (if needed):
- Best practices for {change type}
- {technology} migration guide
- Common pitfalls for {pattern}

**Output Mini-PRD:**
```markdown
## Change Request Analysis

### Summary
{What we're changing and why}

### Technical Approach
{How we'll implement this}

### Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| {risk} | {mitigation} |

### Phases
| Phase | Scope | Specs |
|-------|-------|-------|
| 1 | {scope} | {N} |
| 2 | {scope} | {N} |

### Rollback Plan
{How to undo if needed}

### Success Criteria
- {criterion 1}
- {criterion 2}
```

→ Continue to STEP 5

---

## STEP 5: Create Change Request Document

Create `docs/CHANGE-REQUEST-{date}.md`:

```markdown
# Change Request - {Title}

**Date:** {YYYY-MM-DD}
**Scope:** {SMALL/MEDIUM/LARGE}
**Requestor:** User

## Summary
{1-2 sentences describing the change}

## Background
{Why this change is needed}

## Requirements
{What specifically needs to be done}

## Scope Assessment
{From STEP 3}

## Impact Analysis
{From STEP 4 - for MEDIUM/LARGE only}

## Technical Approach
{High-level approach}

## Files Affected
| File | Change |
|------|--------|
| {file} | {what changes} |

## Specs to Create
| Spec | Description |
|------|-------------|
| CR-01-{name} | {what} |
| CR-02-{name} | {what} |

## Success Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}

## Risks
| Risk | Mitigation |
|------|------------|
| {risk} | {plan} |

---

*Generated by Ralph Change Request*
*Next step: /ralph:plan --change-request*
```

---

## STEP 6: Generate Specs

### For Bug Fixes:
```
.ralph-specs/
├── CR-01-fix-{bug}.md
├── CR-02-fix-{bug}.md
└── ...
```

### For Features/Enhancements:
```
.ralph-specs/
├── CR-01-{feature-part-1}.md
├── CR-02-{feature-part-2}.md
└── ...
```

**Spec format:**
```markdown
# CR-{NN}: {Brief description}

{What needs to be done - 1-2 sentences}

## Context
- Existing: {what exists now}
- Change: {what should change}

## Requirements
- {Requirement 1}
- {Requirement 2}

## Files to modify
- {file1.tsx} - {what change}
- {file2.ts} - {what change}

## E2E Test
Update/create test in `e2e/{feature}.spec.ts`:
- {what to verify}

## Done when
- [ ] Build passes
- [ ] E2E test passes
- [ ] {Specific verification}
- [ ] Regression: {existing functionality still works}
```

**IMPORTANT:**
- Keep specs MINIMAL (max 20 lines)
- One spec = one focused change
- Include regression check
- Reference existing files

---

## STEP 7: Update Plan (if exists)

If `docs/IMPLEMENTATION_PLAN.md` exists, append:

```markdown
---

## Change Request: {title}

**Date:** {date}
**Scope:** {scope}

### CR Specs
- [ ] CR-01-{name}.md
- [ ] CR-02-{name}.md
- **HARD STOP** - Verify all CR changes

### CR Traceability
| Requirement | Spec |
|-------------|------|
| {req 1} | CR-01 |
| {req 2} | CR-02 |
```

---

## DEFINITION OF DONE - Change Request

| Kriterium | Verifiering |
|-----------|-------------|
| ✅ Codebase analyzed | Förstår existerande struktur |
| ✅ Scope assessed | S/M/L med rationale |
| ✅ Impact analyzed | (för M/L) Filer och risker identifierade |
| ✅ CHANGE-REQUEST.md skapad | Dokumentation komplett |
| ✅ Specs genererade | CR-*.md filer |
| ✅ Regression planned | Specs inkluderar regression check |

---

## NÄR KLAR

```
CHANGE_REQUEST_COMPLETE

Scope: {SMALL/MEDIUM/LARGE}

Created:
- docs/CHANGE-REQUEST-{date}.md
- .ralph-specs/CR-01-{name}.md
- .ralph-specs/CR-02-{name}.md
- ... ({total} specs)

Impact:
- Files affected: {N}
- New dependencies: {yes/no}
- Database changes: {yes/no}

Next steps:
1. Review specs in .ralph-specs/CR-*.md
2. Run /ralph:preflight to verify requirements
3. Run /ralph:deploy to push to VM and start building
```

---

## MODE SELECTION SUMMARY

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CHANGE REQUEST FLOW                                   │
└─────────────────────────────────────────────────────────────────────────────┘

                    /ralph:change-request
                            │
                            ▼
                   ┌─────────────────┐
                   │ Analyze Codebase│
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Collect Request │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Assess Scope    │
                   └────────┬────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
       ┌─────────┐    ┌──────────┐    ┌─────────┐
       │  SMALL  │    │  MEDIUM  │    │  LARGE  │
       │         │    │          │    │         │
       │ Direct  │    │ Impact   │    │ Full    │
       │ to spec │    │ Analysis │    │ Analysis│
       └────┬────┘    └────┬─────┘    └────┬────┘
            │              │               │
            └──────────────┴───────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Generate Specs  │
                   │ CR-01, CR-02... │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ /ralph:deploy   │
                   └─────────────────┘
```

---

## START NOW

1. Analyze existing codebase
2. Collect change request details
3. Assess scope (S/M/L)
4. Run appropriate analysis
5. Create CHANGE-REQUEST.md
6. Generate specs
