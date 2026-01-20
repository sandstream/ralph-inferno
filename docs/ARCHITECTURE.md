# Ralph Inferno - Architecture

> **Build while you sleep. Wake to working code.** 🌙 → ☀️

Ralph Inferno is a spec-first autonomous development workflow that runs Claude Code or Codex CLI on a VM while you're away.

---

## Core Principles

### 1. Spec-First Development
Every feature starts as a spec file. The agent (Claude or Codex) reads the spec, implements it, verifies it works, then moves to the next. Specs are the source of truth.

### 2. Two Entry Points
Ralph supports both greenfield (new apps) and brownfield (existing apps):

```
GREENFIELD                          BROWNFIELD
/ralph:idea                         /ralph:change-request
     ↓                                      ↓
PROJECT-BRIEF.md                    CHANGE-REQUEST.md
     ↓                                      ↓
/ralph:discover                             │
     ↓                                      │
  PRD.md ────────────────────────────────────
                      ↓
                /ralph:plan
                      ↓
               .ralph-specs/
                      ↓
                /ralph:deploy
                      ↓
                /ralph:review
```
Each phase has a dedicated Claude command or Codex prompt. You progress through phases linearly.

### 3. Three Execution Modes
Control how much verification happens on the VM:

| Mode | Flag | Build | E2E Tests | Design Review | Parallel |
|------|------|-------|-----------|---------------|----------|
| **Quick** | (none) | ✅ | ❌ | ❌ | ❌ |
| **Standard** | `--orchestrate` | ✅ | ✅ | ❌ | ❌ |
| **Inferno** | `--orchestrate --parallel` | ✅ | ✅ | ✅ | ✅ |

### 4. Self-Healing Loop
When tests fail, Ralph generates Change Request specs automatically and retries. The orchestrator loops until all specs pass or max iterations reached.

### 5. Centralized Config
All settings in `.ralph/config.json`. Scripts use `config-utils.sh` to read values with defaults.

### 6. Language Agnostic
Auto-detects project type (Node, Rust, Go, Python, Make) and uses appropriate build/test commands. Override in config if needed.

### 7. VM Isolation
Ralph runs on a disposable VM, never on your local machine. AI-generated code executes in a sandboxed environment.

### 8. Async Notifications
Push notifications via ntfy.sh when Ralph finishes or needs help. Check status without SSH.

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        TWO ENTRY POINTS                                      │
└─────────────────────────────────────────────────────────────────────────────┘

   GREENFIELD (new app)                    BROWNFIELD (existing app)
         │                                          │
         ▼                                          ▼
┌─────────────────┐                        ┌─────────────────────┐
│  /ralph:idea    │                        │ /ralph:change-      │
│  BMAD Brainstorm│                        │ request             │
│                 │                        │ (Analyze + Scope)   │
│ Output:         │                        │                     │
│ PROJECT-BRIEF.md│                        │ Output:             │
└────────┬────────┘                        │ CHANGE-REQUEST.md   │
         │                                 └──────────┬──────────┘
         ▼                                            │
