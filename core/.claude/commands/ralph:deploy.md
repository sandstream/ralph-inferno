# /ralph:deploy - Deploy to VM via GitHub

Push project to GitHub and start Ralph on VM.

## Usage
```
/ralph:deploy
/ralph:deploy --overnight   # Shut down VM when done
/ralph:deploy --skip-requirements  # Skip requirements check
```

## Prerequisites
- IMPLEMENTATION_PLAN.md or .ralph-.ralph-specs/*.md must exist
- VM must be configured (~/.ralph-vm)
- GitHub repo must exist

## Instructions

You are a deployment assistant. Run these steps:

**STEP 1: CHECK CLAUDE AUTH**

First, verify Claude is authenticated:

```bash
echo "=== CHECKING CLAUDE AUTH ==="
if claude --version > /dev/null 2>&1; then
    echo "✅ Claude CLI installed"
else
    echo "❌ FATAL: Claude CLI not found"
    echo "   Install with: npm i -g @anthropic-ai/claude-code"
    exit 1
fi

# Quick auth test
if claude --print-system-prompt > /dev/null 2>&1; then
    echo "✅ Claude authenticated"
else
    echo "❌ FATAL: Claude not authenticated"
    echo ""
    echo "   Fix with ONE of these:"
    echo "   1. claude login (if you have Max subscription)"
    echo "   2. export ANTHROPIC_API_KEY='sk-ant-...'"
    echo ""
    exit 1
fi
```

If auth fails → **STOP** and show fix instructions.

---

**STEP 2: VALIDATE PROJECT**

Run this validation and STOP if anything is missing:

```bash
echo "=== PRE-DEPLOY VALIDATION ==="

# 1. Specs must exist
SPEC_COUNT=$(ls -1 .ralph-.ralph-specs/*.md 2>/dev/null | grep -v "CR-" | wc -l | tr -d ' ')
if [ "$SPEC_COUNT" -eq 0 ]; then
    echo "❌ FATAL: No specs found in .ralph-.ralph-specs/"
    echo "   Run /ralph:plan first to generate specs"
    exit 1
fi
echo "✅ Found $SPEC_COUNT specs"

# 2. PRD should exist
if [ ! -f "docs/PRD.md" ] && [ ! -f "docs/prd.md" ]; then
    echo "⚠️  WARNING: No PRD found in docs/"
    echo "   Recommended: Run /ralph:discover first"
fi

# 3. CLAUDE.md should exist
if [ ! -f "CLAUDE.md" ]; then
    echo "⚠️  WARNING: No CLAUDE.md found"
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

If anything is ❌ FATAL → **STOP** and ask the user to fix it.
If anything is ⚠️ WARNING → Ask if they want to continue anyway.

**STEP 3: REQUIREMENTS CHECK (unless --skip-requirements)**

Run requirements check LOCALLY first (not on VM):

```bash
# Find requirements.sh from template or scripts
if [ -f ".ralph/scripts/requirements.sh" ]; then
  .ralph/scripts/requirements.sh --check
elif [ -f ".ralph/templates/stacks/react-supabase/scripts/requirements.sh" ]; then
  .ralph/templates/stacks/react-supabase/scripts/requirements.sh --check
else
  echo "No requirements.sh found, skipping"
fi
```

If requirements FAIL:
- Show what's missing
- Give instructions for manual fix (especially auth)
- STOP deploy until fixed

If requirements OK → continue to step 3.

**STEP 4: CHECK CLAUDE AUTH ON VM**

Run via SSH to check if Claude is authenticated:
```bash
source ~/.ralph-vm
ssh $VM_USER@$VM_IP "claude --version 2>/dev/null && echo 'CLAUDE_OK' || echo 'CLAUDE_MISSING'"
```

If `CLAUDE_MISSING` or first time:

Read `.ralph/config.json` to see `claude.auth_method`:

**If `subscription`:**
```
⚠️  Claude needs to be authenticated on the VM (first time)

Run the following:
  1. ssh $VM_USER@$VM_IP
  2. claude login
  3. Follow the instructions in the browser
  4. Run /ralph:deploy again

This only needs to be done once per VM.
```
**STOP** and wait for the user to do this.

**If `api_key`:**
```
⚠️  ANTHROPIC_API_KEY needs to be set on the VM

Run the following:
  1. ssh $VM_USER@$VM_IP
  2. echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
  3. source ~/.bashrc
  4. Run /ralph:deploy again
```
**STOP** and wait for the user to do this.

If Claude already works → continue to step 4.

**STEP 5: CHOOSE MODE**

Ask the user with AskUserQuestion:

```
Which mode do you want to run Ralph in?

1. Standard (E2E + auto-CR) - Recommended
   Runs specs with Playwright tests, generates auto-fix on errors

2. Quick (build only)
   Fastest - just spec execution and build verify

3. Inferno (everything + parallel)
   Full power - E2E, auto-CR, design review, parallel worktrees
```

Save the choice:
- Standard → `RALPH_FLAGS="--orchestrate"`
- Quick → `RALPH_FLAGS=""`
- Inferno → `RALPH_FLAGS="--orchestrate --parallel"`

**STEP 6: PUSH TO GITHUB**
```bash
git add -A
git commit -m "Deploy: $(date +%Y-%m-%d_%H:%M)" || true
git push origin main
```

**STEP 7: START ON VM**

Use RALPH_FLAGS from step 3. Run via SSH:
```bash
# Get VM config
source ~/.ralph-vm

# SSH to VM and run (RALPH_FLAGS set based on mode selection)
ssh $VM_USER@$VM_IP << EOF
  # Cleanup - kill old processes before starting
  echo "Cleaning up old processes..."
  supabase stop 2>/dev/null || true
  pkill -f "vite|next|node.*dev" 2>/dev/null || true
  sleep 2

  cd ~/projects

  # Clone or update repo
  REPO_NAME=\$(basename \$(git remote get-url origin 2>/dev/null || echo "project") .git)

  if [ -d "\$REPO_NAME" ]; then
    cd "\$REPO_NAME"
    git pull origin main
  else
    gh repo clone \$(git remote get-url origin) "\$REPO_NAME"
    cd "\$REPO_NAME"
  fi

  # Install node_modules if missing
  [ -f "package.json" ] && [ ! -d "node_modules" ] && npm install

  # Make ralph executable
  chmod +x ralph .ralph/scripts/*.sh 2>/dev/null || true

  # Start Ralph with selected mode
  nohup ./.ralph/scripts/ralph.sh $RALPH_FLAGS > ralph-deploy.log 2>&1 &
  echo "Ralph started with PID: \$! (mode: $RALPH_FLAGS)"
EOF
```

**MODES:**
- Standard: `--orchestrate` (E2E + auto-CR)
- Quick: (no flags) - just build verify
- Inferno: `--orchestrate --parallel` (everything)

**STEP 8: CONFIRM**
Print:
```
✅ DEPLOY COMPLETE!

Ralph is now running on VM: $VM_IP

Follow progress:
  - ntfy.sh (notifications)
  - ssh $VM_USER@$VM_IP 'tail -f ~/projects/REPO/ralph-deploy.log'

When done:
  /ralph:review    # Open tunnels and test
```

**IMPORTANT:**
- Use `gh repo clone` NOT `git clone` (handles auth)
- Run ralph.sh in background with nohup
- Give user commands to follow progress
