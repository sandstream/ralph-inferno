# /ralph:review - Review Ralph's work

Check if Ralph is done and review the results.

## Usage
```
/ralph:review
/ralph:review --tunnel   # Also open SSH tunnel for testing
```

## Instructions

**STEP 1: CHECK IF RALPH IS RUNNING**

```bash
ssh ralph@$(cat ~/.ralph-vm | grep VM_IP | cut -d= -f2) 'pgrep -f "ralph.sh|claude" && echo "RUNNING" || echo "NOT_RUNNING"'
```

If RUNNING:
```
⏳ Ralph is still running on VM!

Follow progress:
  ssh ralph@VM_IP 'tail -f ~/projects/REPO/ralph-deploy.log'

Come back when Ralph is done.
```
STOP HERE - don't give more options.

If NOT_RUNNING → continue to step 2.

**STEP 2: CHECK RESULTS**

```bash
# Get latest from VM
source ~/.ralph-vm
ssh $VM_USER@$VM_IP "cd ~/projects/$(basename $(git remote get-url origin) .git) && git log --oneline -10"
```

Show:
- Number of commits Ralph made
- Which specs were run

**STEP 3: PULL CHANGES**

```bash
git pull origin main
```

**STEP 4: LIST PRs (if any)**

```bash
gh pr list
```

**STEP 5: OPEN TUNNEL (if --tunnel)**

```bash
# Open SSH tunnel to test the app
ssh -L 5173:localhost:5173 -L 54321:localhost:54321 $VM_USER@$VM_IP
```

Show:
```
🔗 Tunnels open!
- App: http://localhost:5173
- Supabase: http://localhost:54321

Press Ctrl+C to close the tunnels.
```
