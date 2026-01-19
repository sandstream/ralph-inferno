# /ralph:plan - Create Implementation Plan

Analyze PRD or Change Request and create implementation plan with executable specs.

## Usage
```
/ralph:plan                         # Auto-detect input (PRD or CR)
/ralph:plan --prd                   # Force PRD mode
/ralph:plan --change-request        # Force Change Request mode
/ralph:plan --input custom.md       # Custom input file
```

## Two Entry Points

| Source | Input | Output |
|--------|-------|--------|
| Greenfield (new app) | `docs/PRD.md` | Full spec sequence |
| Brownfield (changes) | `docs/CHANGE-REQUEST-*.md` | CR-* specs |

## Prerequisites
- **Greenfield:** `docs/PRD.md` must exist (run `/ralph:discover` first)
- **Brownfield:** `docs/CHANGE-REQUEST-*.md` must exist (run `/ralph:change-request` first)

## Output
- `docs/IMPLEMENTATION_PLAN.md` - Overview with epics and tasks
- `.ralph-specs/*.md` - Executable spec files (this is what Ralph runs on VM)

## LANGUAGE SETTING

**FIRST: Detect language automatically**
```bash
LANG=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
echo "Language: ${LANG:-en}"
```

Use the detected language for ALL output (specs, plans, comments).

---

## STEP 1: Detect Input Source

```bash
# Check for Change Request (most recent)
CR_FILE=$(ls -t docs/CHANGE-REQUEST-*.md 2>/dev/null | head -1)

# Check for PRD
PRD_FILE="docs/PRD.md"

if [ -n "$CR_FILE" ]; then
    echo "Found Change Request: $CR_FILE"
elif [ -f "$PRD_FILE" ]; then
    echo "Found PRD: $PRD_FILE"
else
    echo "No input found"
fi
```

**Auto-detect logic:**
1. If `CHANGE-REQUEST-*.md` exists → Change Request mode
2. Else if `PRD.md` exists → PRD mode
3. Else → Error

```
Detected input source:

1) Change Request: {filename} (brownfield)
2) PRD: docs/PRD.md (greenfield)
3) Neither found - need to run /ralph:discover or /ralph:change-request first

Using: {detected}

1) Continue with detected source
2) Switch to other source

Reply with number:
```

---

## STEP 2: Choose Mode

```
How do you want to create specs?

1) Autonomous (YOLO) - I analyze PRD and create all specs, you review at the end
2) Interactive - We go through each epic/spec together

Reply with number:
```

---

## PLANNING PHASES

### For Change Requests (Brownfield)

If input is a Change Request, the planning is simplified:

1. **Read CR document** - Requirements and scope already defined
2. **Verify specs from CR** - CR should have suggested specs
3. **Check completeness** - Ensure all requirements have specs
4. **Generate any missing specs** - Fill gaps
5. **Update IMPLEMENTATION_PLAN.md** - Add CR section

**CR specs are prefixed with `CR-`:**
```
.ralph-specs/
├── 01-project-setup.md      # Original specs (if any)
├── 02-auth.md
├── CR-01-dark-mode.md       # Change Request specs
├── CR-02-theme-toggle.md
└── ...
```

→ Skip to "SPEC FILE FORMAT" section

---

### For PRD (Greenfield)

### Phase 1: ANALYZE PRD

```
📊 ANALYZING PRD
```

1. Identify all features from "Must Have (MVP)"
2. Group into logical epics (max 5-7 epics)
3. Identify dependencies between tasks
4. Order by dependency (what must come first?)

**Output:** Epic overview

---

### Phase 2: BREAK DOWN EPICS

```
🔨 BREAKING DOWN EPICS
```

For each epic:
1. List all tasks needed
2. Ensure each task is atomic (one thing)
3. Add acceptance criteria from PRD
4. Identify E2E test for each

**Rule:** One task = one sentence without "and"

---

### Phase 3: VERIFY COMPLETENESS

