# Project: [PROJECT_NAME]

## Prime Directives
Always read applicable instructions (CLAUDE.md, .claude/rules/, skills) before substantive work.
Do not edit non-test source without a recent RED signal.
No silent failures — all code paths return data or typed errors.
Do not let unrelated failing tests redefine the current task.
Before major work, read .claude/OPEN-QUESTIONS.md and answer each relevant question.
There are no edge cases, only certainties. If it can happen, it will. Design every path as a main path.

## Stack
- [DEFINE YOUR STACK HERE]
- Test runner: [vitest/jest/pytest/etc]
- Linter: [eslint/ruff/etc]
- Formatter: [prettier/black/etc]

## Critical Commands
```bash
# Test (single — prefer this)
[your single test command] <file>

# Test (full suite — sparingly)
[your full test command]

# Build
[your build command]

# Lint + Typecheck
[your lint command] && [your typecheck command]
```

## TDD Protocol — MAX TDD
1. Name the tests first (describe what you're proving before writing anything)
2. Write/update tests before implementation
3. Confirm RED — tests must fail before you write source code
4. Implement the minimum to go GREEN
5. Refactor only while GREEN
6. If the user gives an exact error string, reproduce that exact string in a test
7. Reproduce the exact user command before claiming a fix
8. For CLI/output bugs, add integration tests for the real entrypoint
9. For stdout/stderr work, verify: startup output, progress output, final output, flushing
10. NEVER modify test files to make them pass — fix the source

## Architecture Map
```
src/
├── core/          # Business logic — no framework deps
├── ui/            # Components, pages, views
├── api/           # Routes, handlers, middleware
├── lib/           # Shared utilities
├── types/         # Type definitions
└── __tests__/     # Mirrors src/ structure
```

## Code Rules
- Files under 300 lines — extract when approaching
- Functions under 40 lines — single responsibility
- No `any` types — use `unknown` and narrow
- Surface progress and errors to STDOUT for CLI work
- Error handling: return Result types or typed errors, never empty catch
- Prefer composition over inheritance
- Prefer named exports over default exports

## Git Workflow
- Branch: `feat/`, `fix/`, `refactor/`, `test/`, `docs/`
- Commits: conventional (`feat:`, `fix:`, `refactor:`, `test:`)
- NEVER commit to `main` directly
- Run full test suite before PR

## Context Management
- At 50%: `/compact` preserving modified files, test status, branch, tasks
- At 70%: commit work, new session
- Read `.claude/HANDOFF.md` after compact for state recovery

## External Control (Conductor)
The conductor (`scripts/conductor.sh`) runs OUTSIDE Claude Code sessions.
It restarts work after crashes, rate limits, and session limits.
It reads JOURNAL.md and TODO.md to decide what to resume.
Human controls it via web UI at http://localhost:7777 or direct file edits.
To start autonomous overnight: `bash scripts/conductor.sh --auto --budget 5`
To check status: `bash scripts/conductor.sh --check`
To see dashboard: open `.claude/reports/conductor.html` in any browser
- @docs/ARCHITECTURE.md — system design decisions
- @docs/PATTERNS.md — established patterns
- @docs/DEBUGGING.md — known issues and recovery
- `.claude/skills/` — ratchet-loop, tdd-loop, meta-ratchet (load when needed)
- `.claude/agents/` — subagents for isolated work
- `.claude/ratchet-state.json` — experiment baseline
- `.claude/EVOLUTION.md` — instruction improvement proposals (human reviews)

## Model & Effort Configuration
Higher-order work (planning, design, architecture, critique) uses HIGH effort.
Lower-order work (implementation, testing, formatting) uses STANDARD effort.
Configure in `.claude/model-config.json`. Subagent models set in agent frontmatter.

## Session Lifecycle
- Start: SessionStart hook loads JOURNAL.md, git state, TODO, ratchet state
- Every turn: Stop hook writes JOURNAL.md (survives crashes and session limits)
- Compact: PreCompact hook writes state snapshot
- Anytime: `/check` for 30-second spot check (no files, stdout only)
- End of session: `/retro` to analyze failures, propose rule improvements
- End of day: `/digest` for text report, `/dashboard` for visual report
- Weekly: `/scout` to check for Claude Code updates, `/walkthrough` to update tour
- Complex feature: `/plan` before `/implement` (self-interview + critic)
