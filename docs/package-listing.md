# Claude Code Bootstrap — Complete Package Contents

## Repository Structure

The source bootstrap repo mirrors the installed layout exactly.
Files that live under `.claude/` in your project live under `.claude/`
in the bootstrap repo too. `install.sh` copies them path-for-path.

```
claude-bootstrap/
│
├── install.sh                           # One-command installer (run in your project)
├── README.md                            # GitHub README with quick start
├── LICENSE                              # MIT license
│
├── CLAUDE.md.template                   # ★ USER CUSTOMIZES → installed as CLAUDE.md
├── program.md.template                  # ★ USER CUSTOMIZES → installed as program.md
│
├── docs/                                # → your-project/docs/
│   ├── MANUAL.md
│   ├── ARCHITECTURE.md
│   ├── PATTERNS.md
│   ├── DEBUGGING.md
│   ├── QUICKREF.md
│   └── ESCAPE-HATCHES.md
│
├── scripts/                             # → your-project/scripts/
│   └── conductor.sh                     # External session controller (runs OUTSIDE Claude)
│
└── .claude/                             # → your-project/.claude/  (mirrors destination)
    │
    ├── settings.json                    # Hook wiring, permissions, agent teams flag
    ├── ratchet-state.json               # Initial experiment baseline (empty)
    ├── model-config.json                # Model/effort tier config (opus/sonnet/haiku)
    ├── EVOLUTION.md                     # Instruction evolution log (empty, system writes)
    ├── OPEN-QUESTIONS.md                # Blind spot forcing questions (seeded)
    ├── TODO.md.template                 # ★ USER CUSTOMIZES → installed as .claude/TODO.md
    │
    ├── hooks/
    │   ├── pre-tool-security.sh         # Blocks secrets, destructive commands (fail-closed)
    │   ├── pre-write-guard.sh           # Blocks edits to protected/test files
    │   ├── post-edit-autoformat.sh      # Auto-formats after every edit
    │   ├── stop-journal.sh              # Writes JOURNAL.md every turn (crash-safe)
    │   ├── session-start.sh             # Loads context, verifies hooks, prunes logs
    │   └── pre-compact-handoff.sh       # Preserves state before compaction
    │
    ├── skills/
    │   ├── ratchet-loop/
    │   │   └── SKILL.md                 # 6-step autonomous improvement loop
    │   ├── tdd-loop/
    │   │   └── SKILL.md                 # TDD orchestrator with subagent isolation
    │   ├── meta-ratchet/
    │   │   └── SKILL.md                 # Learn from failures, propose rule improvements
    │   ├── self-plan/
    │   │   └── SKILL.md                 # Self-interview + critic before building
    │   ├── scout/
    │   │   └── SKILL.md                 # Scan Claude Code releases, A/B test features
    │   └── assumption-audit/
    │       └── SKILL.md                 # Invert assumptions, find architectural gaps
    │
    ├── agents/
    │   ├── tdd-test-writer.md           # RED phase — writes failing tests (sonnet)
    │   ├── tdd-implementer.md           # GREEN phase — minimal implementation (sonnet)
    │   ├── code-reviewer.md             # Quality & security review (sonnet)
    │   ├── ui-tester.md                 # UI, accessibility, responsive (sonnet)
    │   └── self-critic.md               # Adversarial plan critique (opus)
    │
    ├── commands/
    │   ├── bootstrap.md                 # /bootstrap — verify environment
    │   ├── implement.md                 # /implement — TDD feature build
    │   ├── ratchet.md                   # /ratchet — autonomous improvement loop
    │   ├── review.md                    # /review — code review via subagent
    │   ├── health.md                    # /health — project health check
    │   ├── retro.md                     # /retro — session retrospective
    │   ├── digest.md                    # /digest — plain-text daily report
    │   ├── dashboard.md                 # /dashboard — interactive HTML report
    │   ├── walkthrough.md               # /walkthrough — project tour with diffs
    │   └── check.md                     # /check — 30-second spot check
    │
    └── rules/
        ├── testing.md                   # Testing rules (loads on *.test.*, *.spec.*)
        ├── ui-components.md             # UI rules (loads on *.tsx, *.jsx, components/)
        └── safety.md                    # Safety rules (loads on *.sh, *.env, hooks/)
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
| Config | 5 | settings, model-config, ratchet-state, EVOLUTION, OPEN-QUESTIONS |
| Scripts | 2 | Installer + conductor |
| **Total** | **46** | |

## What Gets Installed Where

`install.sh` copies the `.claude/` subtree from the bootstrap repo directly
into your project's `.claude/`. Root-level files (`docs/`, `scripts/`,
templates) are copied to your project root.

```
YOUR PROJECT (after install)
│
├── CLAUDE.md                     ← from CLAUDE.md.template   (only if not present)
├── program.md                    ← from program.md.template  (only if not present)
│
├── docs/                         ← from docs/
│   ├── MANUAL.md
│   ├── ARCHITECTURE.md
│   ├── PATTERNS.md
│   ├── DEBUGGING.md
│   ├── QUICKREF.md
│   └── ESCAPE-HATCHES.md
│
├── scripts/
│   └── conductor.sh              ← from scripts/conductor.sh
│
└── .claude/                      ← from .claude/ (entire subtree)
    ├── settings.json
    ├── ratchet-state.json
    ├── model-config.json
    ├── EVOLUTION.md
    ├── OPEN-QUESTIONS.md
    ├── TODO.md                   ← from .claude/TODO.md.template
    ├── hooks/
    │   ├── pre-tool-security.sh
    │   ├── pre-write-guard.sh
    │   ├── post-edit-autoformat.sh
    │   ├── stop-journal.sh
    │   ├── session-start.sh
    │   └── pre-compact-handoff.sh
    ├── skills/
    │   ├── ratchet-loop/SKILL.md
    │   ├── tdd-loop/SKILL.md
    │   ├── meta-ratchet/SKILL.md
    │   ├── self-plan/SKILL.md
    │   ├── scout/SKILL.md
    │   └── assumption-audit/SKILL.md
    ├── agents/
    │   ├── tdd-test-writer.md
    │   ├── tdd-implementer.md
    │   ├── code-reviewer.md
    │   ├── ui-tester.md
    │   └── self-critic.md
    ├── commands/
    │   ├── bootstrap.md
    │   ├── implement.md
    │   ├── ratchet.md
    │   ├── review.md
    │   ├── health.md
    │   ├── retro.md
    │   ├── digest.md
    │   ├── dashboard.md
    │   ├── walkthrough.md
    │   └── check.md
    ├── rules/
    │   ├── testing.md
    │   ├── ui-components.md
    │   └── safety.md
    ├── logs/                     ← (empty dir, created by installer)
    ├── reports/                  ← (empty dir, created by installer)
    └── worktrees/                ← (empty dir, created by installer)
