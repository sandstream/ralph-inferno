# Preflight Checklist

> ⚠️ Alla checkboxar MÅSTE vara ✅ innan /ralph:deploy körs
> Genererad från PRD av Ralph Inferno

---

## Accounts Required

| Service | Status | Signup URL |
|---------|--------|------------|
| [ ] {Service 1} | ❌ Not created | {url} |
| [ ] {Service 2} | ❌ Not created | {url} |

---

## API Keys Needed

Lägg till dessa i `.env` på VM:

```bash
# Required
{SERVICE1_API_KEY}=
{SERVICE2_SECRET}=

# Supabase (om används)
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

| Variable | Service | How to get |
|----------|---------|------------|
| [ ] `{VAR1}` | {service} | {instruktion} |
| [ ] `{VAR2}` | {service} | {instruktion} |

---

## Environment Setup

### VM
- [ ] VM provisioned and running
- [ ] SSH access verified: `ssh ralph@{VM_IP}`
- [ ] Git installed and configured
- [ ] Node.js 18+ installed
- [ ] Codex or Claude CLI installed

### GitHub
- [ ] Repository created: `github.com/{user}/{repo}`
- [ ] SSH key added to GitHub
- [ ] Can push/pull from VM

### Local
- [ ] `.ralph/config.json` configured
- [ ] VM IP set in config

---

## Manual Setup Steps

> Dessa steg kan inte automatiseras och måste göras manuellt

### Webhooks
- [ ] {Service} webhook URL configured: `https://{domain}/api/webhooks/{service}`
- [ ] Webhook secret saved to `.env`

### OAuth / Redirect URLs
- [ ] {Provider} redirect URL set to: `{url}`

### DNS (if applicable)
- [ ] Domain pointing to correct IP
- [ ] SSL certificate configured

### Test Data (if needed)
- [ ] Test account created in {service}
- [ ] Sample data uploaded

---

## Verification Commands

Run these to verify setup:

```bash
# Test SSH to VM
ssh ralph@{VM_IP} "echo 'SSH OK'"

# Test GitHub access from VM
ssh ralph@{VM_IP} "gh auth status"

# Test API key (example)
curl -H "Authorization: Bearer $API_KEY" https://api.service.com/health
```

---

## Cost Estimate

| Service | Plan | Monthly Cost |
|---------|------|--------------|
| {service} | {plan} | ${amount} |
| **Total** | | **${total}** |

---

## Sign-off

- [ ] All accounts created
- [ ] All API keys obtained and added to .env
- [ ] VM environment ready
- [ ] Webhooks configured
- [ ] Manual steps completed
- [ ] Verification commands passed

```
STATUS: [ ] READY FOR DEV
```

---

**När allt är klart, kör:**
```bash
/ralph:deploy
```
