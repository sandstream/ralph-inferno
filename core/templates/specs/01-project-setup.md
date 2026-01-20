# 01-project-setup

> Epic: Foundation
> Dependencies: None (första spec)

---

## Mål

Sätt upp projektets grundstruktur med alla nödvändiga verktyg för att Ralph ska kunna bygga och testa autonomt.

---

## Functional Requirements (FR)

### FR1: Vite + React + TypeScript
Skapa nytt projekt med modern stack.

**Acceptance Criteria:**
- [ ] `npm run dev` startar dev-server
- [ ] `npm run build` bygger utan errors
- [ ] TypeScript strict mode aktiverat

### FR2: Tailwind CSS
Konfigurera Tailwind med design tokens från PRD.

**Acceptance Criteria:**
- [ ] Tailwind klasser fungerar
- [ ] Design tokens från PRD i `tailwind.config.js`
- [ ] CSS-variabler för tema

### FR3: Playwright E2E Testing
> ⚠️ KRITISKT för Ralph's test-loop

**Acceptance Criteria:**
- [ ] `npx playwright install` kört
- [ ] `playwright.config.ts` konfigurerad
- [ ] `e2e/` mapp skapad
- [ ] Smoke test finns och passerar

### FR4: Vitest Unit Testing (om relevant)

**Acceptance Criteria:**
- [ ] `npm test` fungerar
- [ ] Exempel-test passerar

---

## Technical Implementation

### Kommandon att köra
```bash
# 1. Skapa projekt
npm create vite@latest . -- --template react-ts

# 2. Installera dependencies
npm install

# 3. Tailwind
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# 4. Playwright (KRITISKT!)
npm install -D @playwright/test
npx playwright install

# 5. Skapa playwright.config.ts
# 6. Skapa e2e/smoke.spec.ts
```

### Filer att skapa

**playwright.config.ts:**
```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
  },
});
```

**e2e/smoke.spec.ts:**
```typescript
import { test, expect } from '@playwright/test';

test('app loads successfully', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/./);  // Any title
  // Add more specific checks based on your app
});
```

**tailwind.config.js** (med design tokens):
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Lägg till från PRD Design System
        primary: 'var(--color-primary)',
        accent: 'var(--color-accent)',
        // ...
      },
      // Spacing, fonts etc från PRD
    },
  },
  plugins: [],
};
```

---

## E2E Test

**Testfil:** `e2e/smoke.spec.ts`

**Tester att skriva:**
```typescript
test('app loads and shows content', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('body')).toBeVisible();
});
```

---

## Klart när

- [ ] `npm run dev` fungerar
- [ ] `npm run build` passerar
- [ ] `npx playwright test` passerar
- [ ] Tailwind fungerar (testa med en klass)
- [ ] Design tokens från PRD i config
- [ ] Projektstruktur enligt AGENTS.md / CLAUDE.md
