# Claude Code Bootstrap — Complete Package Contents

## Repository Structure

```
claude-bootstrap/
│
├── install.sh                          # One-command installer (run in your project)
├── README.md                           # GitHub README with quick start
├── LICENSE                             # MIT license
│
├── CLAUDE.md.template                  # ★ USER CUSTOMIZES: project constitution
├── program.md.template                 # ★ USER CUSTOMIZES: ratchet experiment directions
├── TODO.md.template                    # ★ USER CUSTOMIZES: project task list
│
├── settings.json                       # Hook wiring, permissions, agent teams flag
├── ratchet-state.json                  # Initial experiment baseline (empty)
├── model-config.json                   # Model/effort tier config (opus/sonnet/haiku)
├── EVOLUTION.md                        # Instruction evolution log (empty, system writes)
├── OPEN-QUESTIONS.md                   # Blind spot forcing questions (seeded)
│
├── hooks/
│   ├── pre-tool-security.sh            # Blocks secrets, destructive commands (fail-closed)
│   ├── pre-write-guard.sh              # Blocks edits to protected/test files
│   ├── post-edit-autoformat.sh         # Auto-formats after every edit
│   ├── stop-journal.sh                 # Writes JOURNAL.md every turn (crash-safe)
│   ├── session-start.sh               # Loads context, verifies hooks, prunes logs
│   └── pre-compact-handoff.sh          # Preserves state before compaction
│
├── skills/
│   ├── ratchet-loop/
│   │   └── SKILL.md                    # 6-step autonomous improvement loop
│   ├── tdd-loop/
│   │   └── SKILL.md                    # TDD orchestrator with subagent isolation
│   ├── meta-ratchet/
│   │   └── SKILL.md                    # Learn from failures, propose rule improvements
│   ├── self-plan/
│   │   └── SKILL.md                    # Self-interview + critic before building
│   ├── scout/
│   │   └── SKILL.md                    # Scan Claude Code releases, A/B test features
│   └── assumption-audit/
│       └── SKILL.md                    # Invert assumptions, find architectural gaps
│
├── agents/
│   ├── tdd-test-writer.md              # RED phase — writes failing tests (sonnet)
│   ├── tdd-implementer.md              # GREEN phase — minimal implementation (sonnet)
│   ├── code-reviewer.md                # Quality & security review (sonnet)
│   ├── ui-tester.md                    # UI, accessibility, responsive (sonnet)
│   └── self-critic.md                  # Adversarial plan critique (opus)
│
├── commands/
│   ├── bootstrap.md                    # /bootstrap — verify environment
│   ├── implement.md                    # /implement — TDD feature build
│   ├── ratchet.md                      # /ratchet — autonomous improvement loop
│   ├── review.md                       # /review — code review via subagent
│   ├── health.md                       # /health — project health check
│   ├── retro.md                        # /retro — session retrospective
│   ├── digest.md                       # /digest — plain-text daily report
│   ├── dashboard.md                    # /dashboard — interactive HTML report
│   ├── walkthrough.md                  # /walkthrough — project tour with diffs
│   └── check.md                        # /check — 30-second spot check
│
├── rules/
│   ├── testing.md                      # Testing rules (loads on *.test.*, *.spec.*)
│   ├── ui-components.md                # UI rules (loads on *.tsx, *.jsx, components/)
│   └── safety.md                       # Safety rules (loads on *.sh, *.env, hooks/)
│
├── scripts/
│   └── conductor.sh                    # External session controller (runs OUTSIDE Claude)
│
└── docs/
    ├── MANUAL.md                       # Human operations guide
    ├── ARCHITECTURE.md                 # System design decisions & diagrams
    ├── PATTERNS.md                     # Code patterns & anti-patterns
    ├── DEBUGGING.md                    # Known issues & recovery procedures
    ├── QUICKREF.md                     # One-page cheat sheet
    └── ESCAPE-HATCHES.md              # Complete failure mode catalog
```

## File Count Summary

| Category | Count | Purpose |
|----------|-------|---------|
| Hooks | 6 | Deterministic enforcement (100% execution) |
| Skills | 6 | On-demand workflows (loaded when triggered) |
| Agents | 5 | Isolated subagents (separate context windows) |
| Commands | 10 | Slash commands for Claude Code |
| Rules | 3 | Conditional instructions (path-scoped) |
| Docs | 6 | Human reference documentation |
| Templates | 3 | User-customizable project files |
| Config | 3 | Settings, model tiers, ratchet state |
| State | 2 | Evolution log, open questions |
| Scripts | 2 | Installer + conductor |
| **Total** | **46** | |

## What Gets Installed Where

The installer copies files from the bootstrap repo into your project:

```
YOUR PROJECT (after install)
├── CLAUDE.md                     ← from CLAUDE.md.template
├── program.md                    ← from program.md.template
├── .claude/
│   ├── settings.json             ← from settings.json
│   ├── TODO.md                   ← from TODO.md.template
│   ├── ratchet-state.json        ← from ratchet-state.json
│   ├── model-config.json         ← from model-config.json
│   ├── EVOLUTION.md              ← from EVOLUTION.md
│   ├── OPEN-QUESTIONS.md         ← from OPEN-QUESTIONS.md
│   ├── hooks/                    ← from hooks/
│   ├── skills/                   ← from skills/
│   ├── agents/                   ← from agents/
│   ├── commands/                 ← from commands/
│   ├── rules/                    ← from rules/
│   ├── logs/                     ← (empty, created by installer)
│   ├── reports/                  ← (empty, created by installer)
│   └── worktrees/                ← (empty, created by installer)
├── scripts/
│   └── conductor.sh              ← from scripts/conductor.sh
└── docs/                         ← from docs/
```

## Files Generated at Runtime (do NOT check in)

These files are created by hooks and commands during operation:

```
.claude/JOURNAL.md          ← written by stop-journal.sh every turn
.claude/HANDOFF.md          ← written by pre-compact-handoff.sh + stop-journal.sh
.claude/PLAN.md             ← written by self-plan skill
.claude/PLAN-CRITIQUE.md    ← written by self-critic agent
.claude/ASSUMPTION-AUDIT.md ← written by assumption-audit skill
.claude/conductor.pid       ← written by conductor.sh
.claude/conductor-state.json← written by conductor.sh
.claude/scout-state.json    ← written by scout skill
.claude/logs/*.log          ← written by hooks and conductor
.claude/logs/*.jsonl        ← transcript backups
.claude/reports/dashboard.html    ← written by /dashboard
.claude/reports/walkthrough.html  ← written by /walkthrough
.claude/reports/conductor.html    ← written by conductor.sh
.claude/reports/digest-*.md       ← written by /digest
```
