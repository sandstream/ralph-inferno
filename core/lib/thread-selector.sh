#!/bin/bash
# =============================================================================
# thread-selector.sh - The Brain
#
# Analyzes specs and decides which thread type to use for execution.
# This enables "Hybrid Runtime" - each spec gets the execution style that fits.
#
# Thread Types:
#   base    - Normal single execution (default)
#   fusion  - Try N approaches, pick the best (for uncertain specs)
#   chained - Extra verification gates (for risky specs)
#   parallel- Can run alongside other specs (for independent specs)
#   long    - Extended timeout, fewer interruptions (for complex specs)
#
# Usage:
#   source lib/thread-selector.sh
#   thread_type=$(select_thread "specs/03-auth.md")
#
# =============================================================================

THREAD_SELECTOR_LOADED=true

# Default settings
DEFAULT_THREAD="base"
FUSION_ATTEMPTS="${FUSION_ATTEMPTS:-3}"

# Keywords that hint at different thread types
# These are checked BEFORE asking Claude (faster, no API cost)

# Risky keywords → chained thread (extra verification)
RISKY_KEYWORDS=(
    "payment"
    "billing"
    "auth"
    "authentication"
    "security"
    "password"
    "credential"
    "migration"
    "database"
    "production"
    "delete"
    "remove"
    "sensitive"
)

# Uncertain keywords → fusion thread (try multiple approaches)
UNCERTAIN_KEYWORDS=(
    "explore"
    "experiment"
    "prototype"
    "try"
    "alternative"
    "approach"
    "design"
    "architecture"
    "best way"
    "options"
    "compare"
    "evaluate"
)

# Independent keywords → parallel thread (can run with others)
INDEPENDENT_KEYWORDS=(
    "standalone"
    "independent"
    "isolated"
    "no dependencies"
    "utility"
    "helper"
    "component"
)

# Complex keywords → long thread (extended execution)
COMPLEX_KEYWORDS=(
    "refactor"
    "rewrite"
    "overhaul"
    "comprehensive"
    "complete"
    "full"
    "entire"
    "all"
)

# =============================================================================
# HINT-BASED SELECTION (Fast, no API cost)
# =============================================================================

# Check if spec has explicit thread hint in metadata
# Format: > Thread: fusion
get_thread_hint() {
    local spec="$1"

    # Look for explicit hint in spec header
    local hint=$(grep -i "^> *thread:" "$spec" 2>/dev/null | head -1 | sed 's/.*: *//' | tr '[:upper:]' '[:lower:]' | tr -d ' ')

    if [[ "$hint" =~ ^(base|fusion|chained|parallel|long)$ ]]; then
        echo "$hint"
        return 0
    fi

    echo ""
    return 1
}

# Check spec content for keyword matches
detect_thread_from_keywords() {
    local spec="$1"
    local content=$(cat "$spec" | tr '[:upper:]' '[:lower:]')

    local risky_count=0
    local uncertain_count=0
    local independent_count=0
    local complex_count=0

    # Count risky keywords
    for keyword in "${RISKY_KEYWORDS[@]}"; do
        if echo "$content" | grep -q "$keyword"; then
            ((risky_count++))
        fi
    done

    # Count uncertain keywords
    for keyword in "${UNCERTAIN_KEYWORDS[@]}"; do
        if echo "$content" | grep -q "$keyword"; then
            ((uncertain_count++))
        fi
    done

    # Count independent keywords
    for keyword in "${INDEPENDENT_KEYWORDS[@]}"; do
        if echo "$content" | grep -q "$keyword"; then
            ((independent_count++))
        fi
    done

    # Count complex keywords
    for keyword in "${COMPLEX_KEYWORDS[@]}"; do
        if echo "$content" | grep -q "$keyword"; then
            ((complex_count++))
        fi
    done

    # Decision logic (threshold-based)
    # Risky specs get extra verification
    if [ $risky_count -ge 2 ]; then
        echo "chained"
        return 0
    fi

    # Uncertain specs try multiple approaches
    if [ $uncertain_count -ge 2 ]; then
        echo "fusion"
        return 0
    fi

    # Complex specs get extended time
    if [ $complex_count -ge 3 ]; then
        echo "long"
        return 0
    fi

    # No strong signal
    echo ""
    return 1
}

# =============================================================================
# CLAUDE-BASED SELECTION (Smart, costs tokens)
# =============================================================================

