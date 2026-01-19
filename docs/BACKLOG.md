# Ralph Inferno - Backlog

## Potentiella utökningar

---

### Runtime Discovery Loop

**Problem:** Ralph kan upptäcka saker under implementation som borde påverka scope.

**Idé:** Graduated response baserat på impact:

| Impact | Exempel | Åtgärd |
|--------|---------|--------|
| **Liten** | Edge case, minor refactor | Expand in-place, fortsätt |
| **Medium** | Nytt API-anrop, extra komponent | Skapa follow-up spec (`02a-discovery.md`) |
| **Stor** | Arkitekturändring, nytt beroende | Pause & notify användaren |

**Alltid:** Logga discoveries till `DISCOVERIES.md`

---

### Issue-baserad dynamisk modell

**Problem:** Nuvarande spec-modell är statisk - alla specs genereras i `/ralph:plan`. Ralph kan inte dynamiskt skapa nya tasks under körning.

**Lösning:** Byt från `specs/` till `issues/` med dynamisk skapning.

```
PRD.md = Staketet (guardrails)
issues/ = Dynamiskt, Ralph skapar vid behov
```

**Regler:**
- Ralph FÅR skapa issues som bidrar till PRD
- Ralph FÅR INTE bygga utanför PRD utan godkännande
- Scope changes → CR → `/ralph:review` → Godkänn/Avslå

---

### Blind Validation

**Problem:** När samma agent implementerar och validerar får vi confirmation bias.

**Lösning:** Separat validator-agent som INTE ser implementation-context.

```
Implementer Agent: Skriver kod baserat på spec
        ↓
Blind Validator Agent: Granskar KOD ENDAST
        ↓
"Koden har bug på rad 45" (ärlig feedback)
```

**Fördelar:**
- Hittar fler buggar
- Ingen "jag vet vad jag menade" bias
- Mer som riktig code review

---

### SQLite för state

**Problem:** Checksum-filer och loggar är fragila. Svårt att query:a historik.

**Lösning:** SQLite-databas för all state.

```sql
CREATE TABLE specs (
  id TEXT PRIMARY KEY,
  name TEXT,
  status TEXT,  -- pending, running, done, failed
  attempts INTEGER,
  tokens_used INTEGER,
  cost_usd REAL,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  error_log TEXT
);
```

**Fördelar:**
- Crash recovery (resume från exakt punkt)
- Cost tracking per spec
- Query historik ("vilka specs failar mest?")

---

### Complexity Classification

**Problem:** Ralph kör alla specs likadant, oavsett komplexitet.

**Lösning:** Klassificera specs och anpassa approach.

```
SIMPLE (< 100 tokens)     → Snabb, ingen validation
MEDIUM (100-500 tokens)   → Standard flow
COMPLEX (> 500 tokens)    → Extra validation, mer retries
RISKY (ändrar auth/db)    → Blind validation + manuell review
```

---

### Domain Modules

**Problem:** Ralph är optimerad för kod. Vad om man vill skapa andra saker?

**Idé:** Domän-specifika moduler med anpassade workflows.

```
/ralph:idea "haj-bok" --module book
/ralph:idea "todo-app" --module app
/ralph:idea "synthwave album" --module music
```

| Modul | Output | "Deploy" gör | "Test" gör |
|-------|--------|--------------|------------|
| **app** | Kod + tester | `npm run build` | Playwright E2E |
| **book** | Chapters (markdown) | Compile PDF/ePub | Spell-check, consistency |
| **music** | Prompts + metadata | Suno/Udio API | Preview + quality check |
| **video** | Script + shot list | Storyboard render | ? |
| **course** | Lessons + quizzes | LMS export | Quiz validation |

**Frågor att lösa:**
- Vad är "spec" för en bok? (Chapter outline?)
- Vad är "build pass" för musik? (API returnerar audio?)
- Hur verifierar vi kvalitet på kreativt innehåll?

---

### Design System Validation

**Problem:** Inferno mode har design review men det är basic.

**Idé:** Integrera med design system för automatisk validering.

- Läs design tokens från Figma/Storybook
- Verifiera att implementation matchar
- Screenshot diff mot design mockups

---

### Multi-VM Parallel Execution

**Problem:** En VM = en spec i taget. Långsamt för stora projekt.

**Idé:** Spinn upp flera VMs och kör oberoende specs parallellt.

```
VM-1: 01-setup.md → 02-auth.md
VM-2: 03-feature-a.md (efter setup klar)
VM-3: 04-feature-b.md (efter setup klar)
```

**Kräver:** Dependency graph, merge strategy, conflict resolution.

---

### Cost Budgets & Alerts

**Problem:** Ralph kan bränna tokens utan kontroll.

**Idé:** Sätt budget per session/spec.

```json
{
  "cost_budget": {
    "per_spec_max_usd": 5.00,
    "session_max_usd": 50.00,
    "alert_at_percent": 80
  }
}
```

**Vid budget hit:** Pause, notify, vänta på godkännande.

---

### Git Branch Strategy

**Problem:** Allt går till main/current branch.

**Idé:** Feature branches per epic/CR.

```
main
├── ralph/epic-1-auth
├── ralph/epic-2-todos
└── ralph/cr-dark-mode
```

**Auto-PR:** När epic klar → skapa PR för review.

---

## Prioritering

| Feature | Värde | Komplexitet | Notering |
|---------|-------|-------------|----------|
| Runtime discovery loop | Högt | Medel | Bygger på befintlig CR-logik |
| Blind validation | Högt | Låg | Enkel att implementera |
| SQLite state | Medel | Medel | Bra för debugging |
| Complexity classification | Medel | Låg | Quick win |
| Domain modules | Högt | Hög | Stor omskrivning |
| Design system validation | Medel | Hög | Kräver integrationer |
| Multi-VM parallel | Högt | Hög | Komplex orchestration |
| Cost budgets | Medel | Låg | Quick win |
| Git branch strategy | Medel | Medel | Nice to have |
| Issue-baserad modell | Högt | Medel | Fundamental ändring |

---

## Inspiration

- [Gas Town](https://github.com/steveyegge/gastown) - Multi-agent orchestration, git worktree persistence
- [Zeroshot](https://github.com/covibes/zeroshot) - Blind validation, SQLite state, complexity classification
- [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) - Brainstorm/Analyst personas

---

*Senast uppdaterad: 2026-01-19*
