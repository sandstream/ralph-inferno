# /ralph:preflight - Verify Requirements Before Dev

Generate and verify preflight checklist before development starts.

## Usage
```
/ralph:preflight
/ralph:preflight --check    # Verify existing PREFLIGHT.md
```

## Prerequisites
- `docs/PRD.md` must exist (run `/ralph:idea` or `/ralph:discover` first)

## Instructions

**STEP 1: READ PRD**

Read `docs/PRD.md` and identify:
1. All external integrations
2. All APIs needed
3. Technical stack and hosting
4. Compliance requirements

**STEP 2: GENERATE PREFLIGHT.md**

Based on PRD, create `docs/PREFLIGHT.md` with:

1. **Accounts Required**
   - List all external services
   - Include signup URLs

2. **API Keys Needed**
   - List all environment variables
   - Instructions for how to get them

3. **Environment Setup**
   - VM requirements
   - GitHub setup
   - Local config

4. **Manual Setup Steps**
   - Webhooks that need configuration
   - OAuth redirect URLs
   - DNS if needed

5. **Cost Estimate**
   - Monthly cost per service

**STEP 3: SHOW TO USER**

Present the checklist and ask the user to confirm each item:

```
📋 PREFLIGHT CHECKLIST

The following must be ready before Ralph can build:

ACCOUNTS:
  [ ] Stripe test account
  [ ] Printful developer account
  [ ] Supabase project

API KEYS:
  [ ] STRIPE_SECRET_KEY
  [ ] PRINTFUL_API_KEY
  [ ] SUPABASE_URL
  [ ] SUPABASE_ANON_KEY

MANUAL SETUP:
  [ ] Stripe webhook URL configured
  [ ] Test products in Printful

---

Is everything above ready? (yes/no)
```

**STEP 4: GATE CHECK**

If the user answers "yes":
```
✅ PREFLIGHT COMPLETE

docs/PREFLIGHT.md updated with STATUS: READY FOR DEV

Next steps:
  /ralph:plan    - Create specs
  /ralph:deploy  - Start the build
```

If the user answers "no":
```
⚠️ PREFLIGHT INCOMPLETE

Please complete the following before continuing:
{list missing items}

Run /ralph:preflight --check when you're done.
```

**IMPORTANT:**
- DO NOT STOP if preflight is not complete
- The user must actively confirm
- `/ralph:deploy` should refuse to run if PREFLIGHT is not READY
