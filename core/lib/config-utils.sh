#!/bin/bash
# config-utils.sh - Centralized config loading for Ralph
# Source this file: source lib/config-utils.sh

# Config file location
RALPH_CONFIG="${RALPH_CONFIG:-.ralph/config.json}"

# Load a value from config.json
# Usage: load_config "key" "default_value"
load_config() {
    local key="$1"
    local default="${2:-}"

    if [ ! -f "$RALPH_CONFIG" ]; then
        echo "$default"
        return
    fi

    local value
    value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$RALPH_CONFIG" 2>/dev/null | cut -d'"' -f4)

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Load a boolean value from config.json
# Usage: load_config_bool "key" "default_value"
load_config_bool() {
    local key="$1"
    local default="${2:-false}"

    if [ ! -f "$RALPH_CONFIG" ]; then
        echo "$default"
        return
    fi

    local value
    value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*[a-z]*" "$RALPH_CONFIG" 2>/dev/null | awk -F':' '{gsub(/[[:space:]]/, "", $2); print $2}')

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Load nested value from config.json (one level deep)
# Usage: load_config_nested "parent" "key" "default_value"
load_config_nested() {
    local parent="$1"
    local key="$2"
    local default="${3:-}"

    if [ ! -f "$RALPH_CONFIG" ]; then
        echo "$default"
        return
    fi

    # Extract parent object and then the key
    local value
    value=$(grep -A20 "\"$parent\"" "$RALPH_CONFIG" 2>/dev/null | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | cut -d'"' -f4)

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Check if config file exists
config_exists() {
    [ -f "$RALPH_CONFIG" ]
}

# Get language setting (used by multiple scripts)
get_language() {
    load_config "language" "en"
}

# Check if ntfy is enabled
is_ntfy_enabled() {
    local enabled
    enabled=$(load_config_bool "ntfy_enabled" "true")
    [ "$enabled" = "true" ]
}

# Get ntfy topic
get_ntfy_topic() {
    load_config "ntfy_topic" ""
}

# Get build command (with auto-detect fallback)
get_build_cmd() {
    local custom_cmd
    custom_cmd=$(load_config "build_cmd" "")

    if [ -n "$custom_cmd" ]; then
        echo "$custom_cmd"
        return
    fi

    # Auto-detect based on project files
    if [ -f "Makefile" ] && grep -q "^build:" Makefile 2>/dev/null; then
        echo "make build"
    elif [ -f "Cargo.toml" ]; then
        echo "cargo build"
    elif [ -f "go.mod" ]; then
        echo "go build ./..."
    elif [ -f "package.json" ]; then
        echo "npm run build"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "python -m build"
    else
        echo ""
    fi
}

# Get test command (with auto-detect fallback)
get_test_cmd() {
    local custom_cmd
    custom_cmd=$(load_config "test_cmd" "")

    if [ -n "$custom_cmd" ]; then
        echo "$custom_cmd"
        return
    fi

    # Auto-detect based on project files
    if [ -f "Makefile" ] && grep -q "^test:" Makefile 2>/dev/null; then
        echo "make test"
    elif [ -f "Cargo.toml" ]; then
        echo "cargo test"
    elif [ -f "go.mod" ]; then
        echo "go test ./..."
    elif [ -f "package.json" ]; then
        echo "npm test"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "pytest"
    else
        echo ""
    fi
}

# Get GitHub username
get_github_username() {
    load_config_nested "github" "username" ""
}

# Get VM IP
get_vm_ip() {
    load_config "vm_ip" ""
}

# Get VM user
get_vm_user() {
    load_config "user" "ubuntu"
}
