#!/bin/bash
# test-loop.sh - E2E testing with Playwright + CR generation
# Source this file: source lib/test-loop.sh

TEST_LOOP_LOADED=true

SCRIPT_DIR_TEST_LOOP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR_TEST_LOOP/agent-utils.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR_TEST_LOOP/agent-utils.sh"
fi

# Track CR depth to prevent infinite loops
CR_DEPTH=${CR_DEPTH:-0}
MAX_CR_DEPTH=1  # Only allow 1 level of CR (no CR-of-CR)

# Check if we're in a CR context
is_cr_spec() {
    local spec_name="$1"
    [[ "$spec_name" == CR-fix-* ]]
}

# Run Playwright E2E tests
run_e2e_tests() {
    # Skip if no playwright config
    if [ ! -f "playwright.config.ts" ] && [ ! -f "playwright.config.js" ]; then
        return 0
    fi

    log "${CYAN}Running E2E tests...${NC}"

    local output
    local exit_code=0
    output=$(npx playwright test --reporter=line 2>&1) || exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log "${GREEN}✅ E2E tests passed${NC}"
        return 0
    fi

    log "${RED}❌ E2E tests failed${NC}"
    echo "$output" > .test-output.log

    # Show summary of failures
    echo "$output" | grep -E "(✘|Error|FAIL|failed)" | head -10

    return 1
}

# Generate CR spec from test failure
generate_cr() {
    local spec_name="$1"

    # Prevent CR-of-CR (infinite loop protection)
    if is_cr_spec "$spec_name"; then
        log "${RED}⚠️ CR failed - not generating CR-of-CR${NC}"
        log "${RED}Manual intervention needed${NC}"
        return 1
    fi

    local test_output=$(cat .test-output.log 2>/dev/null)
    local cr_file=".ralph-specs/CR-fix-${spec_name}.md"

    log "${YELLOW}Generating CR: $cr_file${NC}"

    # Let the configured agent analyze and create CR
    local prompt="E2E tests failed after running spec: $spec_name

Test output:
$test_output

Create a Change Request spec to fix this.

Write to: $cr_file

Use this format:
# CR: Fix E2E test failure from $spec_name

**Problem:** [What failed in the test]
**Root cause:** [Why it likely failed]

## Fix
- [Specific code changes needed]

## Klart när
- [ ] E2E tests pass
- [ ] npm run build succeeds"

    run_agent_prompt "$prompt" 300 > /dev/null 2>&1

    if [ -f "$cr_file" ]; then
        log "${GREEN}CR created: $cr_file${NC}"
        return 0
    fi

    log "${RED}Failed to create CR${NC}"
    return 1
}

# =============================================================================
# AGENT IMAGE REVIEW - Design Review
# =============================================================================

# Take screenshots of the app
take_screenshots() {
    local output_dir="${1:-.screenshots}"
    mkdir -p "$output_dir"

    # Skip if no playwright
    if [ ! -f "playwright.config.ts" ] && [ ! -f "playwright.config.js" ]; then
        return 0
    fi

    log "${CYAN}Taking screenshots...${NC}"

    # Take screenshot directly (no @screenshot tests needed)
    node -e "
const { chromium } = require('@playwright/test');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto('http://localhost:5173');
    await page.screenshot({ path: '$output_dir/home.png', fullPage: true });
    await browser.close();
})();
" 2>/dev/null || true

    # Count screenshots
    local count=$(ls -1 "$output_dir"/*.png 2>/dev/null | wc -l | tr -d ' ')
    log "Captured $count screenshot(s)"
}

# Run agent image design review
run_design_review() {
    local spec_name="$1"
    local screenshot_dir=".screenshots"

    # Skip if no screenshots
    if [ ! -d "$screenshot_dir" ] || [ -z "$(ls -A $screenshot_dir 2>/dev/null)" ]; then
        log "${YELLOW}No screenshots for design review${NC}"
        return 0
    fi

    # Skip if no PRD with design system
    if [ ! -f "docs/PRD.md" ]; then
        return 0
    fi

    # Check if PRD has design system section
    if ! grep -q "## Design System" docs/PRD.md 2>/dev/null; then
        return 0
    fi

    log "${CYAN}Running design review...${NC}"

    # Extract design system from PRD
    local design_system=$(sed -n '/## Design System/,/^## /p' docs/PRD.md | head -50)

    # Build prompt for agent image review
    local prompt="Review this screenshot against the design system.

DESIGN SYSTEM:
$design_system

Check:
1. Are colors correct? (primary, accent, background)
2. Is spacing consistent? (following the scale)
3. Is typography correct? (font, sizes)
4. Overall polish - would this pass a design review?

If there are issues, list them specifically.
If it looks good, say 'DESIGN_OK'.

Be concise - max 10 lines."

    # Call agent with image input
    local screenshot=$(ls -1 "$screenshot_dir"/*.png 2>/dev/null | head -1)
    if [ -z "$screenshot" ]; then
        return 0
    fi

    local result
    result=$(run_agent_image "$prompt" "$screenshot") || true

    if echo "$result" | grep -q "DESIGN_OK"; then
        log "${GREEN}✅ Design review passed${NC}"
        return 0
    fi

    log "${YELLOW}⚠️ Design issues found${NC}"
    echo "$result" | head -10

    # Save for potential CR
    echo "$result" > .design-review.log
    return 1
}

# Generate design CR from review
generate_design_cr() {
    local spec_name="$1"
    local review_output=$(cat .design-review.log 2>/dev/null)

    if [ -z "$review_output" ]; then
        return 1
    fi

    # Prevent CR-of-CR
    if is_cr_spec "$spec_name"; then
        log "${RED}⚠️ Design CR failed - not generating CR-of-CR${NC}"
        return 1
    fi

    local cr_file=".ralph-specs/CR-design-${spec_name}.md"
    log "${YELLOW}Generating design CR: $cr_file${NC}"

    local prompt="Design review found issues after spec: $spec_name

Review feedback:
$review_output

Create a Change Request spec to fix the design issues.

Write to: $cr_file

Format:
# CR: Fix design issues from $spec_name

**Issues found:**
[List from review]

## Fix
- [Specific CSS/component changes]

## Klart när
- [ ] Design review passes
- [ ] npm run build succeeds"

    run_agent_prompt "$prompt" 300 > /dev/null 2>&1

    if [ -f "$cr_file" ]; then
        log "${GREEN}Design CR created: $cr_file${NC}"
        return 0
    fi

    return 1
}
