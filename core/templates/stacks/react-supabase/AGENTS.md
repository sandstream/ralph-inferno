# AGENTS.md - React + Supabase Stack

## Stack
- Frontend: React 18+ med Vite
- Styling: Tailwind CSS
- Backend: Supabase (PostgreSQL, Auth, Realtime)
- Språk: TypeScript

## Projektstruktur

```
src/
├── components/
│   ├── ui/           # Generella UI-komponenter
│   ├── auth/         # Auth-relaterade komponenter
│   └── {feature}/    # Feature-specifika komponenter
├── hooks/            # Custom React hooks
├── contexts/         # React contexts
├── lib/              # Utilities (supabase client, etc)
├── pages/            # Route-komponenter
└── types/            # TypeScript typer
```

## Kodregler

### Komponenter
- En komponent per fil
- Named exports (inte default)
- Varje mapp har `index.ts` som re-exporterar alla komponenter

```typescript
// src/components/ui/index.ts
export { Button } from './Button'
export { Input } from './Input'
export { Card } from './Card'
```

### Hooks
- Prefix med `use`
- Returnera objekt med namngivna värden
- Hantera loading och error states

```typescript
export function useTodos() {
  const [todos, setTodos] = useState<Todo[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // ...

  return { todos, loading, error, addTodo, updateTodo, deleteTodo }
}
```

### Supabase
- Client i `src/lib/supabase.ts`
- Typer i `src/lib/database.types.ts`
- RLS-policies för all data
- Använd `user_id` för row-level access

### Styling
- Använd Tailwind utility classes
- Definiera design tokens i `tailwind.config.js`
- Använd CSS-variabler för teman

## Verifiering

Efter varje epic, kör:
```bash
npm run build          # Inga compile-fel
npm test               # Unit-tester passerar
npx playwright test    # E2E-tester passerar
```

## E2E-tester (Playwright)

E2E-tester ska testa **hela användarflödet**, inte bara att sidan laddar.

**Krav för auth-appar:**
- Testa login-flöde (magic link eller lösenord)
- Hämta magic link från Mailpit (`localhost:54324`) om behövs
- Verifiera att användaren kommer till rätt sida efter login
- Testa CRUD-operationer som inloggad användare

**Exempel på bra E2E-test:**
```typescript
test('user can login and create todo', async ({ page }) => {
  // 1. Gå till login
  await page.goto('/login');

  // 2. Logga in (anpassa efter din auth-metod)
  await page.fill('input[type="email"]', 'test@example.com');
  await page.click('button:has-text("Logga in")');

  // 3. Verifiera redirect till app
  await expect(page).toHaveURL('/');

  // 4. Skapa en todo
  await page.fill('input[placeholder*="todo"]', 'Min nya todo');
  await page.click('button:has-text("Lägg till")');

  // 5. Verifiera att den skapades
  await expect(page.locator('text=Min nya todo')).toBeVisible();
});
```

**VIKTIGT:** Om E2E-tester bara testar att "sidan laddar" - de är för ytliga! Skapa tester som verifierar att appen faktiskt fungerar.

## Supabase Setup

Innan auth-utveckling:
```bash
supabase start                    # Starta lokal instans
supabase db reset                 # Kör migrations
# Uppdatera .env med credentials från 'supabase status'
```

## Port-exponering för testning

För extern testning (browser utanför VM):
```bash
# Dev-server på alla interface
npm run dev -- --host 0.0.0.0

# Supabase är redan exponerad på 0.0.0.0:54321
```

**VIKTIGT för E2E-tester:**
- Playwright körs headless på VM
- Mailpit för magic links: `http://localhost:54324`
- API för att hämta mail programmatiskt: `http://localhost:54324/api/v1/messages`

## Regression Testing

Vid ändringar, säkerställ att existerande funktionalitet inte bryts:

1. **Kör alla unit-tester** - `npm test`
2. **Kör E2E-tester** - `npx playwright test`
3. **Testa manuellt** - Öppna appen och verifiera grundflöden

**Regression test-checklista:**
- [ ] Login fungerar (magic link eller lösenord)
- [ ] CRUD på huvudentitet (t.ex. todos)
- [ ] Logout fungerar
- [ ] Felhantering visas korrekt
- [ ] Responsiv design (mobil/desktop)

## Vanliga Misstag

1. **Glömd export** - Ny komponent måste läggas till i index.ts
2. **Saknad prop** - Kolla att alla required props skickas
3. **Supabase ej startad** - Ger "Failed to fetch" i browser
4. **RLS blockerar** - Kolla policies om data inte visas
5. **Fel redirect-URL** - Kolla `supabase/config.toml` site_url
