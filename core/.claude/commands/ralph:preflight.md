# /ralph:preflight - Verify Requirements Before Dev

Check that all external services and API keys are ready before building.

## Usage
```
/ralph:preflight
/ralph:preflight --check    # Re-verify existing PREFLIGHT.md
```

## Prerequisites
- `docs/PRD.md` must exist (run `/ralph:idea` first)

## Instructions

**STEP 1: READ PRD**

Read `docs/PRD.md` and identify:
1. All external services needed (Supabase, Stripe, etc.)
2. All API keys required
3. Any manual setup steps

**STEP 2: GENERATE CHECKLIST**

Based on PRD, create `docs/PREFLIGHT.md`:

```markdown
# Preflight Checklist

## Status: ⏳ PENDING

## Accounts Required
- [ ] {Service 1} - {signup URL}
- [ ] {Service 2} - {signup URL}

## API Keys / Environment Variables
- [ ] `{VAR_NAME}` - {how to get it}
- [ ] `{VAR_NAME}` - {how to get it}

## Manual Setup (if any)
- [ ] {Webhook configuration}
- [ ] {OAuth redirect URLs}

## Cost Estimate (monthly)
| Service | Free Tier | Paid |
|---------|-----------|------|
| {name} | {limit} | ${x}/mo |
```

**STEP 3: ASK USER TO VERIFY**

Present the checklist:

```
📋 PREFLIGHT CHECKLIST

Before Ralph can build, you need:

ACCOUNTS:
  [ ] Supabase project
  [ ] Stripe test account (if payments)

API KEYS (add to .env):
  [ ] VITE_SUPABASE_URL
  [ ] VITE_SUPABASE_ANON_KEY

Is everything above ready? (yes/no)
```

**STEP 4: UPDATE STATUS**

If user says "yes":
- Update PREFLIGHT.md status to `✅ READY`
- Print:
```
✅ PREFLIGHT COMPLETE

Next steps:
  /ralph:plan    - Create implementation specs
  /ralph:deploy  - Start building
```

If user says "no":
- List what's missing
- Print:
```
⚠️ PREFLIGHT INCOMPLETE

Complete the items above, then run /ralph:preflight --check
```

---

## START NOW

1. Read docs/PRD.md
2. Identify all external dependencies
3. Generate checklist
4. Ask user to confirm
