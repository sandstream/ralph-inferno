#!/bin/bash
# agent-utils.sh - Agent selection and execution helpers
# Source this file: source lib/agent-utils.sh

AGENT_UTILS_LOADED=true

SCRIPT_DIR_AGENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR_AGENT/config-utils.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR_AGENT/config-utils.sh"
fi

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

get_agent() {
    local configured="${RALPH_AGENT:-}"
    if [ -z "$configured" ] && command -v load_config >/dev/null 2>&1; then
        configured=$(load_config "agent" "")
    fi

    local has_claude=false
    local has_codex=false
    if has_cmd claude; then
        has_claude=true
    fi
    if has_cmd codex; then
        has_codex=true
    fi

    case "$configured" in
        claude|codex)
            if [ "$configured" = "claude" ] && $has_claude; then
                echo "claude"
                return
            fi
            if [ "$configured" = "codex" ] && $has_codex; then
                echo "codex"
                return
            fi
            ;;
        ""|auto)
            configured=""
            ;;
        *)
            configured=""
            ;;
    esac

    if $has_claude; then
        echo "claude"
        return
    fi
    if $has_codex; then
        echo "codex"
        return
    fi

    echo "claude"
}

run_agent_prompt() {
    local prompt="$1"
    local timeout_seconds="${2:-}"
    local agent
    agent=$(get_agent)

    local output
    local exit_code=0

    if [ "$agent" = "codex" ]; then
        if [ -n "$timeout_seconds" ]; then
            output=$(echo "$prompt" | timeout "$timeout_seconds" codex exec --dangerously-bypass-approvals-and-sandbox - 2>&1) || exit_code=$?
        else
            output=$(echo "$prompt" | codex exec --dangerously-bypass-approvals-and-sandbox - 2>&1) || exit_code=$?
        fi
    else
        if [ -n "$timeout_seconds" ]; then
            output=$(echo "$prompt" | timeout "$timeout_seconds" claude --dangerously-skip-permissions -p 2>&1) || exit_code=$?
        else
            output=$(echo "$prompt" | claude --dangerously-skip-permissions -p 2>&1) || exit_code=$?
        fi
    fi

    echo "$output"
    return $exit_code
}

run_agent_image() {
    local prompt="$1"
    local image_path="$2"
    local timeout_seconds="${3:-}"
    local agent
    agent=$(get_agent)

    local output
    local exit_code=0

    if [ "$agent" = "codex" ]; then
        if [ -n "$timeout_seconds" ]; then
            output=$(echo "$prompt" | timeout "$timeout_seconds" codex exec --dangerously-bypass-approvals-and-sandbox --image "$image_path" - 2>&1) || exit_code=$?
        else
            output=$(echo "$prompt" | codex exec --dangerously-bypass-approvals-and-sandbox --image "$image_path" - 2>&1) || exit_code=$?
        fi
    else
        if [ -n "$timeout_seconds" ]; then
            output=$(echo "$prompt" | timeout "$timeout_seconds" claude --dangerously-skip-permissions -p --image "$image_path" 2>&1) || exit_code=$?
        else
            output=$(echo "$prompt" | claude --dangerously-skip-permissions -p --image "$image_path" 2>&1) || exit_code=$?
        fi
    fi

    echo "$output"
    return $exit_code
}
