# /ralph:discover - Interactive Requirements Discovery

Start an interactive discovery session to create a PRD and set up the project.

## Usage
```
/ralph:discover [project-name]
/ralph:discover my-app
/ralph:discover my-app --input meeting-notes.md
```

## LANGUAGE SETTING

**FIRST: Detect language automatically**
```bash
LANG=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' .ralph/config.json 2>/dev/null | cut -d'"' -f4)
echo "Language: ${LANG:-en}"
```

Use the detected language (default: English) for ALL output (PRD, questions, comments).
- `en` → Write everything in English
- `sv` → Write everything in Swedish
- etc.

**IMPORTANT:** This includes specs, documentation, and user-facing text.

## CRITICAL INSTRUCTIONS

**NUMBERED CHOICES FORMAT - MANDATORY:**
You MUST present ALL choices as numbered lists. Users respond with just a number.

Format EVERY question exactly like this:
```
[Question text]

1) Option one
2) Option two
3) Option three

Reply with number:
```

NEVER ask open-ended questions when there are known options.
ALWAYS wait for user to reply with a number before proceeding.
If user types something other than a number, ask them to reply with just the number.

---

## STEP 1: Project type

```
What type of project?

1) Greenfield - New project from scratch
2) Brownfield - Existing project

Reply with number:
```

---

## STEP 2: Project basics (Greenfield) or Source (Brownfield)

### If Greenfield:

Ask description first (free text): "What are we building?"

Then suggest a project name based on the description:
```
Suggested project name: {smart-name-based-on-description}

1) Use this name
2) Enter my own name

Reply with number:
```

If user picks 2, ask: "Project name?"

---

## STEP 3: Feature suggestions (Greenfield only)

**MANDATORY: IMMEDIATELY after getting the description, suggest features.**

DO NOT ask "what features do you want?" - ANALYZE the description and SUGGEST.

Examples:

**Todo app** → auth, CRUD todos, complete status, due dates, categories, search, filters
**Blog** → posts, comments, categories, tags, search, admin panel, RSS
**E-commerce** → products, cart, checkout, payments, orders, user accounts
**Chat app** → auth, messages, rooms, real-time, notifications, file sharing

Format EXACTLY like this:
```
Based on "todo app", here are recommended features:

1) User authentication (login/register)
2) Create/edit/delete todos
3) Mark todos as complete
4) Due dates and reminders
5) Categories/tags
6) Search and filter
7) All of the above

Select features (e.g. "1,2,3" or "7" for all):
```

User selects by typing numbers like "1,3,5" or "7" for all.

After selection: "Any additional features? (or 'none'):"

Then: "Any constraints or requirements? (or 'none'):"

---

## STEP 3b: Design preferences (Greenfield only)

```
Do you have design preferences?

1) Yes - I have brand guidelines or a website I like (recommended if you have them)
2) No - Use sensible defaults

Reply with number:
```

If yes, ask:
- "Brand guidelines URL or file path? (or 'none'):"
- "Website you like the design of? (URL or 'none'):"
- "Color preferences? (e.g. 'blue and white', 'dark mode', or 'none'):"

Save these to PRD for reference during build.

---

## STEP 4: Template selection (Greenfield only)

Based on the description, check available templates and recommend:

```bash
ls -1 .ralph/templates/stacks/ 2>/dev/null || echo "none"
```

```
Based on your project, which template?

1) react-supabase - React + Vite + Tailwind + Supabase (recommended for apps with auth/database)
2) custom - Define your own stack

Reply with number:
```

If "custom" was selected:
```
Frontend framework?

1) React + Vite
2) Next.js
3) Vue
4) Svelte
5) Other

Reply with number:
```

```
Backend?

1) Supabase
2) Firebase
3) PostgreSQL + Express
4) None (frontend only)
5) Other

Reply with number:
```

```
Deploy target?

1) Vercel
2) Netlify
3) Railway
4) Own server
5) Not decided yet

Reply with number:
```

---

## STEP 5: Tasks (Brownfield only)

### If Brownfield:

```
Where is the project?

1) GitHub repo
2) Local path

Reply with number:
```

If GitHub: Ask for "GitHub repo (user/repo):"
If local: Ask for "Path to project:"

Then read package.json to detect stack and show what was found.

```
Is this stack detection correct?

1) Yes
2) No, let me adjust

Reply with number:
```

```
What type of work?

1) New features
2) Bug fixes
3) Refactoring
4) Mix of above

Reply with number:
```

Then ask (free text): "List the tasks to do (comma separated):"
Then ask (free text): "Any project context I should know? (or 'none'):"
Then ask (free text): "Files to avoid changing? (or 'none'):"

---

## STEP 6: Credentials (only if relevant)

If Supabase was selected:
```
Do you have Supabase credentials ready?

1) Yes, I'll add them to .env.local (recommended)
2) No, I'll set up Supabase later

Reply with number:
```

If yes, remind them to add to `.env.local`:
- SUPABASE_URL
- SUPABASE_ANON_KEY

Similar for Firebase (FIREBASE_PROJECT_ID, FIREBASE_API_KEY).

**IMPORTANT:** NEVER store credentials in repo! Always use `.env.local` which is gitignored.

---

## STEP 7: Confirm VM setup

Read config and show what's configured:
```bash
cat .ralph/config.json 2>/dev/null
```

Show summary:
```
VM Configuration (from install):
- Provider: {provider}
- Region: {region}
- VM name: {vm_name}

To change: run "npx ralph-inferno install" again
```

---

## STEP 8: Generate output

When all info is collected:

### 1. Create docs/prd.md
```bash
mkdir -p docs
```

PRD should contain:
- Project name and description
- Type (greenfield/brownfield)
- Tech stack
- Features/tasks
- Constraints
- VM/deploy info (if configured)

### 2. Copy template files (if template was selected)
```bash
# Copy CLAUDE.md
cp .ralph/templates/stacks/{template}/CLAUDE.md CLAUDE.md

# Copy requirements.sh to scripts
cp .ralph/templates/stacks/{template}/scripts/requirements.sh .ralph/scripts/requirements.sh 2>/dev/null || true
```

### 3. Generate CLAUDE.md (if no template)

If no template, create CLAUDE.md with:
```markdown
# CLAUDE.md - {projectname}

## Project
{description}

## Tech Stack
- Frontend: {stack}
- Backend: {stack}

## Security Rules

CRITICAL - NEVER do:
- rm -rf / or sudo rm
- curl | bash or wget | bash
- Expose credentials in code
- Commit .env files
- Hardcode API keys

SECRETS HANDLING:
- .env files NEVER in repo
- Use process.env.VAR_NAME
- .gitignore MUST contain .env*

## Workflow
1. Read spec carefully
2. Implement step by step
3. Run tests often
4. Output `<promise>DONE</promise>` when done
```

### 4. Show summary
- Confirm what was created:
  - docs/prd.md - Product Requirements Document
  - CLAUDE.md - Project instructions
- List next steps:
  1. `/ralph:plan` - Create implementation plan from PRD
  2. `/ralph:deploy` - Send to VM and run autonomously
  3. `/ralph:review` - Review results when done

---

## START NOW

Begin by checking templates and asking the first numbered question. Remember: ALL choices must be numbered, user replies with just a number.
