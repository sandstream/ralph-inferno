# Ralph Inferno - Backlog

## Framtida features och idéer

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

### Confidence-based autonomy

**Problem:** Ralph frågar för mycket ELLER för lite. Behöver smart balans.

**Lösning:** Ralph researchar "best practices" och tar beslut baserat på confidence.

```
HÖG CONFIDENCE (>80%)           LÅG CONFIDENCE (<80%)
─────────────────────           ─────────────────────
• Klarna i svensk checkout     • Ny experimentell tech
• Apple Login i iOS-app        • Ovanlig arkitektur
• Tailwind för styling         • Dyr integration

→ Kör direkt                   → Skapa CR, fråga
```

**Exempel på Ralph's resonemang:**
```
"PRD säger 'checkout med betalning' men specificerar inte metod.

Research:
- Klarna: 95% av svenska e-handel → STANDARD
- Swish: 80% → STANDARD
- Crypto: 5% → NICHE

Decision: Implementerar Klarna + Swish (standard)
          Skippar crypto (skapar CR om det behövs)"
```

**Fördelar:**
- Ralph beter sig som en junior dev med research-skills
- Frågar inte om självklarheter (TypeScript, Tailwind)
- Frågar om ovanliga/dyra/kontroversiella val

---

### Trädgårds-metaforen

```
PRD.md = Trädgårdsplanen ("tomater här, gurkor där")
specs/ = Fröna vi sår
issues/ = Vad som faktiskt växer

Guardrails = PRD - vi VET vad vi vill bygga
Flexibilitet = HOW - Ralph löser vägen dit
```

---

---

### Blind Validation (från Zeroshot)

**Problem:** När samma agent implementerar och validerar får vi confirmation bias - den "ser" att koden borde fungera.

**Lösning:** Separat validator-agent som INTE ser implementation-context.

```
Implementer Agent: Skriver kod baserat på spec
        ↓
Blind Validator Agent: Granskar KOD ENDAST
        ↓
"Koden har bug på rad 45" (ärlig feedback)
```

**Implementation:**
```bash
# Efter implementation
claude --dangerously-skip-permissions -p "
  Review this code for bugs. You have NOT seen the spec.
  Only review the code itself.
  $(cat src/checkout.ts)
"
```

**Fördelar:**
- Hittar fler buggar
- Ingen "jag vet vad jag menade" bias
- Mer som riktig code review

---

### SQLite för state (från Zeroshot)

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

CREATE TABLE issues (
  id TEXT PRIMARY KEY,
  spec_id TEXT,
  type TEXT,  -- bug, feature, scope_change
  confidence REAL,
  auto_approved BOOLEAN,
  created_at TIMESTAMP
);
```

**Fördelar:**
- Crash recovery (resume från exakt punkt)
- Cost tracking per spec
- Query historik ("vilka specs failar mest?")
- Bättre `/ralph:status`

---

### Complexity Classification (från Zeroshot)

**Problem:** Ralph kör alla specs likadant, oavsett komplexitet.

**Lösning:** Klassificera specs och anpassa approach.

```
SIMPLE (< 100 tokens)     → Snabb, ingen validation
MEDIUM (100-500 tokens)   → Standard flow
COMPLEX (> 500 tokens)    → Extra validation, mer retries
RISKY (ändrar auth/db)    → Blind validation + manuell review
```

**Implementation:**
```bash
classify_spec() {
  local tokens=$(estimate_tokens "$1")
  local has_auth=$(grep -c "auth\|login\|password" "$1")
  local has_db=$(grep -c "database\|migration\|schema" "$1")

  if [ $has_auth -gt 0 ] || [ $has_db -gt 0 ]; then
    echo "RISKY"
  elif [ $tokens -gt 500 ]; then
    echo "COMPLEX"
  elif [ $tokens -gt 100 ]; then
    echo "MEDIUM"
  else
    echo "SIMPLE"
  fi
}
```

---

## Prioritering

| Feature | Värde | Komplexitet | Status |
|---------|-------|-------------|--------|
| Issue-baserad modell | Högt | Medel | Backlog |
| Confidence-based autonomy | Högt | Hög | Backlog |
| PRD-validering för issues | Medel | Låg | Backlog |
| Blind validation | Högt | Låg | Backlog |
| SQLite state | Medel | Medel | Backlog |
| Complexity classification | Medel | Låg | Backlog |

---

## Inspiration

- [Gas Town](https://github.com/steveyegge/gastown) - Multi-agent orchestration, git worktree persistence
- [Zeroshot](https://github.com/covibes/zeroshot) - Blind validation, SQLite state, complexity classification

---

*Senast uppdaterad: 2025-01-16*
