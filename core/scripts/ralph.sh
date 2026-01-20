#!/bin/bash
# =============================================================================
# ralph.sh - The One Script
#
# Usage:
#   ./ralph.sh                    # Clean loop (default)
#   ./ralph.sh --smart            # Thread intelligence (auto-select best thread)
#   ./ralph.sh --orchestrate      # Middle loop with E2E + auto-CR
#   ./ralph.sh --parallel         # Parallel with worktrees
#   ./ralph.sh --status           # Show status
#   ./ralph.sh --cost             # Show cost estimate
#   ./ralph.sh --strategy         # Show thread strategy for all specs
#   ./ralph.sh --help             # Help
#
# Thread Intelligence: Analyzes each spec and picks the best execution style
# Clean loop: ~150 lines, follows Ryan Carson / Geoffrey Huntley approach
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Check for --orchestrate (middle loop)
if [[ "${1:-}" == "--orchestrate" ]] || [[ "${1:-}" == "-o" ]]; then
    shift
    exec "$SCRIPT_DIR/orchestrator.sh" "$@"
fi

# Check for --status
if [[ "${1:-}" == "--status" ]] || [[ "${1:-}" == "-s" ]]; then
    echo "=== Ralph Status ==="
    echo ""
    if [ -d "specs" ]; then
        total=$(ls -1 .ralph-specs/*.md 2>/dev/null | wc -l | tr -d ' ')
        done=$(ls -1 .spec-checksums/*.md5 2>/dev/null | wc -l | tr -d ' ')
        echo "Specs: $done/$total done"
    fi
    if [ -d ".spec-checksums" ]; then
        echo ""
        echo "Completed:"
        ls -1 .spec-checksums/*.md5 2>/dev/null | xargs -I{} basename {} .md5 | sed 's/^/  ✅ /'
    fi
    exit 0
fi

# Check for --cost
if [[ "${1:-}" == "--cost" ]] || [[ "${1:-}" == "-c" ]]; then
    source "$LIB_DIR/tokens.sh"
    print_cost_summary
    exit 0
fi

# Check for --strategy (show thread recommendations)
if [[ "${1:-}" == "--strategy" ]]; then
    source "$LIB_DIR/thread-selector.sh"
    print_thread_summary "specs"
    exit 0
fi

# Check for --help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << 'EOF'
ralph.sh - The One Script

USAGE:
  ./ralph.sh                    Clean loop (default)
  ./ralph.sh spec.md            Run single spec
  ./ralph.sh --smart            Thread intelligence - auto-select best thread type
  ./ralph.sh --orchestrate      Middle loop with E2E test + auto-CR
  ./ralph.sh --parallel         Parallel with worktrees + dynamic scaling
  ./ralph.sh --strategy         Show recommended thread type for each spec
  ./ralph.sh --watch            Fireplace dashboard
  ./ralph.sh --status           Show progress
  ./ralph.sh --cost             Show cost estimate
  ./ralph.sh --full             Legacy full mode (~1900 lines)
  ./ralph.sh --help             This help

MODES:
  default       Sequential, one spec at a time (base thread)
  --smart       Thread intelligence: analyzes each spec, picks best thread type
                  - base:    Simple specs, run once
                  - fusion:  Uncertain specs, try 3 ways, pick best
                  - chained: Risky specs, extra verification
                  - long:    Complex specs, extended timeout
  --orchestrate Middle loop: specs → E2E → design review → CR → retry
  --parallel    Parallel worktrees with dynamic scaling
  --strategy    Preview thread recommendations without running
  --watch       Live dashboard showing progress
  --cost        Token usage and cost estimate
  --full        Legacy monolithic script (all features)

EOF
    exit 0
fi

# =============================================================================
# CLEAN LOOP BELOW (~120 lines)
# =============================================================================

# Load libraries
source "$LIB_DIR/spec-utils.sh"
source "$LIB_DIR/verify.sh"
source "$LIB_DIR/notify.sh"
source "$LIB_DIR/git-utils.sh"
source "$LIB_DIR/rate-limit.sh"
source "$LIB_DIR/summary.sh"
source "$LIB_DIR/tokens.sh"
source "$LIB_DIR/test-loop.sh"
source "$LIB_DIR/agent-utils.sh"

# Check for --parallel (after loading libs)
PARALLEL_MODE=false
if [[ "${1:-}" == "--parallel" ]] || [[ "${1:-}" == "-p" ]]; then
    PARALLEL_MODE=true
    shift
    source "$LIB_DIR/parallel.sh"
fi

# Check for --smart (thread intelligence)
SMART_MODE=false
if [[ "${1:-}" == "--smart" ]] || [[ "${1:-}" == "-S" ]]; then
    SMART_MODE=true
    shift
    source "$LIB_DIR/thread-selector.sh"
    source "$LIB_DIR/fusion.sh"
    LOG_THREAD_DECISIONS=true  # Show thread selection decisions
fi

# Config
MAX_RETRIES=3
TIMEOUT=1800
COMPLETION_MARKER="<promise>DONE</promise>"

# Logs
LOG_DIR=".ralph/logs"
mkdir -p "$LOG_DIR"
AGENT_NAME=$(get_agent)
RAW_LOG="$LOG_DIR/${AGENT_NAME}-raw.log"
ERROR_LOG="$LOG_DIR/errors.log"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "[$(date +%H:%M:%S)] $1"; }

# Log raw agent output to file (always), and show tail on error
log_agent_output() {
    local spec_name="$1"
    local output="$2"
    local exit_code="${3:-0}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Always append to raw log
    echo "=== [$timestamp] $spec_name ===" >> "$RAW_LOG"
    echo "$output" >> "$RAW_LOG"
    echo "" >> "$RAW_LOG"

    # On error, also write to error log with context
    if [ "$exit_code" -ne 0 ] || ! echo "$output" | grep -q "$COMPLETION_MARKER"; then
        echo "=== [$timestamp] $spec_name FAILED ===" >> "$ERROR_LOG"
        echo "$output" | tail -100 >> "$ERROR_LOG"
        echo "" >> "$ERROR_LOG"
    fi
}

# Run a single spec
run_spec() {
    local spec="$1"
    local attempt=1
    local spec_name=$(basename "$spec" .md)

    log "${GREEN}=== $spec_name ===${NC}"
    notify_spec_start "$spec"

    # Token estimation
    local prompt_content=$(cat "$spec")
    local tokens=$(estimate_tokens "$prompt_content")
    log "Tokens: ~$tokens"
    log_tokens "$spec_name" "$tokens"

    if is_spec_done "$spec"; then
        log "${CYAN}⏭ Already done${NC}"
        return 0
    fi

    while [ $attempt -le $MAX_RETRIES ]; do
        log "${YELLOW}Attempt $attempt/$MAX_RETRIES${NC}"

        local output exit_code=0
        local build_cmd
        build_cmd=$(detect_build_cmd 2>/dev/null || echo "the build command")
        local prompt="$(cat "$spec")

---
When complete: write $COMPLETION_MARKER
Before DONE: run '$build_cmd' and verify it passes."

        output=$(run_agent_prompt "$prompt" "$TIMEOUT") || exit_code=$?

        # Log output to file (always)
        log_agent_output "$spec_name" "$output" "$exit_code"

        if is_rate_limited "$output"; then
            handle_rate_limit "$spec_name"
            continue
        fi

        if [ $exit_code -eq 124 ]; then
            log "${RED}Timeout${NC}"
            ((attempt++))
            continue
        fi

        if echo "$output" | grep -q "$COMPLETION_MARKER"; then
            if verify_build; then
                # Run E2E tests if available
                if ! run_e2e_tests; then
                    local cr_spec=".ralph-specs/CR-fix-${spec_name}.md"
                    if generate_cr "$spec_name" && [ -f "$cr_spec" ]; then
                        log "${YELLOW}Running CR fix...${NC}"
                        run_spec "$cr_spec"
                        rm -f "$cr_spec"
                    fi
                    ((attempt++))
                    continue
                fi

                # Run design review (optional, after E2E pass)
                take_screenshots ".screenshots"
                if ! run_design_review "$spec_name"; then
                    local design_cr=".ralph-specs/CR-design-${spec_name}.md"
                    if generate_design_cr "$spec_name" && [ -f "$design_cr" ]; then
                        log "${YELLOW}Running design fix...${NC}"
                        run_spec "$design_cr"
                        rm -f "$design_cr"
                    fi
                    ((attempt++))
                    continue
                fi

                log "${GREEN}✅ Verified${NC}"
                check_dangerous && check_secrets && commit_and_push "Ralph: $spec_name"
                mark_spec_done "$spec"
                notify_spec_done "$spec"
                return 0
            fi
        fi

        ((attempt++))
        sleep 5
    done

    log "${RED}❌ Failed after $MAX_RETRIES attempts${NC}"
    log "${YELLOW}See logs: $ERROR_LOG${NC}"
    notify_spec_failed "$spec"
    return 1
}

# =============================================================================
# SMART MODE: Thread-Intelligent Spec Execution
# =============================================================================

# Run a spec with automatic thread type selection
run_spec_smart() {
    local spec="$1"
    local spec_name=$(basename "$spec" .md)

    # Skip if already done
    if is_spec_done "$spec"; then
        log "${CYAN}⏭ Already done: $spec_name${NC}"
        return 0
    fi

    # Analyze spec and select thread type
    log "${CYAN}Analyzing: $spec_name${NC}"
    local thread_type=$(select_thread "$spec" true)  # true = use Claude if needed

    log "${YELLOW}Thread type: $thread_type${NC}"

    # Route to appropriate runner
    case "$thread_type" in
        "fusion")
            log "${CYAN}━━━ Running FUSION thread (3 attempts) ━━━${NC}"
            if run_fusion_thread "$spec" 3; then
                # Verify and mark done
                if verify_build; then
                    check_dangerous && check_secrets && commit_and_push "Ralph [fusion]: $spec_name"
                    mark_spec_done "$spec"
                    notify_spec_done "$spec"
                    return 0
                fi
            fi
            return 1
            ;;

        "chained")
            log "${CYAN}━━━ Running CHAINED thread (extra verification) ━━━${NC}"
            # Run with extra verification - essentially run_spec but stricter
            local old_retries=$MAX_RETRIES
            MAX_RETRIES=5  # More retries for risky specs
            run_spec "$spec"
            local result=$?
            MAX_RETRIES=$old_retries
            return $result
            ;;

        "long")
            log "${CYAN}━━━ Running LONG thread (extended timeout) ━━━${NC}"
            # Run with extended timeout
            local old_timeout=$TIMEOUT
            TIMEOUT=3600  # 1 hour for complex specs
            run_spec "$spec"
            local result=$?
            TIMEOUT=$old_timeout
            return $result
            ;;

        "parallel")
            log "${CYAN}━━━ Marked for PARALLEL (will batch with others) ━━━${NC}"
            # For now, just run normally - parallel batching happens at main level
            run_spec "$spec"
            return $?
            ;;

        *)
            # Default: base thread (normal execution)
            log "${CYAN}━━━ Running BASE thread (normal) ━━━${NC}"
            run_spec "$spec"
            return $?
            ;;
    esac
}

# Batch parallel specs together
run_parallel_batch() {
    local parallel_specs=("$@")

    if [ ${#parallel_specs[@]} -eq 0 ]; then
        return 0
    fi

    if [ ${#parallel_specs[@]} -eq 1 ]; then
        # Only one spec, run normally
        run_spec "${parallel_specs[0]}"
        return $?
    fi

    log "${CYAN}━━━ Running ${#parallel_specs[@]} specs in PARALLEL ━━━${NC}"
    source "$LIB_DIR/parallel.sh" 2>/dev/null || true
    run_parallel run_spec "${parallel_specs[@]}"
    return $?
}

# Main smart execution loop
# Sets globals: SMART_SPECS_DONE, SMART_SPECS_FAILED
run_all_specs_smart() {
    SMART_SPECS_DONE=0
    SMART_SPECS_FAILED=0
    local parallel_batch=()

    while true; do
        local spec=$(next_incomplete_spec)
        [ -z "$spec" ] && break

        local spec_name=$(basename "$spec" .md)

        # Check thread type
        local thread_type=$(select_thread "$spec" false)  # Fast mode for batching decisions

        if [ "$thread_type" = "parallel" ]; then
            # Collect parallel specs for batch execution
            parallel_batch+=("$spec")
            log "${YELLOW}Queued for parallel: $spec_name${NC}"
        else
            # First, run any accumulated parallel batch
            if [ ${#parallel_batch[@]} -gt 0 ]; then
                run_parallel_batch "${parallel_batch[@]}" && \
                    ((SMART_SPECS_DONE += ${#parallel_batch[@]})) || \
                    ((SMART_SPECS_FAILED += ${#parallel_batch[@]}))
                parallel_batch=()
            fi

            # Then run this spec with its designated thread type
            run_spec_smart "$spec" && ((SMART_SPECS_DONE++)) || ((SMART_SPECS_FAILED++))
        fi
    done

    # Run any remaining parallel batch
    if [ ${#parallel_batch[@]} -gt 0 ]; then
        run_parallel_batch "${parallel_batch[@]}" && \
            ((SMART_SPECS_DONE += ${#parallel_batch[@]})) || \
            ((SMART_SPECS_FAILED += ${#parallel_batch[@]}))
    fi
}

# Main
main() {
    log "${CYAN}Ralph Starting${NC}"

    # Show mode
    if [ "$SMART_MODE" = true ]; then
        log "${YELLOW}🧠 Thread Intelligence ENABLED${NC}"
        notify "🚀 Ralph starting (smart mode)"
    else
        notify "🚀 Ralph starting"
    fi

    local specs_done=0 specs_failed=0

    # Smart mode: auto-select thread type per spec
    if [ "$SMART_MODE" = true ]; then
        log "${YELLOW}Analyzing specs for optimal thread types...${NC}"

        if [ $# -gt 0 ]; then
            # Specific specs provided
            for spec in "$@"; do
                run_spec_smart "$spec" && ((specs_done++)) || ((specs_failed++))
            done
        else
            # Run all specs with smart selection
            # Note: run_all_specs_smart sets SMART_SPECS_DONE and SMART_SPECS_FAILED globals
            run_all_specs_smart
            specs_done=$SMART_SPECS_DONE
            specs_failed=$SMART_SPECS_FAILED
        fi

    # Parallel mode uses worktrees
    elif [ "$PARALLEL_MODE" = true ]; then
        log "${YELLOW}Parallel mode enabled${NC}"
        local specs=()
        if [ $# -gt 0 ]; then
            specs=("$@")
        else
            while IFS= read -r spec; do
                specs+=("$spec")
            done < <(list_incomplete_specs)
        fi

        if [ ${#specs[@]} -gt 0 ]; then
            run_parallel run_spec "${specs[@]}"
            specs_done=${#specs[@]}  # Approximate
        fi
    else
        # Sequential mode (default)
        if [ $# -gt 0 ]; then
            for spec in "$@"; do
                run_spec "$spec" && ((specs_done++)) || ((specs_failed++))
            done
        else
            while true; do
                local spec=$(next_incomplete_spec)
                [ -z "$spec" ] && break
                run_spec "$spec" && ((specs_done++)) || ((specs_failed++))
            done
        fi
    fi

    # Count total specs (excluding CR-* files)
    local total_specs=$(ls -1 .ralph-specs/*.md 2>/dev/null | grep -v "/CR-" | wc -l | tr -d ' ')

    if [ "$total_specs" -eq 0 ]; then
        log "${RED}No specs found i .ralph-specs/*.md${NC}"
        notify "❌ No specs found"
        exit 1
    fi

    local total_done=$(ls -1 .spec-checksums/*.md5 2>/dev/null | wc -l | tr -d ' ')
    log "${GREEN}=== Done: $total_done/$total_specs specs ===${NC}"
    log "${GREEN}=== This run: $specs_done completed, $specs_failed failed ===${NC}"

    # Generate summary report
    generate_summary "$specs_done" "$specs_failed" "$total_specs"

    notify_complete "$specs_done" "$total_specs"

    [ $specs_failed -eq 0 ]
}

main "$@"
