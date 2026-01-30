---
mode: agent
description: Build the project by executing all specs
---

# Ralph Deploy - Execute Specs

Build the project by executing each spec in order.

## Prerequisites

- `.ralph-specs/*.md` must exist (run `/prompt:ralph-plan` first)

## Instructions

1. **Check Auth**: Verify you can access files and run commands

2. **Execute Specs**: For each spec in `.ralph-specs/`:
   - Read the spec
   - Implement the requirements
   - Run tests if applicable
   - Mark as complete

3. **Progress Output**: Before each spec, print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Spec 1/10: PROJECT SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

4. **Build & Test**: After all specs:
   - Run `npm run build`
   - Run `npm test` if tests exist
   - Fix any issues

## When Done

```
✅ DEPLOY_COMPLETE

Results:
- Specs completed: {count}/{total}
- Build: ✅ Passing
- Tests: ✅ Passing

The project is ready! Review the code and deploy when satisfied.
```

## Error Handling

If a spec fails:
1. Show the error
2. Attempt to fix
3. If still failing, ask user for guidance