# Ask Claude to analyze the spec and recommend a thread type
analyze_spec_with_claude() {
    local spec="$1"
    local spec_content=$(cat "$spec")
    local spec_name=$(basename "$spec")

    local prompt="Analyze this spec and recommend the best execution thread type.

SPEC: $spec_name
---
$spec_content
---

THREAD TYPES:
- base: Simple, well-defined task. Run once normally. (DEFAULT)
- fusion: Uncertain approach, multiple valid solutions. Try 3 different ways, pick best.
- chained: High-risk task (payments, auth, data). Run with extra verification gates.
- parallel: Independent task, no dependencies. Can run alongside other specs.
- long: Complex but well-planned. Extended timeout, let it run longer.

DECISION CRITERIA:
- Is the approach clear and well-defined? → base
- Are there multiple valid ways to solve this? → fusion
- Does it touch sensitive systems (auth, payments, data)? → chained
- Is it independent with no dependencies on other specs? → parallel
- Is it complex but the path is clear? → long

Respond with ONLY a JSON object, no other text:
{\"thread\": \"<type>\", \"confidence\": \"high|medium|low\", \"reason\": \"<one sentence>\"}
"

    local result
    result=$(echo "$prompt" | timeout 60 claude --dangerously-skip-permissions -p 2>/dev/null)

    # Extract thread type from JSON response
    local thread_type=$(echo "$result" | grep -o '"thread"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)

    # Validate thread type
    if [[ "$thread_type" =~ ^(base|fusion|chained|parallel|long)$ ]]; then
        echo "$thread_type"
        return 0
    fi

    # Fallback to default
    echo "$DEFAULT_THREAD"
    return 1
}

# =============================================================================
# MAIN SELECTION FUNCTION
# =============================================================================

# Select the best thread type for a spec
# Strategy: Check hints first (fast), then keywords, then ask Claude (smart)
select_thread() {
    local spec="$1"
    local use_claude="${2:-true}"  # Set to false to skip Claude analysis

    # Validate input
    if [ ! -f "$spec" ]; then
        echo "$DEFAULT_THREAD"
        return 1
    fi

    local thread_type=""

    # Step 1: Check for explicit hint (fastest)
    thread_type=$(get_thread_hint "$spec")
    if [ -n "$thread_type" ]; then
        log_thread_decision "$spec" "$thread_type" "explicit hint"
        echo "$thread_type"
        return 0
    fi

    # Step 2: Check keywords (fast)
    thread_type=$(detect_thread_from_keywords "$spec")
    if [ -n "$thread_type" ]; then
        log_thread_decision "$spec" "$thread_type" "keyword detection"
        echo "$thread_type"
        return 0
    fi

    # Step 3: Ask Claude (smart, costs tokens)
    if [ "$use_claude" = true ]; then
        thread_type=$(analyze_spec_with_claude "$spec")
        if [ -n "$thread_type" ]; then
            log_thread_decision "$spec" "$thread_type" "Claude analysis"
            echo "$thread_type"
            return 0
        fi
    fi

    # Step 4: Default fallback
    log_thread_decision "$spec" "$DEFAULT_THREAD" "default fallback"
    echo "$DEFAULT_THREAD"
    return 0
}

# =============================================================================
# BATCH ANALYSIS (Analyze all specs at once, more efficient)
# =============================================================================

# Analyze all specs and output a strategy
analyze_all_specs() {
    local specs_dir="${1:-specs}"
    local output_file="${2:-.thread-strategy.json}"

    echo "[thread-selector] Analyzing all specs in $specs_dir..."

    local strategy="["
    local first=true

    for spec in "$specs_dir"/*.md; do
        [ -f "$spec" ] || continue

        local spec_name=$(basename "$spec")
        local thread_type=$(select_thread "$spec" false)  # Fast mode, no Claude

        if [ "$first" = true ]; then
            first=false
        else
            strategy+=","
        fi

        strategy+="{\"spec\": \"$spec_name\", \"thread\": \"$thread_type\"}"
    done

    strategy+="]"

    echo "$strategy" > "$output_file"
    echo "[thread-selector] Strategy saved to $output_file"
}

# =============================================================================
# LOGGING
# =============================================================================

log_thread_decision() {
    local spec="$1"
    local thread_type="$2"
    local reason="$3"
    local spec_name=$(basename "$spec")

    # Only log if LOG_THREAD_DECISIONS is set
    # Output to stderr so it doesn't get captured by $(select_thread)
    if [ "${LOG_THREAD_DECISIONS:-false}" = true ]; then
        echo "[thread-selector] $spec_name → $thread_type ($reason)" >&2
    fi
}

# =============================================================================
# UTILITIES
# =============================================================================

# Get human-readable description of a thread type
describe_thread() {
    local thread_type="$1"

    case "$thread_type" in
        "base")
            echo "Normal execution - run once, verify, done"
            ;;
        "fusion")
            echo "Try $FUSION_ATTEMPTS approaches in parallel, pick the best"
            ;;
        "chained")
            echo "High-risk mode - extra verification at each step"
            ;;
        "parallel")
            echo "Independent - can run alongside other specs"
            ;;
        "long")
            echo "Extended execution - longer timeout, fewer interruptions"
            ;;
        *)
            echo "Unknown thread type"
            ;;
    esac
}

# Print thread selection summary for a set of specs
print_thread_summary() {
    local specs_dir="${1:-specs}"

    echo ""
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│              THREAD SELECTION SUMMARY                   │"
    echo "├─────────────────────────────────────────────────────────┤"

    for spec in "$specs_dir"/*.md; do
        [ -f "$spec" ] || continue

        local spec_name=$(basename "$spec" .md)
        local thread_type=$(select_thread "$spec" false)
        local description=$(describe_thread "$thread_type")

        printf "│ %-20s │ %-8s │ %-20s │\n" "$spec_name" "$thread_type" ""
    done

    echo "└─────────────────────────────────────────────────────────┘"
    echo ""
}
