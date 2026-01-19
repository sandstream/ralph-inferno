# /ralph:review - Review Ralph's work

Check if Ralph is done and review the results.

## Usage
```
/ralph:review
/ralph:review --tunnel   # Also open SSH tunnel for testing
```

## Language Setting

**FIRST: Detect language automatically**
```bash
LANG=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
echo "Language: ${LANG:-en}"
```

Use the detected language for user-facing output.

## Instructions

**STEP 1: LOAD CONFIG**

```bash
VM_IP=$(grep -o '"vm_ip"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
VM_USER=$(grep -o '"user"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
VM_USER="${VM_USER:-ubuntu}"
echo "VM: $VM_USER@$VM_IP"
```

**STEP 2: CHECK IF RALPH IS RUNNING**

```bash
ssh $VM_USER@$VM_IP 'pgrep -f "ralph.sh|claude" && echo "RUNNING" || echo "NOT_RUNNING"'
```

If RUNNING:
```
Ralph is still running on VM!

Follow progress:
  ssh VM_USER@VM_IP 'tail -f ~/projects/REPO/ralph-deploy.log'

Come back when Ralph is done.
```
STOP HERE - don't give more options.

If NOT_RUNNING -> continue to step 3.

**STEP 3: CHECK RESULTS**

```bash
ssh $VM_USER@$VM_IP "cd ~/projects/$(basename $(git remote get-url origin) .git) && git log --oneline -10"
```

Show:
- Number of commits Ralph made
- Which specs were run

**STEP 4: PULL CHANGES**

```bash
git pull origin main
```

**STEP 5: LIST PRs (if any)**

```bash
gh pr list
```

**STEP 6: OPEN TUNNEL (if --tunnel)**

```bash
# Open SSH tunnel to test the app
ssh -L 5173:localhost:5173 -L 54321:localhost:54321 $VM_USER@$VM_IP
```

Show:
```
Tunnels open!
- App: http://localhost:5173
- Supabase: http://localhost:54321

Press Ctrl+C to close tunnels.
```
