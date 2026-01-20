# Token Optimization

Ralph is designed to be cost-efficient with Claude or Codex API tokens.

## Strategies

### 1. Fresh Context Per Spec

Each spec runs in a fresh agent session. This prevents context bloat.

```
Spec 1: [fresh context] → build → done
Spec 2: [fresh context] → build → done
```

### 2. Error-Only Output

Build and test output is filtered to show only errors:

```bash
# In lib/verify.sh
echo "$output" | grep -E "(error|Error|ERROR|FAIL|failed|Failed|✗|❌)" | head -20
```

This saves tokens by not showing successful test output.

### 3. Silent Git Operations

Git commit and push output is suppressed:

```bash
git commit -m "$message" >/dev/null 2>&1 || true
git push origin "$branch" >/dev/null 2>&1 || true
```

### 4. Minimal Spec Files

Specs should be concise:

```markdown
# Epic: Auth

## Tasks
- [ ] Login form
- [ ] Register form
- [ ] Protected routes

## Acceptance
- User can login
- User can register
- Unauthenticated users redirected to login
```

### 5. English Language

Using English for all prompts and output reduces token usage compared to other languages (fewer tokens per word).

## Monitoring Token Usage

Check the log for token estimates:

```bash
[20:52:08] === 01-project-setup ===
[20:52:09] Tokens: ~249
```

## Cost Comparison

| Mode | Tokens/Spec (avg) | Notes |
|------|-------------------|-------|
| Clean | ~500 | Recommended |
| Full | ~1500 | More features |

## Tips

1. Keep specs small (5-10 tasks each)
2. Use English for prompts
3. Don't include large code blocks in specs
4. Let Ralph read files rather than embedding content
