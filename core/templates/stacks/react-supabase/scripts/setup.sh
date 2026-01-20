#!/bin/bash
# setup.sh - React + Supabase stack setup
#
# Körs automatiskt av Ralph vid projektstart
# KRAV: Docker måste köra för Supabase

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "🚀 React + Supabase Setup"
echo "========================="

# 1. Installera dependencies om package.json finns
if [ -f "package.json" ]; then
    if [ ! -d "node_modules" ]; then
        echo "📦 Installerar npm dependencies..."
        npm install
    fi
fi

# 2. Kolla Docker (KRAV)
echo "🐳 Kollar Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker ej installerat"
    echo "   Installera Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "⚠️  Docker körs inte - försöker starta..."

    # Försök starta Docker
    if command -v systemctl &> /dev/null; then
        sudo systemctl start docker 2>/dev/null || true
        sleep 3
    fi

    # Kolla igen
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Kunde inte starta Docker"
        echo "   Starta Docker manuellt och kör setup igen"
        exit 1
    fi
fi
echo "   ✅ Docker OK"

# 3. Playwright för E2E-tester
echo "🎭 Kollar Playwright..."
if [ ! -f "playwright.config.ts" ] && [ ! -f "playwright.config.js" ]; then
    echo "   📦 Installerar Playwright..."
    npm install -D @playwright/test
    npx playwright install chromium --with-deps 2>/dev/null || npx playwright install chromium

    # Skapa minimal config om saknas
    cat > playwright.config.ts << 'EOF'
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  use: {
    baseURL: 'http://localhost:5173',
    headless: true,
  },
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: true,
  },
});
EOF

    # Skapa e2e-mapp (agenten ska skapa riktiga tester)
    mkdir -p e2e
    cat > e2e/.gitkeep << 'EOF'
# E2E-tester ska skapas av agenten
# Se AGENTS.md / CLAUDE.md för krav på E2E-tester
# Tester ska verifiera hela användarflödet, inte bara att sidan laddar
EOF
    echo "   ✅ Playwright installerat (agenten skapar E2E-tester)"
else
    echo "   ✅ Playwright config finns"
fi

# 3. Supabase setup
if [ -d "supabase" ] || [ -f "supabase/config.toml" ]; then
    echo "📊 Startar Supabase..."

    # Starta om inte redan igång
    if ! supabase status > /dev/null 2>&1; then
        supabase start
    fi

    # Hämta credentials
    API_URL=$(supabase status 2>/dev/null | grep -E "API URL|Project URL" | awk '{print $NF}' | head -1)
    ANON_KEY=$(supabase status 2>/dev/null | grep -E "anon key|Publishable" | awk '{print $NF}' | head -1)

    if [ -z "$API_URL" ]; then
        API_URL="http://127.0.0.1:54321"
    fi

    # Uppdatera .env
    if [ -n "$ANON_KEY" ]; then
        echo "📝 Uppdaterar .env..."

        # Ta bort gamla SUPABASE-rader
        if [ -f ".env" ]; then
            grep -v "SUPABASE" .env > .env.tmp 2>/dev/null || true
            mv .env.tmp .env
        fi

        echo "VITE_SUPABASE_URL=$API_URL" >> .env
        echo "VITE_SUPABASE_ANON_KEY=$ANON_KEY" >> .env

        echo "✅ .env konfigurerad"
    fi

    # Kör migrations om finns
    if [ -d "supabase/migrations" ] && [ -n "$(ls supabase/migrations/*.sql 2>/dev/null)" ]; then
        echo "📊 Kör databasmigrering..."
        supabase db reset --no-seed 2>/dev/null || supabase db reset
    fi
fi

# 4. ntfy för notifikationer
echo "📣 Kollar ntfy..."
RALPH_CONFIG="$HOME/.ralph-vm"
if [ -f "$RALPH_CONFIG" ]; then
    source "$RALPH_CONFIG"
fi

if [ -z "${NTFY_TOPIC:-}" ]; then
    # Generera unik topic baserat på projekt + timestamp
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    RANDOM_SUFFIX=$(head -c 4 /dev/urandom | xxd -p)
    NTFY_TOPIC="ralph-${PROJECT_NAME}-${RANDOM_SUFFIX}"

    echo "   📝 Skapar ntfy topic: $NTFY_TOPIC"
    echo "NTFY_TOPIC=$NTFY_TOPIC" >> "$RALPH_CONFIG"

    echo "   💡 Prenumerera på: https://ntfy.sh/$NTFY_TOPIC"
    echo "   📱 Eller i ntfy-appen: $NTFY_TOPIC"
else
    echo "   ✅ ntfy topic: $NTFY_TOPIC"
fi

# Skicka test-notis
if command -v curl &> /dev/null; then
    curl -s -d "Ralph setup klar för $(basename $PROJECT_DIR)" "ntfy.sh/${NTFY_TOPIC}" > /dev/null 2>&1 || true
fi

echo ""
echo "✅ Setup klar!"
echo ""
echo "📣 ntfy: https://ntfy.sh/${NTFY_TOPIC}"
