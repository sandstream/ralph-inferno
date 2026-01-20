#!/bin/bash
# =============================================================================
# fusion.sh - F-Thread Implementation
#
# Runs the SAME spec multiple times in parallel, then picks the best result.
# This is for specs where the approach is uncertain - try multiple ways,
# compare outcomes, select the winner.
#
# "More shots at the problem = higher confidence"
#   - Indy Dev Dan
#
# Usage:
#   source lib/fusion.sh
#   run_fusion_thread "specs/03-auth.md" 3
#
# =============================================================================

FUSION_LOADED=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load dependencies if not already loaded
[ -z "${SELFHEAL_LOADED:-}" ] && source "$SCRIPT_DIR/selfheal.sh"
[ -f "$SCRIPT_DIR/verify.sh" ] && source "$SCRIPT_DIR/verify.sh"

# Configuration
FUSION_WORKTREE_BASE="${FUSION_WORKTREE_BASE:-$HOME/ralph-fusion}"
FUSION_RESULTS_DIR="${FUSION_RESULTS_DIR:-.fusion-results}"
FUSION_DEFAULT_ATTEMPTS="${FUSION_DEFAULT_ATTEMPTS:-3}"
FUSION_TIMEOUT="${FUSION_TIMEOUT:-1800}"  # 30 minutes per attempt

# Colors (if not already defined)
GREEN="${GREEN:-\033[0;32m}"
RED="${RED:-\033[0;31m}"
YELLOW="${YELLOW:-\033[1;33m}"
CYAN="${CYAN:-\033[0;36m}"
NC="${NC:-\033[0m}"

# Logging (use existing log function or define one)
if ! type log &>/dev/null; then
    log() { echo -e "[$(date +%H:%M:%S)] $1"; }
fi

# =============================================================================
# MAIN FUSION FUNCTION
# =============================================================================

