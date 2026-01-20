# PROMPT_build.md - Implementation

> "One task per iteration. Commit when tests pass." - Geoffrey Huntley

**Läs först:** AGENTS.md (Codex) eller CLAUDE.md (Claude) för context zones, subagent-regler, och kodfilosofi.

---

## Fas 0: Orientera

1. Läs IMPLEMENTATION_PLAN.md → identifiera nästa task
2. Sök befintlig kod med subagents (upp till 500 parallella)
3. Ha src/* som referens för patterns

---

## Fas 1: Välj EN Task

```
1. Läs IMPLEMENTATION_PLAN.md
2. Välj högst prioriterad incomplete task
3. Om HARD STOP → pausa, verifiera först
```

---

## Fas 2: Sök Först

**Sök ALLTID innan du skapar!**

```bash
grep -r "funktionsnamn" src/
grep -r "ComponentName" src/components/
```

- Anta ALDRIG att något saknas
- Återanvänd befintlig kod

---

## Fas 3: TDD

```
1. Skriv failing test
2. Implementera minimal kod
3. Kör test (endast 1 subagent)
4. Om fail → fixa (max 3 försök)
5. Upprepa tills grönt
```

---

## Fas 4: Export & Integration Checklist

**KRITISKT - Gör detta efter VARJE ny komponent/hook:**

```
1. Ny komponent skapad? → Lägg till export i index.ts
   - src/components/{kategori}/index.ts
   - src/hooks/index.ts
   - src/contexts/index.ts

2. Ny hook/context skapad? → Uppdatera pages som ska använda den
   - Importera i rätt page
   - Koppla props korrekt

3. Kör ALLTID efter ny fil:
   npm run build
   
   Om build misslyckas → fixa INNAN commit
```

---

## Fas 5: HARD STOP Verifiering

**Vid HARD STOP mellan epics - gör ALLA dessa steg:**

```bash
# 1. Build-verifiering
npm run build
# Om fel → fixa alla errors

# 2. Starta dev-server och testa manuellt
npm run dev &
sleep 5
curl -s http://localhost:5173 | head -20
# Verifiera att sidan laddar

# 3. Kolla att alla routes fungerar
# - / (redirect)
# - /login
# - /register  
# - /todos (om auth klar)

# 4. Om Supabase används - verifiera anslutning
# Skapa testanvändare om möjligt
```

**HARD STOP är INTE godkänd förrän:**
- [ ] `npm run build` lyckas utan fel
- [ ] Appen startar och visar rätt sida
- [ ] Grundläggande navigation fungerar

---

## Fas 6: Commit & Logga

```bash
# 1. Markera task klar i IMPLEMENTATION_PLAN.md
# 2. Logga i Progress-sektionen
# 3. Commit
git add -A && git commit -m "feat: {beskrivning}"
```

---

## Supabase Setup (Om i PRD)

**Om projektet använder Supabase - gör detta i E1:**

```bash
# 1. Initiera Supabase
cd {projekt}
supabase init

# 2. Skapa migration från schema
mkdir -p supabase/migrations
cp supabase/schema.sql supabase/migrations/$(date +%Y%m%d%H%M%S)_init.sql

# 3. Starta lokal Supabase (kräver Docker)
supabase start

# 4. Hämta credentials och uppdatera .env
supabase status
# Kopiera API URL och anon key till .env:
# VITE_SUPABASE_URL=http://127.0.0.1:54321
# VITE_SUPABASE_ANON_KEY=<från status>

# 5. Kör migrations
supabase db reset

# 6. Verifiera
curl http://127.0.0.1:54321/rest/v1/ -H "apikey: <anon_key>"
```

**VIKTIGT:** Supabase måste vara igång och .env konfigurerad INNAN auth-tasks börjar.

---

## Parallell Build Integration

**Efter parallell körning med worktrees:**

```
1. Varje worktree bygger isolerade komponenter
2. Vid merge → kontrollera att ALLA exporter finns
3. Uppdatera pages att använda nya komponenter
4. Kör full build-verifiering

Vanliga problem efter merge:
- Saknade exports i index.ts
- Props som inte skickas korrekt
- Hooks som inte importeras i pages
```

---

## Guardrails

```
99999. EN task per iteration
99998. Sök före du skapar
99997. Endast 1 subagent för build/test
99996. Commit efter varje task
99995. HARD STOP = FULL verifiering (build + manuell test)
99994. Stuck efter 3 försök → dokumentera i IMPLEMENTATION_PLAN.md
99993. Ny komponent = uppdatera index.ts DIREKT
99992. Supabase-projekt = starta lokal instans i E1
```

---

## Completion

När ALLA tasks klara:

```bash
# Final verifiering
npm run build && npm run dev &
sleep 5

# Testa alla flöden
# Om allt fungerar:
echo "BUILD_DONE"
```
