# Changelog

All notable changes to Ralph Inferno will be documented in this file.

## [1.0.10] - 2026-01-19

### Added
- **AWS Bedrock support**: Full documentation for Bedrock authentication
- **Azure AI Foundry support**: Full documentation for Foundry authentication
- New **Authentication** section in README with all 4 auth methods
- Auth method options table in config documentation
- Updated `vm-init.sh` with all auth examples

## [1.0.9] - 2026-01-19

### Added
- **Two entry points**: Greenfield (new apps) and Brownfield (existing apps)
- **`/ralph:idea`**: Full BMAD Brainstorm Mode with 8 techniques
  - 5 Whys, Crazy 8s, Mashups, HMW, SCAMPER, Audience Flip, Devil's Advocate, Web Research
  - Autonomous (YOLO) or Interactive mode
  - Outputs PROJECT-BRIEF.md
- **`/ralph:discover`**: Full BMAD Analyst Mode with 8 techniques
  - Market Research, Personas, User Journeys, Feature Prioritization
  - Tech Feasibility, Security, Business Model, Devil's Advocate
  - Takes PROJECT-BRIEF.md as input, outputs PRD.md
- **`/ralph:change-request`**: Brownfield entry point
  - Analyzes existing codebase
  - Scope assessment (Small/Medium/Large)
  - Different analysis depth based on scope
  - Generates CR-* specs with regression checks
- **`/ralph:plan`**: Now supports both PRD and Change Request input
  - Auto-detects input source
  - PRD mode: Full greenfield planning
  - CR mode: Appends to existing IMPLEMENTATION_PLAN.md
- **New templates**: PROJECT-BRIEF-template.md, CHANGE-REQUEST-template.md

### Changed
- All phases now offer Autonomous (YOLO) or Interactive mode
- Completeness loops in brainstorm, discovery, and planning phases
- Updated ARCHITECTURE.md and README.md with new workflow

## [1.0.8] - 2025-01-19

### Added
- **config-utils.sh**: Centralized config loading (`load_config`, `get_language`, etc.)
- All slash commands now auto-detect language setting

### Fixed
- **ntfy notifications**: Now respects `ntfy_enabled` setting in config.json
- **VM config**: `ralph:review` reads from config.json instead of `~/.ralph-vm`
- Consistent config loading across all scripts

## [1.0.7] - 2025-01-19

### Added
- **Language agnostic**: Auto-detect build/test commands (npm, cargo, go, make, python)
- **Custom commands**: Support `build_cmd` and `test_cmd` in config.json
- **Language setting**: Specs/PRD written in configured language (en, sv, etc.)
- Smart logging: Always log to `.ralph/logs/claude-raw.log`, errors to `errors.log`
- `/ralph:status` now shows last error details

### Changed
- All code/commands converted to English (output still respects language setting)
- `git push` now uses current branch instead of hardcoded `main`

### Removed
- **~90KB of deprecated code**:
  - `ralph-full.sh` (62KB legacy monolith)
  - `ralph-deploy.sh`, `ralph-review.sh`, `ralph-setup.sh`, `ralph-tmux.sh`, `vm-sync.sh`
  - `vm.sh`, `watch.sh`
  - `spec.md.template` (duplicate)

## [1.0.6] - 2025-01-16

### Added
- Better README with "How It Works" section
- Clear setup instructions for both local and VM
- vm-init.sh: nvm path fix, Playwright dependencies
- Smart logging (always to file, show on error)

## [1.0.5] - 2025-01-16

### Added
- `/ralph:update` command to check for new versions

### Fixed
- Version now read dynamically from package.json

## [1.0.4] - 2025-01-16

### Fixed
- ntfy topic now unique per install (was shared `ralph-notifications`)

## [1.0.3] - 2025-01-15

### Added
- Chrome Extension tip for discovery mode
- Cost tracking improvements

## [1.0.2] - 2025-01-15

### Fixed
- Various bug fixes from initial testing

## [1.0.1] - 2025-01-15

### Fixed
- npm package structure fixes

## [1.0.0] - 2025-01-15

### Added
- Initial release
- Three modes: Quick, Standard, Inferno
- Slash commands: `/ralph:discover`, `/ralph:plan`, `/ralph:deploy`, `/ralph:review`, `/ralph:change-request`, `/ralph:status`, `/ralph:abort`
- Test loop with Playwright E2E
- Auto-CR generation on test failure
- ntfy.sh notifications
- VM sandbox execution
- Cost/token tracking