# Run a spec using F-thread (multiple attempts, pick best)
run_fusion_thread() {
    local spec="$1"
    local attempts="${2:-$FUSION_DEFAULT_ATTEMPTS}"
    local spec_name=$(basename "$spec" .md)
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local results_dir="$FUSION_RESULTS_DIR/$spec_name-$timestamp"

    log "${CYAN}━━━ FUSION THREAD: $spec_name ($attempts attempts) ━━━${NC}"

    # Create results directory
    mkdir -p "$results_dir"
    mkdir -p "$FUSION_WORKTREE_BASE"

    # Track worktrees and PIDs
    local worktrees=()
    local branches=()
    local pids=()

    # Get current branch as base
    local base_branch=$(git rev-parse --abbrev-ref HEAD)

    # ==========================================================================
    # PHASE 1: Launch parallel attempts
    # ==========================================================================

    log "${YELLOW}Phase 1: Launching $attempts parallel attempts...${NC}"

    for i in $(seq 1 $attempts); do
        local branch="fusion-$spec_name-$i-$timestamp"
        local worktree="$FUSION_WORKTREE_BASE/$spec_name-$i-$timestamp"

        log "  Starting attempt $i..."

        # Create branch from current HEAD
        git branch "$branch" 2>/dev/null || git branch "$branch" HEAD

        # Create worktree
        if ! git worktree add "$worktree" "$branch" 2>/dev/null; then
            log "${RED}  Failed to create worktree for attempt $i${NC}"
            continue
        fi

        worktrees+=("$worktree")
        branches+=("$branch")

        # Copy the spec to worktree
        cp "$spec" "$worktree/"

        # Run Claude in background
        (
            cd "$worktree"

            local attempt_log="$results_dir/attempt-$i.log"
            local start_time=$(date +%s)

            # Run the spec
            local prompt="$(cat "$(basename "$spec")")

---
FUSION ATTEMPT $i of $attempts
Try a DIFFERENT approach than you might normally use. Be creative.
When complete: write <promise>DONE</promise>
Before DONE: verify the build passes."

            echo "$prompt" | timeout $FUSION_TIMEOUT claude --dangerously-skip-permissions -p > "$attempt_log" 2>&1
            local exit_code=$?

            local end_time=$(date +%s)
            local duration=$((end_time - start_time))

            # Capture results
            echo "$exit_code" > "$results_dir/exit-$i.txt"
            echo "$duration" > "$results_dir/duration-$i.txt"

            # Check for completion marker
            if grep -q "<promise>DONE</promise>" "$attempt_log"; then
                echo "COMPLETE" > "$results_dir/status-$i.txt"
            else
                echo "INCOMPLETE" > "$results_dir/status-$i.txt"
            fi

            # Run build verification
            local build_cmd=$(detect_build_cmd 2>/dev/null || echo "npm run build")
            if [ -n "$build_cmd" ]; then
                if $build_cmd > "$results_dir/build-$i.log" 2>&1; then
                    echo "PASS" > "$results_dir/build-status-$i.txt"
                else
                    echo "FAIL" > "$results_dir/build-status-$i.txt"
                fi
            else
                echo "SKIP" > "$results_dir/build-status-$i.txt"
            fi

            # Capture the diff (what changed)
            git diff HEAD > "$results_dir/diff-$i.patch" 2>/dev/null

            # Count files changed
            git diff --stat HEAD > "$results_dir/stats-$i.txt" 2>/dev/null

        ) &

        pids+=($!)
        log "  Attempt $i running (PID: ${pids[-1]})"
    done

    # ==========================================================================
    # PHASE 2: Wait for all attempts to complete
    # ==========================================================================

    log "${YELLOW}Phase 2: Waiting for attempts to complete...${NC}"

    local failed=0
    for i in "${!pids[@]}"; do
        local pid="${pids[$i]}"
        if wait "$pid"; then
            log "  Attempt $((i+1)) finished"
        else
            log "  Attempt $((i+1)) failed"
            ((failed++))
        fi
    done

    # ==========================================================================
    # PHASE 3: Analyze results
    # ==========================================================================

    log "${YELLOW}Phase 3: Analyzing results...${NC}"

    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                    FUSION RESULTS                               │"
    echo "├─────────┬──────────┬─────────┬──────────┬───────────────────────┤"
    echo "│ Attempt │ Complete │  Build  │ Duration │ Files Changed         │"
    echo "├─────────┼──────────┼─────────┼──────────┼───────────────────────┤"

    local best_attempt=0
    local best_score=0

    for i in $(seq 1 $attempts); do
        local status=$(cat "$results_dir/status-$i.txt" 2>/dev/null || echo "UNKNOWN")
        local build=$(cat "$results_dir/build-status-$i.txt" 2>/dev/null || echo "UNKNOWN")
        local duration=$(cat "$results_dir/duration-$i.txt" 2>/dev/null || echo "?")
        local files=$(cat "$results_dir/stats-$i.txt" 2>/dev/null | tail -1 | grep -o "[0-9]* file" | grep -o "[0-9]*" || echo "0")

        # Calculate score
        local score=0
        [ "$status" = "COMPLETE" ] && ((score += 50))
        [ "$build" = "PASS" ] && ((score += 40))
        [ "$files" -gt 0 ] && ((score += 10))

        # Track best
        if [ $score -gt $best_score ]; then
            best_score=$score
            best_attempt=$i
        fi

        # Print row
        printf "│    %d    │ %-8s │ %-7s │ %6ss  │ %3s files             │\n" \
            "$i" "$status" "$build" "$duration" "$files"
    done

    echo "└─────────┴──────────┴─────────┴──────────┴───────────────────────┘"
    echo ""

    # ==========================================================================
    # PHASE 4: Select best result
    # ==========================================================================

    if [ $best_attempt -eq 0 ]; then
        log "${RED}No successful attempts!${NC}"
        cleanup_fusion_worktrees "${worktrees[@]}"
        cleanup_fusion_branches "${branches[@]}"
        return 1
    fi

    log "${GREEN}Best attempt: #$best_attempt (score: $best_score)${NC}"

    # If best attempt has PASS build, use Claude to do final comparison
    if [ $best_score -ge 90 ] && [ $attempts -gt 1 ]; then
        log "${CYAN}Running Claude comparison for final selection...${NC}"
        best_attempt=$(select_best_with_claude "$results_dir" $attempts)
        log "${GREEN}Claude selected: attempt #$best_attempt${NC}"
    fi

    # ==========================================================================
    # PHASE 5: Apply winning result
    # ==========================================================================

    log "${YELLOW}Phase 5: Applying winning result...${NC}"

    local winning_worktree="${worktrees[$((best_attempt-1))]}"
    local winning_diff="$results_dir/diff-$best_attempt.patch"

    if [ -f "$winning_diff" ] && [ -s "$winning_diff" ]; then
        # Apply the diff from the winning attempt
        if git apply "$winning_diff" 2>/dev/null; then
            log "${GREEN}Applied changes from attempt #$best_attempt${NC}"
        else
            # If patch fails, try copying files directly
            log "${YELLOW}Patch failed, copying files directly...${NC}"
            if [ -d "$winning_worktree" ]; then
                rsync -av --exclude='.git' "$winning_worktree/" . 2>/dev/null
                log "${GREEN}Copied files from attempt #$best_attempt${NC}"
            fi
        fi
    else
        log "${YELLOW}No changes to apply from attempt #$best_attempt${NC}"
    fi

    # ==========================================================================
    # PHASE 6: Cleanup
    # ==========================================================================

    log "${YELLOW}Phase 6: Cleaning up...${NC}"

    cleanup_fusion_worktrees "${worktrees[@]}"
    cleanup_fusion_branches "${branches[@]}"

    # Keep results for debugging (optional cleanup)
    log "Results saved to: $results_dir"

    log "${GREEN}━━━ FUSION COMPLETE ━━━${NC}"
    return 0
}

