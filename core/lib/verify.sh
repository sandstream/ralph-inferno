#!/bin/bash
# verify.sh - Build verification with self-healing
# Source this file: source lib/verify.sh

# Also source selfheal if not already loaded
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -z "${SELFHEAL_LOADED:-}" ] && source "$SCRIPT_DIR/selfheal.sh"

# Detect build command based on project type
detect_build_cmd() {
    # Check for custom config first
    if [ -f ".ralph/config.json" ]; then
        local custom_cmd
        custom_cmd=$(grep -o '"build_cmd"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
        [ -n "$custom_cmd" ] && echo "$custom_cmd" && return
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
        echo ""  # No build needed
    fi
}

# Detect test command based on project type
detect_test_cmd() {
    # Check for custom config first
    if [ -f ".ralph/config.json" ]; then
        local custom_cmd
        custom_cmd=$(grep -o '"test_cmd"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
        [ -n "$custom_cmd" ] && echo "$custom_cmd" && return
    fi

    # Auto-detect based on project files
    if [ -f "Makefile" ] && grep -q "^test:" Makefile 2>/dev/null; then
        echo "make test"
    elif [ -f "Cargo.toml" ]; then
        echo "cargo test"
    elif [ -f "go.mod" ]; then
        echo "go test ./..."
    elif [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
        echo "npm test"
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "pytest"
    else
        echo ""  # No tests
    fi
}

# Verify build passes
verify_build() {
    local max_attempts=${1:-3}
    local attempt=0

    # Ensure dependencies first
    ensure_deps || true

    local build_cmd
    build_cmd=$(detect_build_cmd)

    # No build command detected, assume success
    [ -z "$build_cmd" ] && return 0

    while [ $attempt -lt $max_attempts ]; do
        ((attempt++))

        local output
        local exit_code=0

        output=$($build_cmd 2>&1) || exit_code=$?

        if [ $exit_code -eq 0 ]; then
            return 0
        fi

        # Only show errors (saves tokens)
        echo "$output" | grep -E "(error|Error|ERROR|FAIL|failed|Failed|✗|❌)" | head -20

        # Try self-heal
        if try_selfheal "$output"; then
            continue
        fi

        # No self-heal possible, fail
        return 1
    done

    return 1
}

# Verify tests pass
verify_tests() {
    local test_cmd
    test_cmd=$(detect_test_cmd)

    # No test command detected, assume success
    [ -z "$test_cmd" ] && return 0

    local output
    output=$($test_cmd 2>&1) || {
        # Only show failed tests (saves tokens)
        echo "$output" | grep -E "(FAIL|failed|Failed|✗|❌|Error)" | head -30
        return 1
    }
    return 0
}

# Full verification (build + tests)
verify_all() {
    verify_build || return 1
    verify_tests || return 1
    return 0
}
