# Ralph CLI Flags

## ralph.sh

The main entry point for running Ralph on the VM.

### Basic Usage

```bash
./ralph.sh                    # Quick mode (default)
./ralph.sh --orchestrate      # Standard mode with E2E + auto-CR
./ralph.sh --orchestrate --parallel  # Inferno mode (all features)
./ralph.sh --status           # Show progress
./ralph.sh --cost             # Show token usage estimate
./ralph.sh --watch            # Fireplace dashboard
./ralph.sh --help             # Show help
```

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--orchestrate` | `-o` | Middle loop with E2E tests + auto-CR |
| `--parallel` | `-p` | Use git worktrees for parallel execution |
| `--status` | `-s` | Show current progress (specs done/total) |
| `--cost` | `-c` | Show token usage and cost estimate |
| `--watch` | `-w` | Live dashboard showing Ralph's progress |
| `--full` | | Legacy full mode (~1900 lines) |
| `--help` | `-h` | Show help message |

## Three Modes

### Quick Mode (default)

```bash
./ralph.sh
```

- Spec execution + build verify
- No E2E tests
- Fastest, lowest token usage
- Good for simple projects or debugging

### Standard Mode

```bash
./ralph.sh --orchestrate
```

- Everything in Quick mode, plus:
- Playwright E2E tests after each spec
- Auto-CR generation when tests fail
- Middle loop retries until all specs pass
- Recommended for most projects

### Inferno Mode

```bash
./ralph.sh --orchestrate --parallel
```

- Everything in Standard mode, plus:
- Design review with agent image input (Codex or Claude)
- Auto-CR for design issues
- Parallel worktrees for faster execution
- Full autonomous power

## When to Use Each Mode

| Use Case | Mode |
|----------|------|
| Simple project | Quick |
| Most projects | Standard |
| Large projects (20+ specs) | Inferno |
| Debugging | Quick |
| Overnight runs | Standard/Inferno |
| Limited API credits | Quick |

## Deploy Mode Selection

When running `/ralph:deploy` or `/prompts:ralph-deploy`, you choose the mode:

```
Vilken mode vill du köra Ralph i?

1. Standard (E2E + auto-CR) - Recommended
2. Quick (bara build)
3. Inferno (allt + parallel)
```

## ralph-inferno CLI

```bash
npx ralph-inferno install   # Install Ralph in project
npx ralph-inferno update    # Update core files, keep config
```

### Install Options

During `install`, you'll be asked:
1. Language (en, sv, es, de, fr, zh)
2. Cloud provider (hcloud, gcloud, doctl, aws, ssh)
3. VM name and region
4. ntfy.sh notifications (optional)
5. GitHub username (auto-detected from `gh` CLI)
6. Agent authentication method (Claude or Codex)

## Commands & Prompts

| Command | Description |
|---------|-------------|
| Claude Code | Codex CLI | Description |
|-------------|-----------|-------------|
| `/ralph:discover` | `/prompts:ralph-discover` | Autonomous discovery loop → PRD |
| `/ralph:plan` | `/prompts:ralph-plan` | Break down PRD → specs |
| `/ralph:deploy` | `/prompts:ralph-deploy` | Push to GitHub, start on VM |
| `/ralph:review` | `/prompts:ralph-review` | Open tunnels, test the app |
| `/ralph:change-request` | `/prompts:ralph-change-request` | Document bugs → CR specs |
| `/ralph:status` | `/prompts:ralph-status` | Check Ralph's progress on VM |
| `/ralph:abort` | `/prompts:ralph-abort` | Stop Ralph on VM |
