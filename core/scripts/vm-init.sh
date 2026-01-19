#!/bin/bash
# vm-init.sh - Run automatically when VM starts
# Installs everything needed for Ralph

set -e

echo "=== Ralph VM Setup ==="

# Update system
sudo apt-get update

# Install basic tools
sudo apt-get install -y curl git ripgrep jq tmux

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Fix nvm path issues - add to profile if using nvm
if [ -d "$HOME/.nvm" ]; then
    echo "=== Configuring nvm path ==="
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Add to bashrc if not already there
    if ! grep -q "NVM_DIR" ~/.bashrc 2>/dev/null; then
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
    fi
fi

# Install Claude Code CLI
sudo npm install -g @anthropic-ai/claude-code

# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update
sudo apt-get install -y gh

# Install Playwright dependencies (for E2E tests)
echo "=== Installing Playwright dependencies ==="
sudo npx playwright install-deps || true
npx playwright install || true

# Create workspace
mkdir -p ~/workspace
mkdir -p ~/scripts
mkdir -p ~/specs

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Next steps (one-time configuration):"
echo ""
echo "1. Authenticate Claude (choose ONE):"
echo ""
echo "   Option A - Claude Subscription (simplest):"
echo "     claude login"
echo ""
echo "   Option B - Anthropic API Key:"
echo "     export ANTHROPIC_API_KEY=\"sk-ant-...\""
echo ""
echo "   Option C - AWS Bedrock:"
echo "     export CLAUDE_CODE_USE_BEDROCK=1"
echo "     export ANTHROPIC_MODEL=\"us.anthropic.claude-sonnet-4-20250514-v1:0\""
echo "     export AWS_REGION=\"us-east-1\""
echo "     export AWS_ACCESS_KEY_ID=\"...\""
echo "     export AWS_SECRET_ACCESS_KEY=\"...\""
echo ""
echo "   Option D - Azure AI Foundry:"
echo "     export CLAUDE_CODE_USE_FOUNDRY=1"
echo "     export ANTHROPIC_FOUNDRY_BASE_URL=\"https://your-resource.services.ai.azure.com/api/v1\""
echo "     export ANTHROPIC_FOUNDRY_API_KEY=\"...\""
echo "     export ANTHROPIC_FOUNDRY_RESOURCE=\"your-resource-name\""
echo ""
echo "   Tip: Add exports to ~/.bashrc to persist across sessions"
echo ""
echo "2. Log in to GitHub:  gh auth login"
echo ""
echo "Then the VM is ready for Ralph!"
