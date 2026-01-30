---
mode: agent
description: Verify all requirements before building
---

# Ralph Preflight - Verify Requirements

Check that all external services and API keys are ready before building.

## Prerequisites

- `docs/PRD.md` must exist

## Instructions

1. Read `docs/PRD.md`
2. Identify all external dependencies (Supabase, Stripe, etc.)
3. Create `docs/PREFLIGHT.md` checklist
4. Ask user to confirm each item

## Checklist Format

```markdown
# Preflight Checklist

## Status: ⏳ PENDING

## Accounts Required
- [ ] {Service 1} - {signup URL}
- [ ] {Service 2} - {signup URL}

## API Keys / Environment Variables
- [ ] `{VAR_NAME}` - {how to get it}

## Manual Setup (if any)
- [ ] {Webhook configuration}
```

## When Done

If user confirms all ready:
```
✅ PREFLIGHT COMPLETE

Next steps:
  /prompt:ralph-deploy - Start building
```
