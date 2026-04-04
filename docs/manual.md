# Claude Code Bootstrap — Operations Manual

## What This Is

An autonomous development environment that wraps Claude Code with safety hooks, test-driven workflows, self-improving instructions, and an external controller that keeps work going through crashes and rate limits. You give it a naive prompt ("build me a habit tracker") and it handles TDD, code review, autonomous improvement, and quality reporting.

## Core Philosophy

**There are no edge cases, only certainties.** Sessions will die. Builds will break. Claude will write bad code. Tests will fail. The human will be absent. The system is designed around these certainties, not despite them.

## Quick Start (5 minutes)

```bash
# 1. Clone the bootstrap into your project
cd /your/project
bash /path/to/bootstrap/install.sh

# 2. Edit CLAUDE.md — replace ALL [BRACKETED] values
#    This is the only REQUIRED customization.

# 3. Start Claude Code
claude

# 4. Inside Claude Code, verify everything:
/bootstrap
/health
```

## Daily Operations

### Starting a Work Session
```bash
cd /your/project
claude
```
Claude automatically reads CLAUDE.md, loads JOURNAL.md from last session, and shows current git state, TODO status, and ratchet progress.

### Building a Feature (TDD)
```
/plan authentication system with JWT
```
Claude interviews itself, runs a self-critic, produces PLAN.md. Review and approve.

```
/implement authentication system with JWT
```
Claude writes failing tests (RED), implements minimal code (GREEN), refactors. Each phase uses an isolated subagent to prevent context pollution.

### Quick Status Check (anytime, even from phone)
```
/check
```
Prints 25-line summary to stdout in under 10 seconds. No files generated.

### End of Session
```
/retro
```
Analyzes what went well and wrong. Proposes rule improvements to EVOLUTION.md.

### End of Day
```
/digest
```
Generates plain-text daily report at `.claude/reports/digest-YYYY-MM-DD.md`.

```
/dashboard
```
Generates interactive HTML dashboard at `.claude/reports/dashboard.html`. Open in any browser.

## Autonomous Overnight Runs

**Run this in a SEPARATE terminal, not inside Claude Code:**

```bash
# Start autonomous mode with $5 budget
bash scripts/conductor.sh --auto --budget 5

# Monitor from any browser (including phone):
bash scripts/conductor.sh --serve
# → http://localhost:7777

# Quick status without starting a server:
bash scripts/conductor.sh --check
```

The conductor:
- Spawns `claude -p` sessions headlessly
- Reads TODO.md for the next task
- Reads JOURNAL.md for context from the previous session
- Restarts after rate limits (exponential backoff: 5m → 10m → 20m)
- Restarts after token limits and crashes
- Stops at budget limit, 3 consecutive failures, or when TODO is empty
- Generates live HTML dashboard that auto-refreshes every 15 seconds

## What the Human Reviews

| File | How Often | What To Do |
|------|-----------|------------|
| `.claude/EVOLUTION.md` | Every few days | Promote good rule proposals to CLAUDE.md, reject bad ones |
| `.claude/reports/digest-*.md` | Daily | Read the 60-second health report. Check warnings. |
| `.claude/reports/dashboard.html` | Anytime | Open in browser for visual overview |
| `.claude/reports/walkthrough.html` | After autonomous runs | Understand what was built while you were away |
| `.claude/TODO.md` | When priorities change | Reorder tasks, add new ones, mark complete |
| `program.md` | When ratchet stalls | Update experiment directions, mark exhausted areas |
| `CLAUDE.md` | Rarely (when rules need updating) | Keep under 25 rules. Every rule must name the failure it prevents. |

## Configuration

### Changing Models and Effort
Edit `.claude/model-config.json`. Three tiers:

- **High** (opus, high effort): planning, architecture, critique
- **Standard** (sonnet, standard effort): implementation, testing
- **Low** (sonnet, low effort): scanning, spot checks

To change a subagent's model: edit the `model:` field in `.claude/agents/<name>.md`.
To change a skill's effort: edit the `effort:` field in `.claude/skills/<name>/SKILL.md`.

### Adding Project-Specific Rules
Create `.claude/rules/your-rule.md` with path scoping:

```markdown
---
paths:
  - "src/api/**/*.ts"
---
# API Rules
- All endpoints must validate input with Zod
- Return consistent error shapes
```

This rule ONLY loads when Claude touches API files.

### Changing Permissions
Edit `.claude/settings.json`. The `allow` list pre-approves common tools.
The `deny` list blocks dangerous commands. Hooks provide additional security.

### Conductor Settings
Edit these variables at the top of `scripts/conductor.sh`:

```bash
MAX_BUDGET=10          # USD cap per run
MAX_CONSECUTIVE_FAILS=3 # Stop after N failures
MAX_SESSIONS=50        # Max sessions per run
SESSION_TIMEOUT=600    # Seconds per session (10 min)
MAX_TURNS=25           # Max Claude turns per session
```

## Maintenance

### Weekly
- Review `.claude/EVOLUTION.md` — promote or reject proposed rules
- Run `/scout` — check for Claude Code updates that could improve the bootstrap
- Run `/walkthrough` — regenerate the project tour
- Prune CLAUDE.md if approaching 25 rules

### Monthly
- Run the assumption audit: type "audit assumptions" in Claude Code
- Review `docs/ESCAPE-HATCHES.md` — are there new failure modes?
- Check conductor logs: `cat .claude/logs/conductor.log | tail -100`

### Emergency Recovery
```bash
# Revert all uncommitted changes
git checkout -- .

# Reset to a specific commit
git log --oneline -10
git reset --hard <hash>

# Fix corrupted ratchet state
git checkout HEAD -- .claude/ratchet-state.json

# Start completely fresh session
claude
/clear

# Reset conductor state
bash scripts/conductor.sh --reset
```

## How the Dashboard Works

The `/dashboard` command generates a single self-contained HTML file at `.claude/reports/dashboard.html`. Here's how it works:

1. **Data Collection**: When you run `/dashboard`, Claude reads all state files:
   - `.claude/ratchet-state.json` → experiment history and scores
   - `.claude/EVOLUTION.md` → rule proposals and session scores
   - `.claude/TODO.md` → task completion progress
   - `.claude/scout-state.json` → feature scan results
   - `.claude/reports/digest-*.md` → historical daily reports
   - `git log` → commit history
   - Current test, lint, and build results

2. **Embedding**: All data is baked into the HTML file as JavaScript constants. No external API calls, no server needed.

3. **Rendering**: Chart.js (loaded from CDN, cached by browser) renders:
   - Health traffic light (GREEN/YELLOW/RED)
   - Test pass/fail donut chart
   - Ratchet staircase chart (score over time, like Karpathy's AutoResearch)
   - Task progress kanban
   - Instruction budget gauge
   - Git activity bars
   - Warnings panel

4. **Viewing**: Double-click the file. Works on desktop, tablet, phone. Dark mode default. Responsive CSS Grid layout. No server, no npm, no build step.

5. **Freshness**: The file is static. Run `/dashboard` again to regenerate with current data. The file shows its generation timestamp.

The **conductor dashboard** (`conductor.html`) is different — it's generated by the bash conductor script, not by Claude Code. It auto-refreshes every 15 seconds via `<meta http-equiv="refresh" content="15">` and shows live session status, cost tracking, and history.

## Glossary

| Term | Meaning |
|------|---------|
| **Ratchet** | Quality score that can only go up. Bad changes are reverted. |
| **RED/GREEN** | TDD phases. RED = failing test. GREEN = passing test. |
| **Conductor** | External bash script that restarts Claude Code sessions. |
| **JOURNAL.md** | Living state file updated every Claude turn. Survives crashes. |
| **HANDOFF.md** | Copy of journal for session recovery. |
| **EVOLUTION.md** | Proposed rule changes. Human promotes or rejects. |
| **program.md** | Experiment directions for the ratchet loop. |
| **Meta-ratchet** | System that learns from failures and proposes new rules. |
| **Scout** | Skill that checks Claude Code changelog for useful new features. |
| **Self-plan** | Skill where Claude interviews itself before building. |
| **Assumption audit** | Skill that inverts every system assumption to find gaps. |