┌─────────────────┐                                   │
│ /ralph:discover │                                   │
│ BMAD Analyst    │                                   │
│                 │                                   │
│ Output: PRD.md  │                                   │
└────────┬────────┘                                   │
         │                                            │
         └──────────────────┬─────────────────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │  /ralph:plan    │  ◄── Auto-detects input
                   │                 │      (PRD or Change Request)
                   │ Output: specs/* │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │  /ralph:deploy  │  ◄── Push to GitHub, start on VM
                   │                 │      Choose mode: Quick/Standard/Inferno
                   └────────┬────────┘
                            │
                            ▼
         ┌─────────────────────────────────────────────────────────┐
         │                     ON THE VM (AUTONOMOUS)               │
         │                                                          │
         │   ralph.sh runs specs → build → test → auto-fix → commit │
         │                                                          │
         └────────┬────────────────────────────────────────────────┘
                  │
                  ▼
         ┌─────────────────┐
         │  /ralph:review  │  ◄── Open tunnels, test the app
         └────────┬────────┘
                  │
                  ▼
         ┌─────────────────────┐
         │ /ralph:change-      │  ◄── If bugs found, generate CR specs
         │ request --bug       │      Then run /ralph:deploy again
         └─────────────────────┘
```

Codex CLI equivalents use `/prompts:ralph-*`.

---

## Execution Modes Comparison

| Feature | Quick | Standard | Inferno |
|---------|-------|----------|---------|
| Spec execution | ✅ | ✅ | ✅ |
| Build verification | ✅ | ✅ | ✅ |
| E2E tests (Playwright) | ❌ | ✅ | ✅ |
| Auto-CR generation | ❌ | ✅ | ✅ |
| Design review (screenshots) | ❌ | ❌ | ✅ |
| Parallel worktrees | ❌ | ❌ | ✅ |
| Loop protection | ✅ | ✅ | ✅ |
| ntfy notifications | ✅ | ✅ | ✅ |

---

## Architecture Components

### Commands & Prompts (10)

- Claude Code commands live in `.claude/commands/`
- Codex CLI prompts live in `~/.codex/prompts/`

| Claude Code | Codex CLI | Purpose |
|-------------|-----------|---------|
| `/ralph:idea` | `/prompts:ralph-idea` | **BMAD Brainstorm** - 8 techniques → PROJECT-BRIEF.md |
| `/ralph:discover` | `/prompts:ralph-discover` | **BMAD Analyst** - Research & validation → PRD.md |
| `/ralph:change-request` | `/prompts:ralph-change-request` | **Brownfield entry** - Analyze changes → CR specs |
| `/ralph:plan` | `/prompts:ralph-plan` | Generate specs from PRD or Change Request |
| `/ralph:preflight` | `/prompts:ralph-preflight` | Verify requirements before deployment |
| `/ralph:deploy` | `/prompts:ralph-deploy` | Push to GitHub, start Ralph on VM |
| `/ralph:status` | `/prompts:ralph-status` | Check Ralph's progress on VM |
| `/ralph:review` | `/prompts:ralph-review` | Open tunnels, test the built app |
| `/ralph:abort` | `/prompts:ralph-abort` | Stop Ralph on VM |
| `/ralph:update` | `/prompts:ralph-update` | Update Ralph to latest version |

### Core Scripts

Located in `.ralph/scripts/`:

| Script | Purpose |
|--------|---------|
| `ralph.sh` | Main entry point, runs specs sequentially |
| `orchestrator.sh` | Middle loop, retries failed specs |
| `vm-init.sh` | Initialize VM environment |

### Library Scripts

Located in `.ralph/lib/`:

| Script | Purpose |
|--------|---------|
| `config-utils.sh` | Load config values with defaults |
| `agent-utils.sh` | Agent selection + execution helpers |
| `spec-utils.sh` | Find next spec, mark done, checksums |
| `verify.sh` | Run build verification |
| `test-loop.sh` | E2E tests + CR generation + design review |
| `notify.sh` | ntfy.sh push notifications |
| `git-utils.sh` | Commit, push, safety checks |
| `tokens.sh` | Cost tracking |
| `rate-limit.sh` | Handle API rate limits |
| `parallel.sh` | Git worktree management |
| `selfheal.sh` | Auto-recovery from failures |
| `security.sh` | Security scanning |
| `merge.sh` | Merge completed work |
| `scaling.sh` | Multi-VM coordination |
| `summary.sh` | Generate progress summaries |

---

## Three Loops Model

```
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   OUTER LOOP     │    │   MIDDLE LOOP    │    │   INNER LOOP     │
│   (Your Machine) │ →  │   (Orchestrator) │ →  │   (Per Spec)     │
├──────────────────┤    ├──────────────────┤    ├──────────────────┤
│ /ralph:* or /prompts:*   │    │ ralph.sh         │    │ Agent runs spec │
│ discover/plan/deploy     │    │ --orchestrate    │    │ npm run build    │
│ review/change-request    │    │                  │    │ playwright test  │
│                          │    │ Retries specs    │    │ Auto-CR on fail  │
│                          │    │ until all pass   │    │ Design review    │
└──────────────────┘    └──────────────────┘    └──────────────────┘
       YOU                   VM (auto)              VM (auto)
```

### Inner Loop (per spec)

```bash
run_spec() {
    # 1. Agent runs spec (Claude or Codex)
    run_agent_prompt "$(cat "$spec")"

    # 2. Verify build
    npm run build || retry

    # 3. Run E2E tests (Standard/Inferno mode)
    npx playwright test || generate_cr && retry

    # 4. Design review (Inferno mode)
    take_screenshots
    run_agent_image "Check against design system" "$screenshot" || generate_design_cr && retry

    # 5. Commit & mark done
    git commit && mark_spec_done "$spec"
}
```

### Middle Loop (Orchestrator)

```bash
# orchestrator.sh
MAX_ITERATIONS=3

while [ $iteration -lt $MAX_ITERATIONS ]; do
    ralph.sh  # Run all specs

    if all_specs_done; then
        notify "✅ Complete!"
        exit 0
    fi

    ((iteration++))
done

notify "⚠️ Needs help"
```

---

## Config System

### config.json Structure

```json
{
  "version": "1.0.6",
  "language": "en",
  "provider": "hcloud",
  "vm_name": "ralph-sandbox",
  "vm_ip": "1.2.3.4",
  "user": "ubuntu",
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

### config-utils.sh Functions

| Function | Purpose |
|----------|---------|
| `load_config "key" "default"` | Load string value |
| `load_config_bool "key" "default"` | Load boolean value |
| `load_config_nested "parent" "key" "default"` | Load nested value |
| `get_build_cmd` | Get build command (auto-detect) |
| `get_test_cmd` | Get test command (auto-detect) |
| `get_github_username` | Get GitHub username |
| `get_vm_ip` | Get VM IP address |
| `is_ntfy_enabled` | Check if notifications enabled |

### Auto-Detection

When `build_cmd` or `test_cmd` not set, Ralph auto-detects:

| Project Type | Build | Test |
|--------------|-------|------|
| Node.js (package.json) | `npm run build` | `npm test` |
| Rust (Cargo.toml) | `cargo build` | `cargo test` |
| Go (go.mod) | `go build ./...` | `go test ./...` |
| Python (pyproject.toml) | `python -m build` | `pytest` |
| Makefile | `make build` | `make test` |

---

## Integration Points

### Local Machine

| Integration | Purpose |
|-------------|---------|
| Claude Code | Run slash commands, interact with Claude |
| Codex CLI | Run prompts, interact with Codex |
| Git | Version control, push specs |
| GitHub CLI (`gh`) | Create PRs, manage repos |
| SSH | Connect to VM |
| Cloud CLI | Create/manage VMs (hcloud, gcloud, etc.) |

### VM (Sandbox)

| Integration | Purpose |
|-------------|---------|
| Claude Code | Execute specs autonomously |
| Codex CLI | Execute specs autonomously |
| Git | Clone, commit, push |
| Build tools | npm, cargo, go, etc. |
| Playwright | E2E testing |
| GitHub CLI | Push commits, create branches |

### External Services

| Service | Purpose |
|---------|---------|
| GitHub | Code hosting, PR management |
| ntfy.sh | Push notifications |
| Cloud providers | VM provisioning |

---

## File Structure

```
.ralph/
├── config.json           # Project configuration
├── scripts/
│   ├── ralph.sh          # Main entry point
│   ├── orchestrator.sh   # Middle loop (--orchestrate)
│   └── vm-init.sh        # VM initialization
│
├── lib/
│   ├── config-utils.sh   # Config loading
│   ├── spec-utils.sh     # Spec management
│   ├── verify.sh         # Build verification
│   ├── test-loop.sh      # E2E + CR + design
│   ├── notify.sh         # Notifications
│   ├── git-utils.sh      # Git operations
│   ├── tokens.sh         # Cost tracking
│   ├── rate-limit.sh     # Rate limit handling
│   ├── parallel.sh       # Worktree management
│   ├── selfheal.sh       # Auto-recovery
│   ├── security.sh       # Security scanning
│   ├── merge.sh          # Merge operations
│   ├── scaling.sh        # Multi-VM scaling
│   └── summary.sh        # Progress summaries
│
├── templates/
│   ├── PROJECT-BRIEF-template.md  # Brainstorm output
│   ├── CHANGE-REQUEST-template.md # Brownfield changes
│   ├── PRD-template.md            # Product requirements
│   ├── SPEC-template.md           # Spec template
│   └── stacks/                    # Stack-specific templates
│
└── phases/               # Phase-specific configs

~/.codex/prompts/
├── ralph-discover.md       # Discovery prompt
├── ralph-plan.md           # Planning prompt
├── ralph-preflight.md      # Preflight checks
├── ralph-deploy.md         # Deployment prompt
├── ralph-status.md         # Status check
├── ralph-review.md         # Review prompt
├── ralph-change-request.md # CR generation
├── ralph-idea.md           # Idea capture
├── ralph-abort.md          # Stop Ralph
└── ralph-update.md         # Update Ralph

.claude/commands/
├── ralph:discover.md       # Discovery command
├── ralph:plan.md           # Planning command
├── ralph:preflight.md      # Preflight checks
├── ralph:deploy.md         # Deployment command
├── ralph:status.md         # Status check
├── ralph:review.md         # Review command
├── ralph:change-request.md # CR generation
├── ralph:idea.md           # Idea capture
├── ralph:abort.md          # Stop Ralph
└── ralph:update.md         # Update Ralph

.ralph-specs/             # Generated spec files
├── 01-setup.md
├── 02-auth.md
└── ...
```

---

## Memory Model

Inspired by Ryan Carson's Ralph concept:

| Type | File | Purpose |
|------|------|---------|
| Short-term | Spec itself | What the agent should do NOW |
| Medium-term | Checksums | Which specs are done |
| Long-term | Git commits | All code built |

**Fresh context per iteration** = Each spec starts with an empty agent session. No accumulated state means no accumulated confusion.

---

## References

- [snarktank/ralph](https://github.com/snarktank/ralph) - Ryan Carson's original concept
- [claude-ralph](https://github.com/RobinOppenstam/claude-ralph) - Robin Oppenstam's implementation
- [how-to-build-a-coding-agent](https://github.com/ghuntley/how-to-build-a-coding-agent) - Geoffrey Huntley's patterns
