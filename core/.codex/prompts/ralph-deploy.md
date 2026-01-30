# /prompts:ralph-deploy - Deploy till VM via GitHub

Pusha projekt till GitHub och starta Ralph på VM.

## Usage
```
/prompts:ralph-deploy
/prompts:ralph-deploy --overnight   # Stäng av VM när klar
/prompts:ralph-deploy --skip-requirements  # Hoppa över requirements check
```

## Prerequisites
- IMPLEMENTATION_PLAN.md eller .ralph-.ralph-specs/*.md måste finnas
- VM måste vara konfigurerad (~/.ralph-vm)
- GitHub repo måste finnas

## Instructions

Du är en deployment-assistent. Kör dessa steg:

**STEG 1: VALIDERA**

Kör denna validering och STOPPA om något saknas:

```bash
echo "=== PRE-DEPLOY VALIDATION ==="

# 1. Specs måste finnas
SPEC_COUNT=$(ls -1 .ralph-.ralph-specs/*.md 2>/dev/null | grep -v "CR-" | wc -l | tr -d ' ')
if [ "$SPEC_COUNT" -eq 0 ]; then
    echo "❌ FATAL: No specs found in .ralph-.ralph-specs/"
    echo "   Run /prompts:ralph-plan first to generate specs"
    exit 1
fi
echo "✅ Found $SPEC_COUNT specs"

# 2. PRD bör finnas
if [ ! -f "docs/PRD.md" ] && [ ! -f "docs/prd.md" ]; then
    echo "⚠️  WARNING: No PRD found in docs/"
    echo "   Recommended: Run /prompts:ralph-discover first"
fi

# 3. AGENTS.md bör finnas
if [ ! -f "AGENTS.md" ]; then
    echo "⚠️  WARNING: No AGENTS.md found"
    echo "   Ralph works better with project instructions"
fi

# 4. VM config
if [ ! -f "$HOME/.ralph-vm" ]; then
    echo "❌ FATAL: No VM config found (~/.ralph-vm)"
    echo "   Create it with: echo 'VM_IP=x.x.x.x' > ~/.ralph-vm"
    exit 1
fi
source ~/.ralph-vm
echo "✅ VM config: $VM_USER@$VM_IP"

# 5. Git remote
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "❌ FATAL: No git remote 'origin'"
    echo "   Add with: git remote add origin <url>"
    exit 1
fi
echo "✅ Git remote OK"

echo ""
echo "=== VALIDATION PASSED ==="
```

Om något är ❌ FATAL → **STOPPA** och be användaren fixa det.
Om något är ⚠️ WARNING → Fråga om de vill fortsätta ändå.

**STEG 2: REQUIREMENTS CHECK (om inte --skip-requirements)**

Kör requirements check LOKALT först (inte på VM):

```bash
# Hitta requirements.sh från template eller scripts
if [ -f ".ralph/scripts/requirements.sh" ]; then
  .ralph/scripts/requirements.sh --check
elif [ -f ".ralph/templates/stacks/react-supabase/scripts/requirements.sh" ]; then
  .ralph/templates/stacks/react-supabase/scripts/requirements.sh --check
else
  echo "No requirements.sh found, skipping"
fi
```

Om requirements FAILAR:
- Visa vad som saknas
- Ge instruktioner för manuell fix (speciellt auth)
- STOPPA deploy tills fixat

Om requirements OK → fortsätt till steg 3.

**STEG 3: KOLLA CODEX AUTH PÅ VM**

Kör via SSH för att kolla om Codex är autentiserad:
```bash
source ~/.ralph-vm
ssh $VM_USER@$VM_IP "codex --version 2>/dev/null && echo 'CODEX_OK' || echo 'CODEX_MISSING'"
```

Om `CODEX_MISSING` eller första gången:

Läs `.ralph/config.json` för att se `codex.auth_method`:

**Om `account`:**
```
⚠️  Codex behöver autentiseras på VM:en (första gången)

Kör följande:
  1. ssh $VM_USER@$VM_IP
  2. codex login
  3. Följ instruktionerna i browsern
  4. Kör /prompts:ralph-deploy igen

Detta behöver bara göras en gång per VM.
```
**STOPPA** och vänta på att användaren gör detta.

**Om `api_key`:**
```
⚠️  OPENAI_API_KEY behöver sättas på VM:en

Kör följande:
  1. ssh $VM_USER@$VM_IP
  2. echo 'export OPENAI_API_KEY="sk-..."' >> ~/.bashrc
  3. source ~/.bashrc
  4. Kör /prompts:ralph-deploy igen
```
**STOPPA** och vänta på att användaren gör detta.

Om Codex redan fungerar → fortsätt till steg 4.

**STEG 4: VÄLJ MODE**

Fråga användaren med AskUserQuestion:

```
Vilken mode vill du köra Ralph i?

1. Standard (E2E + auto-CR) - Recommended
   Kör specs med Playwright-tester, genererar auto-fix vid fel

2. Quick (bara build)
   Snabbaste - bara spec-körning och build verify

3. Inferno (allt + parallel)
   Full kraft - E2E, auto-CR, design review, parallel worktrees
```

Spara valet:
- Standard → `RALPH_FLAGS="--orchestrate"`
- Quick → `RALPH_FLAGS=""`
- Inferno → `RALPH_FLAGS="--orchestrate --parallel"`

**STEG 5: PUSHA TILL GITHUB**
```bash
git add -A
git commit -m "Deploy: $(date +%Y-%m-%d_%H:%M)" || true
git push origin main
```

**STEG 6: STARTA PÅ VM**

Använd RALPH_FLAGS från steg 3. Kör via SSH:
```bash
# Hämta VM-config
source ~/.ralph-vm

# SSH till VM och kör (RALPH_FLAGS sätts baserat på mode-val)
ssh $VM_USER@$VM_IP << EOF
  # Cleanup - döda gamla processer innan vi startar
  echo "Cleaning up old processes..."
  supabase stop 2>/dev/null || true
  pkill -f "vite|next|node.*dev" 2>/dev/null || true
  sleep 2

  cd ~/projects

  # Klona eller uppdatera repo
  REPO_NAME=\$(basename \$(git remote get-url origin 2>/dev/null || echo "project") .git)

  if [ -d "\$REPO_NAME" ]; then
    cd "\$REPO_NAME"
    git pull origin main
  else
    gh repo clone \$(git remote get-url origin) "\$REPO_NAME"
    cd "\$REPO_NAME"
  fi

  # Installera node_modules om saknas
  [ -f "package.json" ] && [ ! -d "node_modules" ] && npm install

  # Gör ralph körbar
  chmod +x ralph .ralph/scripts/*.sh 2>/dev/null || true

  # Starta Ralph med vald mode
  nohup ./.ralph/scripts/ralph.sh $RALPH_FLAGS > ralph-deploy.log 2>&1 &
  echo "Ralph startad med PID: \$! (mode: $RALPH_FLAGS)"
EOF
```

**MODES:**
- Standard: `--orchestrate` (E2E + auto-CR)
- Quick: (inga flaggor) - bara build verify
- Inferno: `--orchestrate --parallel` (allt)

**STEG 7: BEKRÄFTA**
Skriv ut:
```
✅ DEPLOY KLAR!

Ralph kör nu på VM: $VM_IP

Följ progress:
  - ntfy.sh (notifieringar)
  - ssh $VM_USER@$VM_IP 'tail -f ~/projects/REPO/ralph-deploy.log'

När klar:
  /prompts:ralph-review    # Öppna tunnlar och testa
```

**VIKTIGT:**
- Använd `gh repo clone` INTE `git clone` (hanterar auth)
- Kör ralph.sh i bakgrunden med nohup
- Ge användaren kommandon för att följa progress
