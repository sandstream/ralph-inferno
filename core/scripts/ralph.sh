#!/bin/bash
# =============================================================================
# ralph.sh - The One Script
#
# Usage:
#   ./ralph.sh                    # Clean loop (default)
#   ./ralph.sh --parallel         # Parallel with worktrees
#   ./ralph.sh --watch            # Fireplace dashboard
#   ./ralph.sh --status           # Show status
#   ./ralph.sh --full             # Legacy full mode
#   ./ralph.sh --help             # Help
#
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

# Check for --full flag (legacy)
if [[ "${1:-}" == "--full" ]]; then
    shift
    exec "$SCRIPT_DIR/ralph-full.sh" "$@"
fi

# Check for --watch
if [[ "${1:-}" == "--watch" ]] || [[ "${1:-}" == "-w" ]]; then
    source "$LIB_DIR/watch.sh"
    show_watch
    exit 0
fi

# Check for --status
if [[ "${1:-}" == "--status" ]] || [[ "${1:-}" == "-s" ]]; then
    echo "=== Ralph Status ==="
    echo ""
    if [ -d "specs" ]; then
        total=$(ls -1 specs/*.md 2>/dev/null | wc -l | tr -d ' ')
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

# Check for --help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << 'EOF'
ralph.sh - The One Script

USAGE:
  ./ralph.sh                    Clean loop (default)
  ./ralph.sh spec.md            Run single spec
  ./ralph.sh --orchestrate      Middle loop with E2E test + auto-CR
  ./ralph.sh --parallel         Parallel with worktrees + dynamic scaling
  ./ralph.sh --watch            Fireplace dashboard
  ./ralph.sh --status           Show progress
  ./ralph.sh --cost             Show cost estimate
  ./ralph.sh --full             Legacy full mode (~1900 lines)
  ./ralph.sh --help             This help

MODES:
  default       Sequential, one spec at a time
  --orchestrate Middle loop: specs → E2E → design review → CR → retry
  --parallel    Parallel worktrees with dynamic scaling
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

# Check for --parallel (after loading libs)
PARALLEL_MODE=false
if [[ "${1:-}" == "--parallel" ]] || [[ "${1:-}" == "-p" ]]; then
    PARALLEL_MODE=true
    shift
    source "$LIB_DIR/parallel.sh"
fi

# Config
MAX_RETRIES=3
TIMEOUT=1800
COMPLETION_MARKER="<promise>DONE</promise>"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "[$(date +%H:%M:%S)] $1"; }

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
        local prompt="$(cat "$spec")

---
When complete: write $COMPLETION_MARKER
Before DONE: run 'npm run build' and verify it passes."

        output=$(echo "$prompt" | timeout $TIMEOUT claude --dangerously-skip-permissions -p 2>&1) || exit_code=$?

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
                    local cr_spec="specs/CR-fix-${spec_name}.md"
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
                    local design_cr="specs/CR-design-${spec_name}.md"
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

    log "${RED}❌ Failed${NC}"
    notify_spec_failed "$spec"
    return 1
}

# Main
main() {
    log "${CYAN}Ralph Starting${NC}"
    notify "🚀 Ralph starting"

    local specs_done=0 specs_failed=0

    # Parallel mode uses worktrees
    if [ "$PARALLEL_MODE" = true ]; then
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
    local total_specs=$(ls -1 specs/*.md 2>/dev/null | grep -v "/CR-" | wc -l | tr -d ' ')

    if [ "$total_specs" -eq 0 ]; then
        log "${RED}Inga specs hittades i specs/*.md${NC}"
        notify "❌ Inga specs hittades"
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