# =============================================================================
# CLAUDE COMPARISON (Smart selection)
# =============================================================================

# Ask Claude to compare the results and pick the best
select_best_with_claude() {
    local results_dir="$1"
    local attempts="$2"

    local prompt="Compare these $attempts implementation attempts and select the best one.

"

    for i in $(seq 1 $attempts); do
        local status=$(cat "$results_dir/status-$i.txt" 2>/dev/null || echo "UNKNOWN")
        local build=$(cat "$results_dir/build-status-$i.txt" 2>/dev/null || echo "UNKNOWN")
        local log_tail=$(tail -50 "$results_dir/attempt-$i.log" 2>/dev/null)
        local diff_stats=$(cat "$results_dir/stats-$i.txt" 2>/dev/null)

        prompt+="=== ATTEMPT $i ===
Status: $status
Build: $build
Changes: $diff_stats

Log (last 50 lines):
$log_tail

"
    done

    prompt+="
Which attempt is BEST? Consider:
1. Did it complete successfully?
2. Did the build pass?
3. Code quality (based on the log output)
4. Simplicity of changes

Respond with ONLY a number (1-$attempts), nothing else."

    local result
    result=$(echo "$prompt" | timeout 120 claude --dangerously-skip-permissions -p 2>/dev/null)

    # Extract number from response
    local selected=$(echo "$result" | grep -o "[0-9]" | head -1)

    # Validate
    if [ -n "$selected" ] && [ "$selected" -ge 1 ] && [ "$selected" -le "$attempts" ]; then
        echo "$selected"
    else
        echo "1"  # Default to first attempt
    fi
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

cleanup_fusion_worktrees() {
    local worktrees=("$@")

    for worktree in "${worktrees[@]}"; do
        if [ -d "$worktree" ]; then
            git worktree remove "$worktree" --force 2>/dev/null || rm -rf "$worktree"
        fi
    done

    git worktree prune 2>/dev/null || true
}

cleanup_fusion_branches() {
    local branches=("$@")

    for branch in "${branches[@]}"; do
        git branch -D "$branch" 2>/dev/null || true
    done
}

# Clean up all fusion artifacts
cleanup_all_fusion() {
    log "Cleaning up all fusion artifacts..."

    # Remove worktrees
    if [ -d "$FUSION_WORKTREE_BASE" ]; then
        rm -rf "$FUSION_WORKTREE_BASE"
    fi

    # Remove results
    if [ -d "$FUSION_RESULTS_DIR" ]; then
        rm -rf "$FUSION_RESULTS_DIR"
    fi

    # Remove fusion branches
    git branch | grep "fusion-" | xargs -r git branch -D 2>/dev/null || true

    # Prune worktrees
    git worktree prune 2>/dev/null || true

    log "Cleanup complete"
}

# =============================================================================
# UTILITIES
# =============================================================================

# Quick fusion - run 3 attempts with defaults
quick_fusion() {
    local spec="$1"
    run_fusion_thread "$spec" 3
}

# Deep fusion - run 5 attempts for important decisions
deep_fusion() {
    local spec="$1"
    run_fusion_thread "$spec" 5
}

# Test fusion setup (dry run)
test_fusion_setup() {
    log "Testing fusion setup..."

    # Check git
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log "${RED}Not in a git repository${NC}"
        return 1
    fi

    # Check worktree support
    if ! git worktree list > /dev/null 2>&1; then
        log "${RED}Git worktree not supported${NC}"
        return 1
    fi

    # Check Claude
    if ! command -v claude &> /dev/null; then
        log "${RED}Claude CLI not found${NC}"
        return 1
    fi

    # Check write permissions
    if ! mkdir -p "$FUSION_WORKTREE_BASE" 2>/dev/null; then
        log "${RED}Cannot create worktree directory: $FUSION_WORKTREE_BASE${NC}"
        return 1
    fi

    log "${GREEN}Fusion setup OK${NC}"
    return 0
}
