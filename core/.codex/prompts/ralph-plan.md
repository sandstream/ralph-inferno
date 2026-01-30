# /prompts:ralph-plan - Create Implementation Plan

Analyze PRD and create implementation plan with executable specs.

## Usage
```
/prompts:ralph-plan                    # Uses docs/PRD.md
/prompts:ralph-plan --input prd.md     # Custom PRD file
```

## Prerequisites
- `docs/PRD.md` must exist (run `/prompts:ralph-discover` first)

## Output
- `docs/IMPLEMENTATION_PLAN.md` - Overview with epics and tasks
- `.ralph-.ralph-specs/*.md` - Executable spec files (this is what Ralph runs on VM)

## LANGUAGE SETTING

**FIRST: Detect language automatically**
```bash
LANG=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
echo "Language: ${LANG:-en}"
```

Use the detected language for ALL output (specs, plans, comments).

---

## STEP 1: Read PRD

```bash
cat docs/PRD.md 2>/dev/null || echo "PRD not found"
```

Om PRD saknas:
```
ERROR: docs/PRD.md not found.

Run /prompts:ralph-discover first to create PRD.
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
- No background/context - Codex reads the code
- No implementation details - Codex knows how
- Only WHAT, not HOW
- One spec = one focused task

---

## SPEC STRUCTURE

```
.ralph-.ralph-specs/
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
*Next step: /prompts:ralph-deploy to start building*
```

---

## DEFINITION OF DONE - Planning

| Kriterium | Verifiering |
|-----------|-------------|
| ✅ Alla PRD must-haves täckta | Traceability komplett |
| ✅ Specs är atomära | En sak per spec |
| ✅ Dependencies explicit | Ordning är tydlig |
| ✅ E2E test för varje spec | Testability klar |
| ✅ 01-project-setup har Playwright | Test-loop kommer funka |
| ✅ Specs är minimala | Max 20 rader |
| ✅ Inga open questions | Allt är specificerat |

---

## NÄR KLAR

```
PLANNING_COMPLETE

Created:
- docs/IMPLEMENTATION_PLAN.md
- .ralph-.ralph-specs/01-project-setup.md
- .ralph-.ralph-specs/02-{name}.md
- ... ({total} specs)

Summary:
- Epics: {antal}
- Specs: {total}
- PRD coverage: 100%

Next steps:
1. Review specs in .ralph-.ralph-specs/
2. Run /prompts:ralph-preflight to verify requirements
3. Run /prompts:ralph-deploy to push to VM and start building
```

---

## START NOW

1. Read PRD
2. Ask for mode (Autonomous/Interactive)
3. Analyze and break down into epics
4. Create specs with completeness loop
5. Generate IMPLEMENTATION_PLAN.md
6. Verify PRD coverage
