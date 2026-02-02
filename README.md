# 🔥 Ralph Inferno

> **🚨 DEPRECATED:** This project has been superseded by [Symbiont](https://github.com/sandstream/symbiont). See [DEPRECATED.md](./DEPRECATED.md) for migration details.

```
🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
🔥                                              🔥
🔥  ██████╗  █████╗ ██╗     ██████╗ ██╗  ██╗    🔥
🔥  ██╔══██╗██╔══██╗██║     ██╔══██╗██║  ██║    🔥
🔥  ██████╔╝███████║██║     ██████╔╝███████║    🔥
🔥  ██╔══██╗██╔══██║██║     ██╔═══╝ ██╔══██║    🔥
🔥  ██║  ██║██║  ██║███████╗██║     ██║  ██║    🔥
🔥  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝    🔥
🔥                                              🔥
🔥          I N F E R N O   M O D E             🔥
🔥                                              🔥
🔥  Build while you sleep. Wake to working code 🔥
🔥                   🌙 → ☀️                     🔥
🔥                                              🔥
🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
```

> **Light the fire. Walk away.**
>
> Ralph runs autonomously on a VM while you do literally anything else.
> Come back when it's done. Or don't. Ralph doesn't care.

AI-driven autonomous development workflow.

## How It Works

Ralph installs as **Claude Code commands** and **Codex CLI prompts**. When you run `npx ralph-inferno install`, it creates a `.ralph/` folder with scripts, syncs `.claude/commands/` for Claude Code, and syncs `~/.codex/prompts/` for Codex CLI.

```
Local Machine                               VM (Sandbox)
┌──────────────────────────┐              ┌─────────────────┐
│ Claude Code or Codex CLI │              │ Agent CLI       │
│ + Ralph commands/prompts │     GitHub   │ + ralph.sh      │
│                          │ ───────────► │                 │
│ /ralph:* or /prompts:*   │              │ Runs specs      │
└──────────────────────────┘              └─────────────────┘
```

**The flow:**
1. You work locally with Claude Code (`/ralph:*`) or Codex CLI (`/prompts:ralph-*`)
2. Deploy pushes your specs to GitHub and starts Ralph on the VM
3. Ralph runs autonomously on the VM while you sleep
4. Next day: review what was built

## Requirements

### Local Machine

| Tool | Required | How to install |
|------|----------|----------------|
| Node.js | Yes | `brew install node` |
| Claude Code | Yes (choose one) | `npm install -g @anthropic-ai/claude-code` |
| Codex CLI | Yes (choose one) | `npm install -g @openai/codex` |
| GitHub CLI | Recommended | `brew install gh` then `gh auth login` |

### VM (Sandbox)

| Tool | Required | Notes |
|------|----------|-------|
| SSH access | Yes | You need to be able to SSH into the VM |
| Git | Yes | Usually pre-installed |
| Claude Code | Yes (choose one) | `npm install -g @anthropic-ai/claude-code` |
| Claude auth | Yes (if using Claude) | See [Authentication](#authentication) below |
| Codex CLI | Yes (choose one) | `npm install -g @openai/codex` |
| Codex auth | Yes (if using Codex) | Run `codex login` OR set `OPENAI_API_KEY` |
| GitHub CLI | Yes | `brew install gh` then `gh auth login` |

**Important:** Both machines need `gh auth login` for Git operations to work!

### Optional

- **Codex web search** - Run Codex with `--search` (or enable it in Codex config) for `/prompts:ralph-discover`.
- **Claude Chrome Extension** - Lets Claude browse websites during `/ralph:discover`.
- If browsing isn’t available, use the `dev-browser` skill as a fallback.
- Cloud CLI (`hcloud`, `gcloud`, `doctl`, `aws`) - For VM management
- [ntfy.sh](https://ntfy.sh) - Push notifications when Ralph finishes

## Installation

### Step 1: Install Ralph locally

```bash
cd your-project
npx ralph-inferno install
```

This creates:
- `.ralph/` - Scripts and config
- `.claude/commands/` - Claude Code commands
- `~/.codex/prompts/` - Codex prompt files

### Step 2: Set up your VM

SSH into your VM and install the prerequisites:

```bash
# Install Node.js (if not installed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Claude Code (if using Claude)
npm install -g @anthropic-ai/claude-code

# Install Codex CLI (if using Codex)
npm install -g @openai/codex

# Authenticate Claude - see Authentication section below
claude login                    # Simplest option for Pro/Max subscribers

# Authenticate Codex (if using Codex):
codex login                      # If you prefer browser-based login
# OR
export OPENAI_API_KEY="sk-..."   # If using API key

# Install and authenticate GitHub CLI
sudo apt-get install gh
gh auth login

# Install Playwright dependencies (for E2E tests)
npx playwright install-deps
npx playwright install
```

### Step 3: Verify setup

On your local machine, start your CLI:

Claude Code:
```bash
claude
```
Then run:
- `/ralph:discover`
- `/ralph:plan`
- `/ralph:deploy`

Codex CLI:
```bash
codex
```
Then run:
- `/prompts:ralph-discover`
- `/prompts:ralph-plan`
- `/prompts:ralph-deploy`

## Authentication

Claude Code supports multiple authentication methods. Set these on your **VM** (not local machine):

### Option 1: Claude Subscription (Simplest)
```bash
claude login
```

### Option 2: Anthropic API Key
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

### Option 3: AWS Bedrock
```bash
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_MODEL="us.anthropic.claude-sonnet-4-20250514-v1:0"
export AWS_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### Option 4: Azure AI Foundry
```bash
export CLAUDE_CODE_USE_FOUNDRY=1
export ANTHROPIC_FOUNDRY_BASE_URL="https://your-resource.services.ai.azure.com/api/v1"
export ANTHROPIC_FOUNDRY_API_KEY="..."
export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
```

> **Tip:** Add these to `~/.bashrc` on your VM so they persist across sessions.

## Update

Update core files while preserving your config:

```bash
npx ralph-inferno update
```

Or use the command/prompt:
```
/ralph:update            # Claude Code
/prompts:ralph-update    # Codex CLI
```

## Workflow

Ralph supports two entry points: **Greenfield** (new apps) and **Brownfield** (existing apps).

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        TWO ENTRY POINTS                                      │
└─────────────────────────────────────────────────────────────────────────────┘

   GREENFIELD (new app)                    BROWNFIELD (existing app)
         │                                          │
         ▼                                          ▼
   /ralph:idea ──────────────────────────► /ralph:change-request
   (BMAD Brainstorm)                       (Analyze scope: S/M/L)
         │                                          │
         ▼                                          │
   PROJECT-BRIEF.md                                 │
         │                                          │
         ▼                                          │
   /ralph:discover                                  │
   (BMAD Analyst)                                   │
         │                                          │
         ▼                                          ▼
      PRD.md ─────────────────────────► CHANGE-REQUEST.md
                            │
                            ▼
                      /ralph:plan
                      (auto-detects input)
                            │
                            ▼
                      /ralph:deploy → VM → /ralph:review
```

Codex CLI equivalents use `/prompts:ralph-*` (see table below).
```

### Commands / Prompts
| Claude Code | Codex CLI | Description |
|-------------|-----------|-------------|
| `/ralph:idea` | `/prompts:ralph-idea` | **Greenfield start** - BMAD brainstorm → PROJECT-BRIEF.md |
| `/ralph:discover` | `/prompts:ralph-discover` | BMAD analyst mode → PRD.md |
| `/ralph:change-request` | `/prompts:ralph-change-request` | **Brownfield start** - Analyze changes → CR specs |
| `/ralph:plan` | `/prompts:ralph-plan` | Creates specs from PRD or Change Request |
| `/ralph:preflight` | `/prompts:ralph-preflight` | Verify requirements before deployment |
| `/ralph:deploy` | `/prompts:ralph-deploy` | Push to GitHub, choose mode, start Ralph on VM |
| `/ralph:review` | `/prompts:ralph-review` | Open SSH tunnels, test the app |
| `/ralph:status` | `/prompts:ralph-status` | Check Ralph's progress on VM |
| `/ralph:abort` | `/prompts:ralph-abort` | Stop Ralph on VM |
| `/ralph:update` | `/prompts:ralph-update` | Update Ralph to latest version |

### Deploy Modes

When running deploy (`/ralph:deploy` or `/prompts:ralph-deploy`), you choose a mode:

| Mode | What it does |
|------|--------------|
| **Quick** | Spec execution + build verify only |
| **Standard** | + Playwright E2E tests + auto-CR generation |
| **Inferno** | + Design review + parallel worktrees |

### Tips for Best Results

**Discovery mode works best when the agent can browse the web.**

- Codex CLI: use web search (`--search` or enable it in config)
- Claude Code: use the Claude Chrome Extension
- Otherwise: use the `dev-browser` skill as a fallback

### Example: New App (Greenfield)

```bash
# 1. Install Ralph
npx ralph-inferno install

# 2. Brainstorm & Discover
/ralph:idea "todo app"      # BMAD brainstorm → PROJECT-BRIEF.md
/ralph:discover             # BMAD analyst → PRD.md

# 3. Plan & Deploy
/ralph:plan                 # Generate specs
/ralph:deploy               # Send to VM

# 4. Review
/ralph:review               # Test what Ralph built

# Codex CLI equivalents
/prompts:ralph-idea "todo app"
/prompts:ralph-discover
/prompts:ralph-plan
/prompts:ralph-deploy
/prompts:ralph-review
```

### Example: Existing App (Brownfield)

```bash
# 1. Describe changes
/ralph:change-request "add dark mode"   # Analyze scope → CR specs

# 2. Plan & Deploy
/ralph:plan                 # Auto-detects Change Request
/ralph:deploy               # Send to VM

# 3. Review
/ralph:review               # Test the changes

# Codex CLI equivalents
/prompts:ralph-change-request "add dark mode"
/prompts:ralph-plan
/prompts:ralph-deploy
/prompts:ralph-review
```

## Language Agnostic

Ralph auto-detects your project type and uses the appropriate build/test commands:

| Project Type | Build Command | Test Command |
|--------------|---------------|--------------|
| Node.js (package.json) | `npm run build` | `npm test` |
| Rust (Cargo.toml) | `cargo build` | `cargo test` |
| Go (go.mod) | `go build ./...` | `go test ./...` |
| Python (pyproject.toml) | `python -m build` | `pytest` |
| Makefile | `make build` | `make test` |

**Custom commands:** Override in `.ralph/config.json`:
```json
{
  "build_cmd": "yarn build",
  "test_cmd": "yarn test:ci"
}
```

Set `agent` to `claude` or `codex` (or `auto` to use whatever is installed on the VM).

## Safety

Ralph runs AI-generated code autonomously. For safety:

- **ALWAYS run on a disposable VM** - never on your local machine
- Review generated code before production
- Never store credentials in code

## Cloud Providers

Ralph supports multiple cloud providers for VM execution:

| Provider | CLI | Notes |
|----------|-----|-------|
| Hetzner | `hcloud` | Cheapest, great for Europe |
| Google Cloud | `gcloud` | Good free tier |
| DigitalOcean | `doctl` | Simple and reliable |
| AWS | `aws` | Enterprise option |
| SSH | - | Use your own server |

## Config File

Configuration is stored in `.ralph/config.json`:

```json
{
  "version": "1.0.9",
  "language": "en",
  "provider": "hcloud",
  "vm_name": "ralph-sandbox",
  "region": "fsn1",
  "github": {
    "username": "your-username"
  },
  "agent": "claude",
  "claude": {
    "auth_method": "subscription"
  },
  "codex": {
    "auth_method": "account"
  },
  "notifications": {
    "ntfy_enabled": true,
    "ntfy_topic": "my-unique-ralph-topic"
  },
  "build_cmd": "npm run build",
  "test_cmd": "npm test"
}
```

**Auth method options:**
| Value | Description |
|-------|-------------|
| `subscription` | Uses `claude login` (Pro/Max subscription) |
| `api_key` | Uses `ANTHROPIC_API_KEY` env var |
| `bedrock` | Uses AWS Bedrock env vars |
| `foundry` | Uses Azure AI Foundry env vars |

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System overview and memory model
- [CLI Flags](docs/CLI-FLAGS.md) - All ralph.sh options
- [Token Optimization](docs/TOKEN-OPTIMIZATION.md) - Cost-saving strategies

## Credits & Inspiration

Ralph Inferno builds on ideas from:

- [snarktank/ralph](https://github.com/snarktank/ralph) - Ryan Carson's original Ralph concept
- [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) - The discovery workflow (`/ralph:idea` and `/ralph:discover`) is heavily inspired by BMAD's Brainstorm and Analyst personas
- [how-to-build-a-coding-agent](https://github.com/ghuntley/how-to-build-a-coding-agent) - Geoffrey Huntley's agent patterns
- [claude-ralph](https://github.com/RobinOppenstam/claude-ralph) - Robin Oppenstam's implementation

## License

MIT