```

## Files Generated at Runtime (do NOT check in)

These files are created by hooks and commands during operation.
They are excluded by `.gitignore` (installer adds the entries automatically).

```
.claude/JOURNAL.md            ← written by stop-journal.sh every turn
.claude/HANDOFF.md            ← written by pre-compact-handoff.sh + stop-journal.sh
.claude/PLAN.md               ← written by self-plan skill
.claude/PLAN-CRITIQUE.md      ← written by self-critic agent
.claude/ASSUMPTION-AUDIT.md   ← written by assumption-audit skill
.claude/conductor.pid         ← written by conductor.sh
.claude/conductor-state.json  ← written by conductor.sh
.claude/scout-state.json      ← written by scout skill
.claude/logs/*.log            ← written by hooks and conductor
.claude/logs/*.jsonl          ← transcript backups
.claude/reports/dashboard.html     ← written by /dashboard command
.claude/reports/walkthrough.html   ← written by /walkthrough command
.claude/reports/conductor.html     ← written by conductor.sh
.claude/reports/digest-*.md        ← written by /digest command
```

## Key Design Principle: Source Mirrors Destination

The bootstrap repo's `.claude/` subtree is a **direct mirror** of what
gets installed in your project. This means:

- You can inspect `bootstrap-repo/.claude/hooks/stop-journal.sh` to
  see exactly what will run in your project.
- Updating the bootstrap repo is straightforward — edit files in place
  under `.claude/`, re-run `install.sh` to push updates to projects.
- No mental translation required between "where it is in the bootstrap"
  and "where it lands in my project."

Files that live at your project root (`CLAUDE.md`, `program.md`,
`docs/`, `scripts/`) also live at the bootstrap repo root — same logic.
