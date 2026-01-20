import chalk from 'chalk';
import fs from 'fs-extra';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { homedir } from 'os';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const CORE_DIR = join(__dirname, '..', 'core');
const TARGET_DIR = '.ralph';
const CONFIG_FILE = join(TARGET_DIR, 'config.json');

export async function update() {
  console.log(chalk.cyan(`
🔄 Ralph Inferno Update
`));

  // Check if installed
  if (!await fs.pathExists(CONFIG_FILE)) {
    console.log(chalk.red('❌ Ralph not installed in this directory.'));
    console.log(chalk.dim('Run: npx ralph-inferno install'));
    return;
  }

  // Read existing config
  const config = await fs.readJson(CONFIG_FILE);

  console.log(chalk.dim('Current config:'));
  console.log(chalk.dim(`  Provider: ${config.provider || 'none'}`));
  console.log(chalk.dim(`  Language: ${config.language || 'en'}`));
  console.log(chalk.dim(`  VM: ${config.vm_name || 'not set'}`));
  console.log('');

  // Check for missing required config
  const warnings = [];
  if (!config.provider || config.provider === 'none') {
    warnings.push('provider - VM is required for safe execution');
  }
  if (!config.vm_name) {
    warnings.push('vm_name - No VM name configured');
  }
  if (!config.github?.username) {
    warnings.push('github.username - Needed for repo operations');
  }

  if (warnings.length > 0) {
    console.log(chalk.yellow('⚠️  Missing config:'));
    warnings.forEach(w => console.log(chalk.yellow(`   - ${w}`)));
    console.log(chalk.dim('   Fix with: ralph-inferno config --set key=value\n'));
  }

  // Update core directories
  console.log(chalk.cyan('Updating core files...'));

  const dirs = ['lib', 'scripts', 'templates', '.claude', '.codex'];
  for (const dir of dirs) {
    const src = join(CORE_DIR, dir);
    const dest = join(TARGET_DIR, dir);

    if (await fs.pathExists(src)) {
      // Remove old and copy new
      await fs.remove(dest);
      await fs.copy(src, dest);

      const files = await countFiles(dest);
      console.log(chalk.green(`✅ ${dir}/ updated (${files} files)`));
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

  // Also sync Codex prompts to ~/.codex/prompts
  const codexPromptsSrc = join(CORE_DIR, '.codex', 'prompts');
  const codexPromptsDest = join(homedir(), '.codex', 'prompts');
  if (await fs.pathExists(codexPromptsSrc)) {
    await fs.ensureDir(codexPromptsDest);
    await fs.copy(codexPromptsSrc, codexPromptsDest, { overwrite: true });
    console.log(chalk.green('✅ ~/.codex/prompts/ synced'));
  }

  // Config is preserved (we didn't touch it)
  console.log(chalk.green('✅ config.json preserved'));

  // Update version in config
  const pkg = await fs.readJson(join(__dirname, '..', 'package.json'));
  config.version = pkg.version;
  await fs.writeJson(CONFIG_FILE, config, { spaces: 2 });

  console.log(chalk.green(`
✅ Update complete! (v${pkg.version})
`));
}

async function countFiles(dir) {
  let count = 0;
  const items = await fs.readdir(dir, { withFileTypes: true });

  for (const item of items) {
    if (item.isDirectory()) {
      count += await countFiles(join(dir, item.name));
    } else {
      count++;
    }
  }

  return count;
}
