#!/bin/bash
# tokens.sh - Token estimation and context window awareness
# Source this file: source lib/tokens.sh

TOKEN_LOG="${TOKEN_LOG:-$HOME/ralph-tokens.log}"
MAX_CONTEXT_TOKENS="${MAX_CONTEXT_TOKENS:-176000}"

# Estimate tokens (rough: ~4 chars per token for code)
estimate_tokens() {
    local text="$1"
    local chars=$(echo "$text" | wc -c | tr -d ' ')
    echo $((chars / 4))
}

# Log token usage
log_tokens() {
    local context="$1"
    local tokens="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $tokens tokens | $context" >> "$TOKEN_LOG"
}

# Check if we're approaching context limit
check_context_usage() {
    local current_tokens=$1
    local max_tokens=${2:-$MAX_CONTEXT_TOKENS}
    local usage_percent=$((current_tokens * 100 / max_tokens))

    if [ $usage_percent -gt 80 ]; then
        echo "[tokens] ⚠️ Context usage: ${usage_percent}% ($current_tokens/$max_tokens)"
        return 1
    elif [ $usage_percent -gt 50 ]; then
        echo "[tokens] Context usage: ${usage_percent}%"
    fi

    return 0
}

# Get total tokens used this session
get_session_tokens() {
    local today=$(date '+%Y-%m-%d')
    grep "$today" "$TOKEN_LOG" 2>/dev/null | awk -F'|' '{sum += $2} END {print sum+0}'
}

# Estimate spec complexity (for parallel scheduling)
estimate_spec_complexity() {
    local spec="$1"
    local tokens=$(estimate_tokens "$(cat "$spec")")

    if [ $tokens -lt 200 ]; then
        echo "small"
    elif [ $tokens -lt 500 ]; then
        echo "medium"
    else
        echo "large"
    fi
}

# =============================================================================
# COST TRACKING
# =============================================================================

# Pricing per 1M tokens (override with env vars if needed)
# Sonnet 4: $3/1M input, $15/1M output
# Opus 4.5: $15/1M input, $75/1M output
# Set INPUT_COST_PER_M and OUTPUT_COST_PER_M to override
INPUT_COST_PER_M=${INPUT_COST_PER_M:-3}    # Sonnet default
OUTPUT_COST_PER_M=${OUTPUT_COST_PER_M:-15}

# Estimate cost from tokens
estimate_cost() {
    local input_tokens=$1
    local output_tokens=${2:-$((input_tokens / 2))}  # Estimate output as half of input

    # Cost in dollars (tokens / 1M * price)
    local input_cost=$(echo "scale=4; $input_tokens / 1000000 * $INPUT_COST_PER_M" | bc)
    local output_cost=$(echo "scale=4; $output_tokens / 1000000 * $OUTPUT_COST_PER_M" | bc)
    local total=$(echo "scale=4; $input_cost + $output_cost" | bc)

    echo "$total"
}

# Get cost summary for today
get_today_cost() {
    local today=$(date '+%Y-%m-%d')
    local total_tokens=$(grep "$today" "$TOKEN_LOG" 2>/dev/null | awk -F'|' '{sum += $2} END {print sum+0}')

    if [ "$total_tokens" -eq 0 ]; then
        echo "0.00"
        return
    fi

    estimate_cost "$total_tokens"
}

# Print cost summary
print_cost_summary() {
    local today=$(date '+%Y-%m-%d')

    echo "=== COST SUMMARY ==="
    echo ""

    # Today
    local today_tokens=$(grep "$today" "$TOKEN_LOG" 2>/dev/null | awk -F'|' '{sum += $2} END {print sum+0}')
    local today_cost=$(estimate_cost "$today_tokens")
    echo "Today: ~${today_tokens} tokens ≈ \$${today_cost}"

    # This week
    local week_tokens=$(grep "$(date '+%Y-%m')" "$TOKEN_LOG" 2>/dev/null | awk -F'|' '{sum += $2} END {print sum+0}')
    local week_cost=$(estimate_cost "$week_tokens")
    echo "This month: ~${week_tokens} tokens ≈ \$${week_cost}"

    # Per spec average
    local spec_count=$(grep "$today" "$TOKEN_LOG" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$spec_count" -gt 0 ]; then
        local avg=$((today_tokens / spec_count))
        echo "Avg per spec: ~${avg} tokens"
    fi

    echo ""
    echo "(Based on Sonnet pricing - set INPUT_COST_PER_M/OUTPUT_COST_PER_M for other models)"
}
