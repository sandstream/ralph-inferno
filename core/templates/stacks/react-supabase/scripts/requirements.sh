#!/bin/bash
#
# requirements.sh - Kolla och installera dependencies för react-supabase stack
#
# Usage:
#   ./requirements.sh [--check|--install|--fix]
#
# Modes:
#   --check   Bara kolla, returnera exit code (default)
#   --install Installera saknade dependencies
#   --fix     Samma som --install
#

set -uo pipefail

# Färger
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODE="${1:---check}"
MISSING=()
WARNINGS=()

log() { echo -e "$1"; }
ok() { log "${GREEN}✅ $1${NC}"; }
fail() { log "${RED}❌ $1${NC}"; MISSING+=("$1"); }
warn() { log "${YELLOW}⚠️ $1${NC}"; WARNINGS+=("$1"); }

# =============================================================================
# REQUIRED DEPENDENCIES
# =============================================================================
check_required() {
    log "${BLUE}=== REQUIRED ===${NC}"

    # Node.js
    if command -v node &>/dev/null; then
        local node_ver=$(node --version)
        ok "Node.js $node_ver"
    else
        fail "Node.js - MISSING"
    fi

    # npm
    if command -v npm &>/dev/null; then
        local npm_ver=$(npm --version)
        ok "npm $npm_ver"
    else
        fail "npm - MISSING"
    fi

    # git
    if command -v git &>/dev/null; then
        local git_ver=$(git --version | awk '{print $3}')
        ok "git $git_ver"
    else
        fail "git - MISSING"
    fi

    # TypeScript (global)
    if command -v tsc &>/dev/null; then
        local tsc_ver=$(tsc --version | awk '{print $2}')
        ok "TypeScript $tsc_ver"
    else
        fail "TypeScript (tsc) - MISSING"
    fi

    # gh CLI
    if command -v gh &>/dev/null; then
        local gh_ver=$(gh --version | head -1 | awk '{print $3}')
        ok "gh CLI $gh_ver"
    else
        fail "gh CLI - MISSING"
    fi

    # Agent CLI (Codex or Claude)
    if command -v codex &>/dev/null; then
        ok "Codex CLI installed"
    elif command -v claude &>/dev/null; then
        ok "Claude CLI installed"
    else
        fail "Codex/Claude CLI - MISSING"
    fi
}

# =============================================================================
# OPTIONAL DEPENDENCIES (för full funktionalitet)
# =============================================================================
check_optional() {
    log ""
    log "${BLUE}=== OPTIONAL ===${NC}"

    # Docker (för lokal Supabase)
    if command -v docker &>/dev/null; then
        local docker_ver=$(docker --version | awk '{print $3}' | tr -d ',')
        ok "Docker $docker_ver"
    else
        warn "Docker - MISSING (behövs för lokal Supabase)"
    fi

    # Supabase CLI
    if command -v supabase &>/dev/null; then
        local supa_ver=$(supabase --version 2>/dev/null || echo "unknown")
        ok "Supabase CLI $supa_ver"
    else
        warn "Supabase CLI - MISSING"
    fi

    # Playwright (för E2E)
    if npx playwright --version &>/dev/null 2>&1; then
        ok "Playwright installed"
    else
        warn "Playwright - MISSING (behövs för E2E-tester)"
    fi
}

# =============================================================================
# AUTH STATUS
# =============================================================================
check_auth() {
    log ""
    log "${BLUE}=== AUTH STATUS ===${NC}"

    # gh auth
    if gh auth status &>/dev/null 2>&1; then
        local gh_user=$(gh auth status 2>&1 | grep "Logged in" | awk '{print $NF}')
        ok "gh: Logged in as $gh_user"
    else
        fail "gh: NOT AUTHENTICATED"
    fi

    # Agent auth (Codex or Claude)
    if command -v codex &>/dev/null; then
        if codex login status &>/dev/null 2>&1; then
            ok "Codex: Authenticated"
        else
            fail "Codex: NOT AUTHENTICATED"
        fi
    elif command -v claude &>/dev/null; then
        if claude auth status &>/dev/null 2>&1; then
            ok "Claude: Authenticated"
        else
            fail "Claude: NOT AUTHENTICATED"
        fi
    fi
}

# =============================================================================
# INSTALL MISSING
# =============================================================================
install_missing() {
    log ""
    log "${BLUE}=== INSTALLING MISSING ===${NC}"

    for dep in "${MISSING[@]}"; do
        case "$dep" in
            *"TypeScript"*)
                log "Installing TypeScript..."
                npm install -g typescript && ok "TypeScript installed" || fail "TypeScript install failed"
                ;;
            *"Supabase CLI"*)
                log "Installing Supabase CLI..."
                npm install -g supabase && ok "Supabase CLI installed" || warn "Supabase CLI install failed"
                ;;
            *"Playwright"*)
                log "Installing Playwright..."
                npx playwright install && ok "Playwright installed" || warn "Playwright install failed"
                ;;
            *"gh:"*|*"Codex:"*|*"Claude:"*)
                log "${YELLOW}$dep kräver manuell autentisering:${NC}"
                if [[ "$dep" == *"gh:"* ]]; then
                    log "  gh auth login"
                elif [[ "$dep" == *"Codex:"* ]]; then
                    log "  codex login"
                else
                    log "  claude login"
                fi
                ;;
            *"Node.js"*|*"npm"*|*"git"*|*"gh CLI"*|*"Codex/Claude CLI"*|*"Docker"*)
                log "${YELLOW}$dep måste installeras manuellt${NC}"
                ;;
        esac
    done
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log ""
    log "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    log "${BLUE}║       REQUIREMENTS CHECK: react-supabase                  ║${NC}"
    log "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    log ""

    check_required
    check_optional
    check_auth

    # Summary
    log ""
    log "${BLUE}=== SUMMARY ===${NC}"

    if [ ${#MISSING[@]} -eq 0 ]; then
        log ""
        log "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
        log "${GREEN}║                    ✅ VM READY                             ║${NC}"
        log "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
        log ""
        return 0
    else
        log ""
        log "${RED}Missing (${#MISSING[@]}):${NC}"
        for m in "${MISSING[@]}"; do
            log "  - $m"
        done

        if [ ${#WARNINGS[@]} -gt 0 ]; then
            log ""
            log "${YELLOW}Warnings (${#WARNINGS[@]}):${NC}"
            for w in "${WARNINGS[@]}"; do
                log "  - $w"
            done
        fi

        # Install mode?
        if [[ "$MODE" == "--install" ]] || [[ "$MODE" == "--fix" ]]; then
            install_missing

            # Re-check
            MISSING=()
            WARNINGS=()
            check_required >/dev/null 2>&1
            check_auth >/dev/null 2>&1

            if [ ${#MISSING[@]} -eq 0 ]; then
                log ""
                log "${GREEN}✅ All fixable issues resolved${NC}"
                return 0
            else
                log ""
                log "${RED}Still missing (requires manual action):${NC}"
                for m in "${MISSING[@]}"; do
                    log "  - $m"
                done
                return 1
            fi
        else
            log ""
            log "Kör med ${CYAN}--install${NC} för att fixa automatiskt"
            return 1
        fi
    fi
}

main "$@"
