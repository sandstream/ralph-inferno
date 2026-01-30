import inquirer from 'inquirer';
import chalk from 'chalk';
import fs from 'fs-extra';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { execSync } from 'child_process';
import { homedir } from 'os';

// Auto-detect GitHub username from gh CLI
function getGitHubUsername() {
  try {
    return execSync('gh api user --jq ".login"', { stdio: ['pipe', 'pipe', 'ignore'] })
      .toString()
      .trim();
  } catch {
    return '';
  }
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const CORE_DIR = join(__dirname, '..', 'core');
const TARGET_DIR = '.ralph';
const CONFIG_FILE = join(TARGET_DIR, 'config.json');
const PKG_JSON = join(__dirname, '..', 'package.json');

// Get version from package.json
function getVersion() {
  try {
    const pkg = fs.readJsonSync(PKG_JSON);
    return pkg.version;
  } catch {
    return '1.0.0';
  }
}

// Check if CLI tool is installed
function checkCli(cmd) {
  try {
    execSync(`which ${cmd}`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

export async function install() {
  // Röd/orange brick-stil som i originalet
  const fire = chalk.hex('#FF6B35');
  const brick = chalk.hex('#C84B31');
  const gold = chalk.hex('#FFD700');

  console.log(fire(`
  🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
  🔥                                              🔥
  🔥  `) + brick(`██████╗  █████╗ ██╗     ██████╗ ██╗  ██╗`) + fire(`    🔥
  🔥  `) + brick(`██╔══██╗██╔══██╗██║     ██╔══██╗██║  ██║`) + fire(`    🔥
  🔥  `) + brick(`██████╔╝███████║██║     ██████╔╝███████║`) + fire(`    🔥
  🔥  `) + brick(`██╔══██╗██╔══██║██║     ██╔═══╝ ██╔══██║`) + fire(`    🔥
  🔥  `) + brick(`██║  ██║██║  ██║███████╗██║     ██║  ██║`) + fire(`    🔥
  🔥  `) + brick(`╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝`) + fire(`    🔥
  🔥                                              🔥
  🔥          `) + gold(`I N F E R N O   M O D E`) + fire(`             🔥
  🔥                                              🔥
  🔥  `) + gold(`Build while you sleep. Wake to working code`) + fire(` 🔥
  🔥                   🌙 → ☀️`) + fire(`                     🔥
  🔥                                              🔥
  🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
`));

  // Disclaimer
  console.log(chalk.yellow(`
⚠️  DISCLAIMER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ralph Inferno runs AI-driven autonomous code.

`), chalk.red(`
🔴 ALWAYS RUN RALPH IN AN EXTERNAL SANDBOX ENVIRONMENT!
   Use a disposable VM that can be destroyed if something goes wrong.
   NEVER run Ralph directly on your local machine.
`), chalk.yellow(`
• YOU are fully responsible for all actions performed
• Review generated code before running in production
• NEVER store sensitive credentials in code or config
• Ralph can make mistakes - monitor and verify results

By continuing, you accept full responsibility for usage.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`));

  const { acceptDisclaimer } = await inquirer.prompt([{
    type: 'rawlist',
    name: 'acceptDisclaimer',
    message: 'Do you accept the terms above?',
    choices: [
      { name: 'Yes, I understand and accept', value: true },
      { name: 'No, cancel installation', value: false }
    ]
  }]);

  if (!acceptDisclaimer) {
    console.log(chalk.dim('Installation cancelled.'));
    return;
  }

  console.log('');

  // Check if already installed
  if (await fs.pathExists(CONFIG_FILE)) {
    const { overwrite } = await inquirer.prompt([{
      type: 'confirm',
      name: 'overwrite',
      message: 'Ralph is already installed. Reinstall? (config will be preserved)',
      default: false
    }]);

    if (!overwrite) {
      console.log(chalk.yellow('Use "ralph-inferno update" to update core files.'));
      return;
    }
  }

  // Collect configuration (rawlist = numbered choices)
  const answers = await inquirer.prompt([
    {
      type: 'rawlist',
      name: 'language',
      message: 'Language?',
      choices: [
        { name: 'English (recommended)', value: 'en' },
        { name: 'Svenska', value: 'sv' },
        { name: 'Español', value: 'es' },
        { name: 'Deutsch', value: 'de' },
        { name: 'Français', value: 'fr' },
        { name: '中文 (Chinese)', value: 'zh' }
      ]
    },
    {
      type: 'rawlist',
      name: 'provider',
      message: 'Cloud Provider for VM?',
      choices: [
        { name: 'Hetzner (hcloud)', value: 'hcloud' },
        { name: 'Google Cloud (gcloud)', value: 'gcloud' },
        { name: 'DigitalOcean (doctl)', value: 'doctl' },
        { name: 'AWS (aws)', value: 'aws' },
        { name: 'Own SSH server', value: 'ssh' },
        { name: 'Skip (no VM)', value: 'none' }
      ]
    }
  ]);

  // Check CLI if provider selected
  if (answers.provider !== 'none' && answers.provider !== 'ssh') {
    const cliName = answers.provider;
    if (!checkCli(cliName)) {
      console.log(chalk.yellow(`\n⚠️  ${cliName} CLI not found.`));
      console.log(chalk.dim(`Install with: brew install ${cliName === 'gcloud' ? '--cask google-cloud-sdk' : cliName}`));
    } else {
      console.log(chalk.green(`✓ ${cliName} CLI found`));
    }
  }

  // VM-specific questions
  let vmConfig = {};
  if (answers.provider !== 'none') {
    const vmAnswers = await inquirer.prompt([
      {
        type: 'input',
        name: 'vm_name',
        message: 'VM name?',
        default: 'ralph-sandbox'
      },
      {
        type: 'input',
        name: 'region',
        message: 'Region?',
        default: answers.provider === 'hcloud' ? 'fsn1' :
                 answers.provider === 'gcloud' ? 'europe-north1-a' :
                 answers.provider === 'doctl' ? 'fra1' : 'eu-west-1'
      }
    ]);
    vmConfig = vmAnswers;
  }

  // Notifications
  const notifyAnswers = await inquirer.prompt([
    {
      type: 'rawlist',
      name: 'useNtfy',
      message: 'Enable ntfy.sh notifications?',
      choices: [
        { name: 'Yes (recommended)', value: true },
        { name: 'No', value: false }
      ]
    },
    {
      type: 'input',
      name: 'ntfyTopic',
      message: 'ntfy.sh topic name (use a unique name!)?',
      when: (a) => a.useNtfy,
      default: `ralph-${Date.now()}`
    }
  ]);

  // GitHub - auto-detect from gh CLI
  const detectedGithub = getGitHubUsername();
  if (detectedGithub) {
    console.log(chalk.green(`✓ GitHub detected: ${detectedGithub}`));
  }

  const githubAnswers = await inquirer.prompt([
    {
      type: 'input',
      name: 'github_username',
      message: 'GitHub username?',
      default: detectedGithub
    }
  ]);

  // Agent selection
  const agentAnswers = await inquirer.prompt([
    {
      type: 'rawlist',
      name: 'agent',
      message: 'Which CLI will run on the VM?',
      choices: [
        { name: 'Claude Code (default)', value: 'claude' },
        { name: 'Codex CLI', value: 'codex' },
        { name: 'GitHub Copilot CLI', value: 'copilot' }
      ]
    }
  ]);

  let authAnswers = {};
  if (agentAnswers.agent === 'claude') {
    authAnswers = await inquirer.prompt([
      {
        type: 'rawlist',
        name: 'claudeAuth',
        message: 'How will Claude authenticate on the VM?',
        choices: [
          { name: 'Claude Pro/Max subscription (recommended)', value: 'subscription' },
          { name: 'Anthropic API key', value: 'api_key' }
        ]
      }
    ]);

    if (authAnswers.claudeAuth === 'subscription') {
      console.log(chalk.cyan(`
┌─────────────────────────────────────────────────────────────┐
│  Claude Subscription Setup                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  After VM is created, SSH in and run:                       │
│                                                             │
│    claude login                                             │
│                                                             │
│  This will open a browser to authenticate.                  │
│  You only need to do this once per VM.                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
`));
    } else {
      console.log(chalk.cyan(`
┌─────────────────────────────────────────────────────────────┐
│  Anthropic API Key Setup                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  After VM is created, set the environment variable:         │
│                                                             │
│    export ANTHROPIC_API_KEY="sk-ant-..."                    │
│                                                             │
│  Add to ~/.bashrc for persistence:                          │
│                                                             │
│    echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc│
│                                                             │
└─────────────────────────────────────────────────────────────┘
`));
    }
  } else if (agentAnswers.agent === 'codex') {
    authAnswers = await inquirer.prompt([
      {
        type: 'rawlist',
        name: 'codexAuth',
        message: 'How will Codex authenticate on the VM?',
        choices: [
          { name: 'Codex login (ChatGPT account) (recommended)', value: 'account' },
          { name: 'OpenAI API key', value: 'api_key' }
        ]
      }
    ]);

    if (authAnswers.codexAuth === 'account') {
      console.log(chalk.cyan(`
┌─────────────────────────────────────────────────────────────┐
│  Codex Login Setup                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  After VM is created, SSH in and run:                       │
│                                                             │
│    codex login                                              │
│                                                             │
│  This will open a browser to authenticate.                  │
│  You only need to do this once per VM.                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
`));
    } else {
      console.log(chalk.cyan(`
┌─────────────────────────────────────────────────────────────┐
│  OpenAI API Key Setup                                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  After VM is created, set the environment variable:         │
│                                                             │
│    export OPENAI_API_KEY="sk-..."                           │
│                                                             │
│  Or authenticate once via:                                  │
│                                                             │
│    echo "$OPENAI_API_KEY" | codex login --with-api-key       │
│                                                             │
│  Add to ~/.bashrc for persistence:                          │
│                                                             │
│    echo 'export OPENAI_API_KEY="sk-..."' >> ~/.bashrc        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
`));
    }
  } else if (agentAnswers.agent === 'copilot') {
    console.log(chalk.cyan(`
┌─────────────────────────────────────────────────────────────┐
│  GitHub Copilot CLI Setup                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Install Copilot CLI:                                    │
│                                                             │
│     gh extension install github/copilot-cli                 │
│                                                             │
│  2. Start Copilot:                                          │
│                                                             │
│     copilot                                                 │
│                                                             │
│  3. Use Ralph prompts:                                      │
│                                                             │
│     /prompt:ralph-idea "your idea"                          │
│                                                             │
│  Requires Copilot Pro/Pro+/Business/Enterprise subscription │
│                                                             │
└─────────────────────────────────────────────────────────────┘
`));
    authAnswers.copilotAuth = 'github';
  }

  // Build config
  const config = {
    version: getVersion(),
    language: answers.language,
    provider: answers.provider,
    ...vmConfig,
    vm_ip: '',
    user: process.env.USER || '',
    notifications: {
      ntfy_enabled: notifyAnswers.useNtfy,
      ntfy_topic: notifyAnswers.ntfyTopic || ''
    },
    github: {
      username: githubAnswers.github_username
    },
    agent: agentAnswers.agent
  };

  if (agentAnswers.agent === 'claude') {
    config.claude = { auth_method: authAnswers.claudeAuth };
  } else if (agentAnswers.agent === 'codex') {
    config.codex = { auth_method: authAnswers.codexAuth };
  } else if (agentAnswers.agent === 'copilot') {
    config.copilot = { auth_method: authAnswers.copilotAuth || 'github' };
  }

  // Install core files
  console.log(chalk.cyan('\nInstalling...'));

  await fs.ensureDir(TARGET_DIR);

  // Copy core directories
  const dirs = ['lib', 'scripts', 'templates', '.claude', '.codex', '.github'];
  for (const dir of dirs) {
    const src = join(CORE_DIR, dir);
    const dest = join(TARGET_DIR, dir);
    if (await fs.pathExists(src)) {
      await fs.copy(src, dest);
      const files = await fs.readdir(dest).catch(() => []);
      console.log(chalk.green(`✅ ${dir}/ installed (${files.length} items)`));
    }
  }

  // Also copy .claude/commands to project root (where Claude Code reads from)
  const claudeSrc = join(CORE_DIR, '.claude', 'commands');
  const claudeDest = join('.claude', 'commands');
  if (await fs.pathExists(claudeSrc)) {
    await fs.ensureDir('.claude');
    await fs.copy(claudeSrc, claudeDest, { overwrite: true });
    console.log(chalk.green('✅ .claude/commands/ synced to project root'));
  }

  // Also copy .github/prompts to project root (where Copilot CLI reads from)
  const githubSrc = join(CORE_DIR, '.github', 'prompts');
  const githubDest = join('.github', 'prompts');
  if (await fs.pathExists(githubSrc)) {
    await fs.ensureDir('.github');
    await fs.copy(githubSrc, githubDest, { overwrite: true });
    console.log(chalk.green('✅ .github/prompts/ synced to project root'));
  }

  // Also sync Codex prompts to ~/.codex/prompts
  const codexPromptsSrc = join(CORE_DIR, '.codex', 'prompts');
  const codexPromptsDest = join(homedir(), '.codex', 'prompts');
  if (await fs.pathExists(codexPromptsSrc)) {
    await fs.ensureDir(codexPromptsDest);
    await fs.copy(codexPromptsSrc, codexPromptsDest, { overwrite: true });
    console.log(chalk.green('✅ ~/.codex/prompts/ synced'));
  }

  // Save version file for update checking
  await fs.writeFile(join(TARGET_DIR, 'version'), config.version);
  console.log(chalk.green(`✅ version ${config.version}`));

  // Save config
  await fs.writeJson(CONFIG_FILE, config, { spaces: 2 });
  console.log(chalk.green('✅ config.json created'));

  // Create ralph wrapper script
  const wrapperPath = 'ralph';
  await fs.writeFile(wrapperPath, `#!/bin/bash
# Ralph CLI wrapper
RALPH_DIR=".ralph"
exec "$RALPH_DIR/scripts/ralph.sh" "$@"
`);
  await fs.chmod(wrapperPath, '755');
  console.log(chalk.green('✅ ralph wrapper created'));

  // Done
  console.log(chalk.green(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              🔥 RALPH INFERNO INSTALLED! 🔥               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
`));

  console.log(chalk.cyan('Next steps:'));
  console.log(chalk.dim('  1. Start Claude Code: claude'));
  console.log(chalk.dim('  2. Run /ralph:idea "your app idea"'));
  console.log(chalk.dim('  3. Then: /ralph:discover → /ralph:plan → /ralph:preflight → /ralph:deploy'));
  console.log('');
  console.log(chalk.dim('Or with Codex CLI: codex then use /prompts:ralph-*'));
  console.log(chalk.dim('Or with Copilot CLI: copilot then use /prompt:ralph-idea'));
  console.log('');
}
