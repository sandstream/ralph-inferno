# /prompts:ralph-preflight - Verify Requirements Before Dev

Generera och verifiera preflight checklist innan development startar.

## Usage
```
/prompts:ralph-preflight
/prompts:ralph-preflight --check    # Verifiera befintlig PREFLIGHT.md
```

## Prerequisites
- `docs/PRD.md` måste finnas (kör `/prompts:ralph-idea` eller `/prompts:ralph-discover` först)

## Instructions

**STEG 1: LÄS PRD**

Läs `docs/PRD.md` och identifiera:
1. Alla externa integrationer
2. Alla API:er som behövs
3. Teknisk stack och hosting
4. Compliance-krav

**STEG 2: GENERERA PREFLIGHT.md**

Baserat på PRD, skapa `docs/PREFLIGHT.md` med:

1. **Accounts Required**
   - Lista alla externa tjänster
   - Inkludera signup-URLs

2. **API Keys Needed**
   - Lista alla miljövariabler
   - Instruktioner för hur man får dem

3. **Environment Setup**
   - VM requirements
   - GitHub setup
   - Local config

4. **Manual Setup Steps**
   - Webhooks som behöver konfigureras
   - OAuth redirect URLs
   - DNS om det behövs

5. **Cost Estimate**
   - Månadskostnad per tjänst

**STEG 3: VISA FÖR ANVÄNDAREN**

Presentera checklistan och be användaren bekräfta varje punkt:

```
📋 PREFLIGHT CHECKLIST

Följande måste vara klart innan Ralph kan bygga:

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

Är allt ovan klart? (ja/nej)
```

**STEG 4: GATE CHECK**

Om användaren svarar "ja":
```
✅ PREFLIGHT COMPLETE

docs/PREFLIGHT.md uppdaterad med STATUS: READY FOR DEV

Nästa steg:
  /prompts:ralph-plan    - Skapa specs
  /prompts:ralph-deploy  - Starta bygget
```

Om användaren svarar "nej":
```
⚠️ PREFLIGHT INCOMPLETE

Vänligen slutför följande innan du fortsätter:
{lista saknade items}

Kör /prompts:ralph-preflight --check när du är klar.
```

**VIKTIGT:**
- STOPPA INTE om preflight inte är klar
- Användaren måste aktivt bekräfta
- `/prompts:ralph-deploy` ska vägra köra om PREFLIGHT inte är READY
