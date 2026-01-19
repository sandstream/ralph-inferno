# /ralph:change-request - Create Change Request from Testing

Document bugs and issues found during testing, generate new specs for Ralph to fix.

## Usage
```
/ralph:change-request
```

## Prerequisites
- App has been built by Ralph (`/ralph:deploy` completed)
- Testing has been done (`/ralph:review` completed)
- Issues/bugs have been identified

## Language Setting

**FIRST: Detect language automatically**
```bash
LANG=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
echo "Language: ${LANG:-en}"
```

Use the detected language (default: English) for ALL output (CR docs, specs, user prompts).

## Output
- `docs/CHANGE_REQUEST.md` - Problem documentation
- `specs/CR-*.md` - New spec files for fixes

## Instructions

**PHASE 1: COLLECT PROBLEMS**

Ask the user (in configured language):
```
🔍 Change Request

Describe the problems you found during testing:
1. What didn't work as expected?
2. Which features are missing or incomplete?
3. Any UI/UX issues?

Paste your observations:
```

Wait for user input.

**PHASE 2: CATEGORIZE PROBLEMS**

Analyze input and categorize:

1. **BUGS** - Things that are broken/wrong
2. **INCOMPLETE** - Started but not finished
3. **MISSING** - Completely missing despite being in spec
4. **ENHANCEMENT** - Improvements beyond original spec

**PHASE 3: CREATE CHANGE_REQUEST.md**

Create `docs/CHANGE_REQUEST.md`:

```markdown
# Change Request - [DATE]

## Summary
{1-2 sentences about what was found}

## Categories

### 🐛 Bugs
| # | Problem | Affects | Priority |
|---|---------|---------|----------|
| B1 | {description} | {feature} | HIGH/MED/LOW |

### ⚠️ Incomplete
| # | Feature | Status | Missing |
|---|---------|--------|---------|
| I1 | {feature} | {%} | {what} |

### ❌ Missing
| # | Feature | Spec Reference |
|---|---------|----------------|
| M1 | {feature} | {original-spec} |

### 💡 Enhancements (Optional)
| # | Suggestion | Value |
|---|------------|-------|
| E1 | {suggestion} | {value} |

---

## Original Specs
{List which specs were run}

## Testing Done
{Summary of testing}
```

**PHASE 4: GENERATE NEW SPECS**

Create new spec files for each problem:

```
specs/
├── CR-01-fix-{bug}.md
├── CR-02-complete-{feature}.md
└── CR-03-add-{missing}.md
```

**Spec format for fixes:**
```markdown
# CR-XX: {Brief description}

{Problem}: {What is wrong}
{Fix}: {What needs to be done}

## Requirements
- {Concrete requirement 1}
- {Concrete requirement 2}

## Done when
- [ ] Build passes
- [ ] {Specific verification of fix}
- [ ] Regression: {existing functionality still works}
```

**IMPORTANT:**
- Keep specs MINIMAL (max 15 lines)
- One spec = one problem
- Include regression test in "Done when"
- CR specs run AFTER original specs

**PHASE 5: UPDATE IMPLEMENTATION_PLAN.md**

Add CR tasks to `docs/IMPLEMENTATION_PLAN.md`:

```markdown
## Change Request Tasks

### CR-Fixes (Priority: Critical)
- [ ] CR-01: {fix}
- [ ] CR-02: {fix}
- [ ] **HARD STOP** - Verify all CR fixes

### CR-Enhancements (Priority: Low)
- [ ] CR-03: {enhancement}
```

**WHEN DONE:**
```
CHANGE_REQUEST_DONE

Created:
- docs/CHANGE_REQUEST.md
- X new specs in specs/CR-*.md

Next: Run /ralph:deploy to push CR specs to VM
```
