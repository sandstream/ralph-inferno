# Thread Intelligence

> "Each spec gets the execution style that fits it best."

Thread Intelligence is a feature that automatically analyzes each spec and selects the optimal execution strategy (thread type) for it.

---

## Quick Start

```bash
# Preview what thread types would be selected
./ralph.sh --strategy

# Run with thread intelligence enabled
./ralph.sh --smart
```

---

## The Problem

Without thread intelligence, every spec runs the same way:

```
Spec 1 (simple button) → Base thread
Spec 2 (payment system) → Base thread  ← Should have extra verification!
Spec 3 (uncertain auth approach) → Base thread  ← Should try multiple ways!
```

With thread intelligence:

```
Spec 1 (simple button) → Base thread ✓
Spec 2 (payment system) → Chained thread (extra verification) ✓
Spec 3 (uncertain auth approach) → Fusion thread (try 3 ways) ✓
```

---

## Thread Types

| Thread | When to Use | What It Does |
|--------|-------------|--------------|
| **Base** | Simple, well-defined tasks | Run once, verify, done |
| **Fusion** | Uncertain approach, multiple valid solutions | Try 3 different ways, pick the best |
| **Chained** | High-risk (auth, payments, data) | Extra verification at each step |
| **Parallel** | Independent, no dependencies | Run alongside other specs |
| **Long** | Complex but clear path | Extended timeout, fewer interruptions |

---

## How Thread Selection Works

The selector uses a 3-step process:

### Step 1: Check for Explicit Hints (Fastest)

Add a hint in your spec header:

```markdown
# 03-auth-system.md

> Epic: Authentication
> Thread: fusion        ← Explicit hint
> Dependencies: 01, 02
```

Valid hints: `base`, `fusion`, `chained`, `parallel`, `long`

### Step 2: Keyword Detection (Fast)

If no hint, the selector looks for keywords in the spec:

**Risky keywords → Chained thread:**
- payment, billing, auth, security, password, migration, database, production

**Uncertain keywords → Fusion thread:**
- explore, experiment, prototype, alternative, approach, design, options

**Complex keywords → Long thread:**
- refactor, rewrite, overhaul, comprehensive, complete, entire

### Step 3: Claude Analysis (Smart)

If still uncertain, asks Claude to analyze the spec and recommend a thread type.

---

## Fusion Thread Deep Dive

Fusion is the most interesting thread type. It implements the F-thread pattern from Indy Dev Dan's framework.

### How It Works

```
                    ┌→ [Attempt 1] → Result A ─┐
[Same Spec] ────────┼→ [Attempt 2] → Result B ─┼→ [Compare] → Best Result
                    └→ [Attempt 3] → Result C ─┘
```

1. Creates 3 isolated git worktrees
2. Runs the same spec in each (with "be creative" prompting)
3. Each attempt might solve it differently
4. Compares results (build pass? complete? quality?)
5. Selects the winner
6. Applies winning changes to main branch
7. Cleans up

### When to Use Fusion

- Designing a new system architecture
- Multiple valid implementation approaches
- You want higher confidence in the solution
- Prototyping / exploring options

### Fusion Example

```markdown
# 05-design-auth-system.md

> Epic: Authentication
> Thread: fusion        ← Force fusion thread

## Goal
Design and implement user authentication.

## Options to Explore
- JWT tokens vs Session cookies
- OAuth vs custom auth
- Supabase Auth vs custom implementation

## Requirements
- Secure password storage
- Session management
- Protected routes
```

Running this with `--smart` will:
1. Try 3 different approaches in parallel
2. Compare which one has the cleanest implementation
3. Select the best one

---

## Usage Examples

### Preview Strategy

See what thread types would be selected without running:

```bash
./ralph.sh --strategy
```

Output:
```
┌─────────────────────────────────────────────────────────┐
│              THREAD SELECTION SUMMARY                   │
├─────────────────────────────────────────────────────────┤
│ 01-project-setup     │ base     │                      │
│ 02-design-system     │ base     │                      │
│ 03-auth-system       │ fusion   │                      │
│ 04-database-setup    │ chained  │                      │
│ 05-api-endpoints     │ parallel │                      │
└─────────────────────────────────────────────────────────┘
```

### Run with Thread Intelligence

```bash
./ralph.sh --smart
```

### Run Single Spec with Intelligence

```bash
./ralph.sh --smart specs/03-auth-system.md
```

### Combine with Orchestrator

```bash
./ralph.sh --orchestrate --smart
```

---

## Adding Thread Hints to Specs

You can override the automatic selection by adding hints:

```markdown
# spec-name.md

> Thread: fusion
> Risk: high
> Confidence: low
```

| Hint | Effect |
|------|--------|
| `Thread: base` | Force normal execution |
| `Thread: fusion` | Force 3-way comparison |
| `Thread: chained` | Force extra verification |
| `Thread: parallel` | Mark as parallelizable |
| `Thread: long` | Force extended timeout |

---

## Configuration

Environment variables:

```bash
# Fusion settings
export FUSION_DEFAULT_ATTEMPTS=3      # How many attempts for fusion
export FUSION_TIMEOUT=1800            # Timeout per attempt (seconds)
export FUSION_WORKTREE_BASE="$HOME/ralph-fusion"  # Where to create worktrees

# Thread selector settings
export LOG_THREAD_DECISIONS=true      # Show selection decisions
```

---

## Files

```
core/lib/
├── thread-selector.sh    # The "brain" - decides which thread type
└── fusion.sh             # F-thread implementation

docs/
└── THREAD-INTELLIGENCE.md  # This file
```

---

## Inspired By

This feature implements concepts from:

- **Indy Dev Dan's Thread Framework** - The 6 thread types (Base, P, C, F, B, L)
- **Jeff Huntley's Ralph** - "One context window, one goal"
- **Boris Cherny's parallel execution** - Running multiple Claudes

---

## Future Enhancements

- [ ] B-thread (Big) - Dynamic sub-agent composition
- [ ] L-thread (Long) - Stop hook integration for extended runs
- [ ] Z-thread (Zero-touch) - Maximum autonomy mode
- [ ] Thread learning - Remember which thread types work best per spec type
