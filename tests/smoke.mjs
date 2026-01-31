import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import assert from 'node:assert/strict';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const repoRoot = dirname(__dirname);

const claudeCommand = join(repoRoot, 'core', '.claude', 'commands', 'ralph:idea.md');
const codexPrompt = join(repoRoot, 'core', '.codex', 'prompts', 'ralph-idea.md');

assert.ok(existsSync(claudeCommand), 'Missing Claude command: ralph:idea.md');
assert.ok(existsSync(codexPrompt), 'Missing Codex prompt: ralph-idea.md');

const result = spawnSync(process.execPath, [
  join(repoRoot, 'bin', 'ralph-inferno.js'),
  '--help'
], { encoding: 'utf8' });

assert.equal(result.status, 0, `CLI --help failed: ${result.stderr}`);
assert.ok(
  result.stdout.includes('AI-driven autonomous development workflow'),
  'CLI help output missing description'
);

console.log('smoke tests passed');
