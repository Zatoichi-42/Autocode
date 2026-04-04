# Quick Reference Card

## Slash Commands
| Command | What It Does | Effort |
|---------|-------------|--------|
| `/bootstrap` | Initialize/verify all bootstrap files, hooks, directories | standard |
| `/plan [feature]` | Self-interview + critic before building (think first) | **high** |
| `/implement [feature]` | Build feature with strict TDD (Red → Green → Refactor) | standard |
| `/ratchet` | Start autonomous improvement loop (Karpathy-style) | standard |
| `/review` | Code review current changes via subagent | standard |
| `/health` | Project health dashboard (tests, build, lint, coverage) | low |
| `/check` | **30-second spot check** — stdout only, anytime, fast | **low** |
| `/retro` | Session retrospective — analyze failures, propose rules | high |
| `/digest` | Generate plain-text daily quality report | low |
| `/dashboard` | Generate interactive HTML visual dashboard | standard |
| `/walkthrough` | Generate project tour with diff tutorial | standard |
| `/scout` | Scan Claude Code releases, propose feature A/B tests | low |
| `/compact [focus]` | Compact context, preserving specified focus areas | — |

## Subagents
| Agent | Role | Model | Effort |
|-------|------|-------|--------|
| `tdd-test-writer` | Writes failing tests (RED phase) | sonnet | standard |
| `tdd-implementer` | Minimal code to pass tests (GREEN phase) | sonnet | standard |
| `code-reviewer` | Reviews code for quality/security | sonnet | standard |
| `ui-tester` | Tests UI components, accessibility | sonnet | standard |
| `self-critic` | **Adversarial plan/code critique** | **opus** | **high** |

## Hook Events (What Fires When)
| Event | When | Our Hook Does |
|-------|------|---------------|
| `SessionStart` | Session begins/resumes | Loads JOURNAL.md, git state, TODO, ratchet |
| `PreToolUse:Bash` | Before any Bash command | Blocks secrets in commits, destructive ops |
| `PreToolUse:Write\|Edit` | Before file write/edit | Blocks edits to protected files |
| `PostToolUse:Write\|Edit` | After file write/edit | Auto-formats the edited file |
| `Stop` | End of Claude's turn | **Writes JOURNAL.md** (survives crashes!) + warns if tests failing |
| `PreCompact` | Before context compaction | Writes state snapshot + backs up transcript |

## The Six-Step Ratchet Loop
```
1. BASELINE  → Measure everything (tests, build, lint, custom)
2. HYPOTHESIZE → Propose ONE atomic change
3. IMPLEMENT → Make the minimal change
4. MEASURE → Run the same measurements
5. DECIDE → Score improved? KEEP (commit). Worse? REVERT.
6. LEARN → Log result, pick next direction, GOTO 2
```

## Context Management Cheatsheet
| Context % | Action |
|-----------|--------|
| 0-50% | Work freely |
| 50% | `/compact` with focus notes |
| 70% | Commit, write HANDOFF.md, new session |
| 90%+ | `/clear` mandatory |

## Git Workflow
```bash
# New feature
git checkout -b feat/feature-name

# Ratchet improvement
git commit -m "ratchet: [description]"

# TDD cycle
git commit -m "test: red — [what tests expect]"
git commit -m "feat: green — [what was implemented]"
git commit -m "refactor: [what was cleaned up]"

# Parallel work with worktrees
claude --worktree feat-auth      # Session 1
claude --worktree fix-bug-123    # Session 2
claude --worktree ratchet-run    # Session 3 (overnight)
```

## External Conductor (runs OUTSIDE Claude Code)
```bash
# Autonomous overnight mode (restarts sessions through crashes/limits)
bash scripts/conductor.sh --auto --budget 5

# Quick status check
bash scripts/conductor.sh --check

# Start web dashboard (phone-friendly, auto-refreshes)
bash scripts/conductor.sh --serve
# → opens http://localhost:7777

# Reset conductor state
bash scripts/conductor.sh --reset
```

## Key File Locations
```
CLAUDE.md                          → Constitution (always loaded, <25 rules)
program.md                         → Ratchet experiment directions
scripts/conductor.sh               → EXTERNAL controller (runs outside Claude)
.claude/settings.json              → Hooks, permissions, env vars
.claude/model-config.json          → Model/effort tier configuration
.claude/TODO.md                    → Task tracker (conductor reads this)
.claude/JOURNAL.md                 → Live state (updated every turn, survives crashes)
.claude/HANDOFF.md                 → Copy of journal for SessionStart
.claude/EVOLUTION.md               → Instruction improvement proposals
.claude/PLAN.md                    → Current plan from /plan self-interview
.claude/conductor-state.json       → Conductor session history & cost tracking
.claude/scout-state.json           → Feature scan results
.claude/ratchet-state.json         → Experiment baseline & history
.claude/reports/
│ ├── conductor.html               → Live conductor dashboard (auto-refreshes)
│ ├── dashboard.html               → Project quality visual dashboard
│ ├── walkthrough.html             → Interactive project tour with diff tutorial
│ └── digest-YYYY-MM-DD.md         → Daily quality reports
.claude/agents/*.md                → Subagent definitions (5 agents)
.claude/commands/*.md              → Slash commands (10 commands)
.claude/skills/*/SKILL.md          → On-demand skills (4 skills)
.claude/hooks/*.sh                 → Hook scripts (6 hooks)
.claude/rules/*.md                 → Conditional rules (path-scoped)
.claude/logs/                      → Session logs, transcript backups
docs/ARCHITECTURE.md               → System design decisions
docs/PATTERNS.md                   → Code patterns & anti-patterns
docs/DEBUGGING.md                  → Known issues & recovery
docs/QUICKREF.md                   → This file
```

## Prompting Patterns
```
# Start a new feature with TDD
"Implement [feature]. Use /implement to enforce TDD."

# Run overnight improvements
"Run /ratchet following program.md. Stop at 50% context or after 20 experiments."

# Challenge Claude's work
"Prove to me this works. Find every edge case that could break this."

# Course correct
"Knowing everything you know now, scrap this and do it the elegant way."

# Scope lock
"Implement ONLY [X]. Do NOT add [Y] or [Z]. Stop when [X] works."
```

## Emergency Recovery
```bash
# Revert everything to last commit
git checkout -- .

# Revert to a specific commit
git log --oneline -10     # Find the commit
git reset --hard <hash>   # Nuclear option

# Fix corrupted ratchet state
git checkout HEAD -- .claude/ratchet-state.json

# Start completely fresh
git stash && /clear
```