```
✅ VERIFYING COMPLETENESS
```

**Completeness Loop:**

```
For each spec:
  1. Läs spec
  2. Checka mot PRD:
     - Täcker denna spec PRD-kravet fullständigt?
     - Saknas edge cases?
     - Saknas error handling?
  3. Checka mot andra specs:
     - Finns alla beroenden?
     - Är ordningen rätt?
  4. Om luckor → iterera
  5. Annars → nästa spec
```

| Check | Question |
|-------|----------|
| ✅ PRD Coverage | Täcker specs ALLA must-have features? |
| ✅ Dependencies | Är beroenden explicit? |
| ✅ Testability | Har varje spec E2E test criteria? |
| ✅ Atomicity | Är varje spec EN sak? |
| ✅ Order | Är ordningen rätt (dependencies first)? |

---

## SPEC FILE FORMAT

**KEEP SPECS MINIMAL - MAX 20 LINES**

```markdown
# {Task-name}

{1-2 sentences what to build}

## Requirements
- {Concrete requirement 1}
- {Concrete requirement 2}
- {Concrete requirement 3}

## E2E Test
Write test in `e2e/{feature}.spec.ts` that verifies:
- {what test should check}

## Done when
- [ ] Build passes
- [ ] E2E test passes
- [ ] {Specific verification}
```

**IMPORTANT:**
- No background/context - Claude reads the code
- No implementation details - Claude knows how
- Only WHAT, not HOW
- One spec = one focused task

---

## SPEC STRUCTURE

```
.ralph-specs/
├── 01-project-setup.md   ← MUST include Playwright!
├── 02-database-schema.md
├── 03-auth-context.md
├── 04-login-page.md
├── 05-{feature}.md
└── ...
```

**CRITICAL - 01-project-setup MUST contain:**
- Vite + React + TypeScript setup (or chosen stack)
- Tailwind with design tokens from PRD
- **Playwright installation** (`npx playwright install`)
- `playwright.config.ts`
- `e2e/smoke.spec.ts`

> ⚠️ Without Playwright, Ralph's test-loop won't work!

---

## EXAMPLE SPECS

### Good spec (minimal):
```markdown
# Auth Context

Create React context for authentication with Supabase.

## Requirements
- AuthProvider wrapper component
- useAuth hook (user, signIn, signOut, loading)
- Automatic session refresh on mount

## E2E Test
Write test in `e2e/auth.spec.ts` that verifies:
- Sign in redirects to home
- Sign out clears session

## Done when
- [ ] Build passes
- [ ] Can sign in/out via hook
```

### Bad spec (too long):
```markdown
# Auth Context

## Background
Authentication is important for...
[10 lines of unnecessary context]

## Implementation
1. Create src/contexts/AuthContext.tsx
2. Import createContext from react
3. Define AuthContextType interface
[20 lines of step-by-step implementation]
```

---

## IMPLEMENTATION_PLAN.md

Create `docs/IMPLEMENTATION_PLAN.md`:

```markdown
# Implementation Plan

## Epics Overview

| Epic | Name | Specs | Status |
|------|------|-------|--------|
| E1 | Project Setup | 01 | pending |
| E2 | Authentication | 02-04 | pending |
| E3 | Core Features | 05-08 | pending |
| E4 | Polish | 09-10 | pending |

## Spec Sequence

### E1: Project Setup (MUST COMPLETE FIRST)
- [ ] 01-project-setup.md
- **HARD STOP** - Verify build + Playwright works

### E2: Authentication
- [ ] 02-database-schema.md
- [ ] 03-auth-context.md
- [ ] 04-login-page.md
- **HARD STOP** - Verify login flow works

### E3: Core Features
- [ ] 05-{feature}.md
- [ ] 06-{feature}.md
- [ ] 07-{feature}.md
- [ ] 08-{feature}.md

### E4: Polish
- [ ] 09-{feature}.md
- [ ] 10-{feature}.md

## Dependencies

```
01 → 02 → 03 → 04
          ↓
     05 → 06 → 07 → 08
                    ↓
               09 → 10
