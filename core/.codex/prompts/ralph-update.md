# /prompts:ralph-update - Check and update Ralph

Check for updates and optionally update Ralph to the latest version.

## Instructions

**STEG 1: KOLLA VERSIONER**

```bash
CURRENT=$(cat .ralph/version 2>/dev/null || echo "unknown")
LATEST=$(npm view ralph-inferno version 2>/dev/null || echo "unknown")
echo "Current: $CURRENT"
echo "Latest:  $LATEST"
```

**STEG 2: JÄMFÖR**

Om CURRENT == LATEST:
```
✅ Ralph is up to date (v$CURRENT)
```
KLAR.

Om CURRENT != LATEST:
```
💡 Update available: v$CURRENT → v$LATEST
```

**STEG 3: FRÅGA**

Fråga användaren med AskUserQuestion:
```
Vill du uppdatera Ralph?

1. Yes, update now
2. No, skip for now
```

**STEG 4: UPPDATERA (om ja)**

```bash
npx ralph-inferno update
```

Visa resultat:
```
✅ Ralph updated to v$LATEST

Changes will take effect in new sessions.
```
