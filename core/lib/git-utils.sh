#!/bin/bash
# git-utils.sh - Git commit and push helpers
# Source this file: source lib/git-utils.sh

MAIN_BRANCH="${MAIN_BRANCH:-main}"

# Commit changes
commit_changes() {
    local message="$1"

    [ -z "$(git status --porcelain 2>/dev/null)" ] && return 0

    git add -A
    git commit -m "$message" >/dev/null 2>&1 || true
}

# Push to remote (uses current branch by default)
push_changes() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "$MAIN_BRANCH")
    local branch="${1:-$current_branch}"

    git push origin "$branch" >/dev/null 2>&1 || true
}

# Commit and push (uses current branch by default)
commit_and_push() {
    local message="$1"
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "$MAIN_BRANCH")
    local branch="${2:-$current_branch}"

    commit_changes "$message"
    push_changes "$branch"
}

# Check for dangerous patterns in diff
check_dangerous() {
    local diff_content
    diff_content=$(git diff 2>/dev/null) || return 0

    local dangerous=(
        "rm -rf /"
        "rm -rf ~"
        "sudo rm -rf"
        "chmod -R 777 /"
    )

    for pattern in "${dangerous[@]}"; do
        if echo "$diff_content" | grep -qF "$pattern"; then
            echo "[DANGER] Found: $pattern"
            return 1
        fi
    done

    return 0
}

# Check for secrets in staged files
check_secrets() {
    local patterns=(
        "sk-ant-[a-zA-Z0-9]{20,}"
        "sk-[a-zA-Z0-9]{40,}"
        "ghp_[a-zA-Z0-9]{30,}"
    )

    for pattern in "${patterns[@]}"; do
        if git diff --cached 2>/dev/null | grep -qE "$pattern"; then
            echo "[DANGER] Secret pattern found: $pattern"
            return 1
        fi
    done

    return 0
}