```

## PRD Traceability

| PRD Feature | Spec(s) | Status |
|-------------|---------|--------|
| {Must-have 1} | 03, 04 | pending |
| {Must-have 2} | 05, 06 | pending |

---

*Generated by Ralph Planning Mode*
*Next step: /ralph:deploy to start building*
```

### For Change Requests - Append to existing plan:

```markdown
---

## Change Request: {Title}

**Date:** {YYYY-MM-DD}
**Scope:** {SMALL/MEDIUM/LARGE}
**Source:** docs/CHANGE-REQUEST-{date}.md

### CR Specs

- [ ] CR-01-{name}.md - {description}
- [ ] CR-02-{name}.md - {description}
- **HARD STOP** - Verify all CR changes + regression

### CR Dependencies

```
CR-01 → CR-02 → CR-03
```

### CR Traceability

| CR Requirement | Spec | Status |
|----------------|------|--------|
| {Requirement 1} | CR-01 | pending |
| {Requirement 2} | CR-02 | pending |

### Regression Checklist

- [ ] {Existing feature 1} still works
- [ ] {Existing feature 2} still works
- [ ] All original E2E tests pass
```

---

## DEFINITION OF DONE - Planning

### For PRD (Greenfield)

| Kriterium | Verifiering |
|-----------|-------------|
| ✅ Alla PRD must-haves täckta | Traceability komplett |
| ✅ Specs är atomära | En sak per spec |
| ✅ Dependencies explicit | Ordning är tydlig |
| ✅ E2E test för varje spec | Testability klar |
| ✅ 01-project-setup har Playwright | Test-loop kommer funka |
| ✅ Specs är minimala | Max 20 rader |
| ✅ Inga open questions | Allt är specificerat |

### For Change Request (Brownfield)

| Kriterium | Verifiering |
|-----------|-------------|
| ✅ Alla CR requirements täckta | Traceability komplett |
| ✅ Specs är atomära | En sak per spec |
| ✅ Dependencies explicit | CR-ordning tydlig |
| ✅ E2E test för varje spec | Testability klar |
| ✅ Regression tests inkluderade | Existerande funktionalitet verifieras |
| ✅ Files to modify listade | Vet vilka filer som påverkas |
| ✅ Specs är minimala | Max 20 rader |

---

## NÄR KLAR

### For PRD (Greenfield)
```
PLANNING_COMPLETE

Created:
- docs/IMPLEMENTATION_PLAN.md
- .ralph-specs/01-project-setup.md
- .ralph-specs/02-{name}.md
- ... ({total} specs)

Summary:
- Epics: {antal}
- Specs: {total}
- PRD coverage: 100%

Next steps:
1. Review specs in .ralph-specs/
2. Run /ralph:preflight to verify requirements
3. Run /ralph:deploy to push to VM and start building
```

### For Change Request (Brownfield)
```
PLANNING_COMPLETE (Change Request)

Source: docs/CHANGE-REQUEST-{date}.md
Scope: {SMALL/MEDIUM/LARGE}

Created:
- Updated docs/IMPLEMENTATION_PLAN.md (CR section)
- .ralph-specs/CR-01-{name}.md
- .ralph-specs/CR-02-{name}.md
- ... ({total} CR specs)

Summary:
- CR Specs: {total}
- Files affected: {N}
- Regression tests: {N}

Next steps:
1. Review specs in .ralph-specs/CR-*.md
2. Run /ralph:preflight to verify requirements
3. Run /ralph:deploy to push to VM and start building
```

---

## START NOW

1. Detect input source (PRD or Change Request)
2. Ask for mode (Autonomous/Interactive)
3. If PRD: Analyze and break down into epics
4. If CR: Verify specs cover all requirements
5. Create specs with completeness loop
6. Generate/update IMPLEMENTATION_PLAN.md
7. Verify coverage (PRD or CR requirements)
