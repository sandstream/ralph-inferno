#!/bin/bash
# notify.sh - Notifications via ntfy with epic tracking
# Source this file: source lib/notify.sh

# Load config utilities if available
SCRIPT_DIR_NOTIFY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR_NOTIFY/config-utils.sh" ]; then
    source "$SCRIPT_DIR_NOTIFY/config-utils.sh"
    NTFY_TOPIC="${NTFY_TOPIC:-$(get_ntfy_topic)}"
    NTFY_ENABLED="${NTFY_ENABLED:-$(is_ntfy_enabled && echo "true" || echo "false")}"
else
    # Fallback: Load directly from config
    if [ -z "${NTFY_TOPIC:-}" ] && [ -f ".ralph/config.json" ]; then
        NTFY_TOPIC=$(grep -o '"ntfy_topic"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
    fi
    NTFY_ENABLED="${NTFY_ENABLED:-true}"
fi
NTFY_TOPIC="${NTFY_TOPIC:-}"

CURRENT_EPIC=""
CURRENT_EPIC_NAME=""

# Send notification
notify() {
    local msg="$1"
    local priority="${2:-default}"

    # Check if notifications are enabled
    [ "$NTFY_ENABLED" = "false" ] && return 0
    [ -z "$NTFY_TOPIC" ] && return 0

    curl -s \
        -H "Priority: $priority" \
        -d "$msg" \
        "https://ntfy.sh/$NTFY_TOPIC" \
        > /dev/null 2>&1 || true
}

# Find IMPLEMENTATION_PLAN.md
_find_plan() {
    if [ -f "docs/IMPLEMENTATION_PLAN.md" ]; then
        echo "docs/IMPLEMENTATION_PLAN.md"
    elif [ -f "IMPLEMENTATION_PLAN.md" ]; then
        echo "IMPLEMENTATION_PLAN.md"
    fi
}

# Match spec to epic (simple: based on spec number)
_get_epic_for_spec() {
    local spec_name="$1"
    local plan=$(_find_plan)
    [ -z "$plan" ] && return

    # Try to match spec name to epic section
    local spec_num=$(echo "$spec_name" | grep -oE "^[0-9]+" | sed 's/^0*//')
    [ -z "$spec_num" ] && return

    # Simple heuristic: specs 01-04 = E1, 05-08 = E2, etc
    local epic_num=$(( (spec_num - 1) / 4 + 1 ))

    # Find epic name from plan
    local epic_line=$(grep -E "^\| *E$epic_num *\|" "$plan" 2>/dev/null | head -1)
    if [ -n "$epic_line" ]; then
        local epic_name=$(echo "$epic_line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        echo "E$epic_num|$epic_name"
    fi
}

# Check and notify epic change
check_epic_change() {
    local spec="$1"
    local spec_name=$(basename "$spec" .md)

    local epic_info=$(_get_epic_for_spec "$spec_name")
    [ -z "$epic_info" ] && return

    local new_epic=$(echo "$epic_info" | cut -d'|' -f1)
    local new_epic_name=$(echo "$epic_info" | cut -d'|' -f2)

    if [ "$new_epic" != "$CURRENT_EPIC" ]; then
        # Notify previous epic done
        if [ -n "$CURRENT_EPIC" ]; then
            notify "🎉 $CURRENT_EPIC: $CURRENT_EPIC_NAME - Done!"
        fi

        # Notify new epic starting
        CURRENT_EPIC="$new_epic"
        CURRENT_EPIC_NAME="$new_epic_name"
        notify "🚀 $new_epic: $new_epic_name" "high"
    fi
}

# Notify spec start (with epic)
notify_spec_start() {
    local spec="$1"
    check_epic_change "$spec"

    local prefix=""
    [ -n "$CURRENT_EPIC" ] && prefix="[$CURRENT_EPIC] "
    notify "🔨 ${prefix}$(basename "$spec" .md)"
}

# Notify spec done (with epic)
notify_spec_done() {
    local spec="$1"
    local prefix=""
    [ -n "$CURRENT_EPIC" ] && prefix="[$CURRENT_EPIC] "
    notify "✅ ${prefix}$(basename "$spec" .md)" "low"
}

# Notify spec failed
notify_spec_failed() {
    local spec="$1"
    local prefix=""
    [ -n "$CURRENT_EPIC" ] && prefix="[$CURRENT_EPIC] "
    notify "❌ ${prefix}$(basename "$spec" .md)" "high"
}

# Notify all done
notify_complete() {
    local done="$1"
    local total="$2"

    # Final epic notification
    if [ -n "$CURRENT_EPIC" ]; then
        notify "🎉 $CURRENT_EPIC: $CURRENT_EPIC_NAME - Done!"
    fi

    notify "🏁 Ralph complete: $done/$total specs" "high"
}
