# 🔥 Quickstart

Get from idea to autonomous builds in 5 minutes.

## Prerequisites

- Node.js 18+
- Claude Code (`npm i -g @anthropic-ai/claude-code`) or Codex CLI (`npm i -g @openai/codex`)
- A VM you can SSH into (Hetzner, DigitalOcean, whatever)

## Install

```bash
cd your-project
npx ralph-inferno install
```

## VM Setup (one-time)

SSH into your VM and run:
```bash
npm i -g @anthropic-ai/claude-code   # or @openai/codex
claude login                          # or codex login
gh auth login
npx playwright install-deps && npx playwright install
```

## Build Something

### New App (Greenfield)
```bash
claude                    # Start Claude Code
/ralph:idea "saas app"    # Brainstorm → PROJECT-BRIEF.md
/ralph:discover           # Research → PRD.md
/ralph:plan               # Specs
/ralph:deploy             # 🚀 Send to VM, go to sleep
```

### Change Existing App (Brownfield)
```bash
claude
/ralph:change-request "add dark mode"    # Analyze → specs
/ralph:plan
/ralph:deploy             # 🚀
```

### Next Morning
```bash
/ralph:review             # See what Ralph built
```

## That's It

Ralph handles the grunt work. You handle the vision.

📚 Full docs: [README.md](./README.md) | 🏗️ [Architecture](./docs/ARCHITECTURE.md)
