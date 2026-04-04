# Architecture & Design Decisions

## Bootstrap System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    HUMAN (Direction Setter)                  │
│  - Writes program.md (experiment directions)                │
│  - Reviews ratchet results                                  │
│  - Provides naive prompts → system handles complexity       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   CLAUDE.md (Constitution)                   │
│  - Loaded every session                                     │
│  - Stack, commands, rules, architecture map                 │
│  - Links to skills, agents, docs via @imports               │
└───────────────────────────┬─────────────────────────────────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────────┐
│   HOOKS (Guard)  │ │ SKILLS (How) │ │  AGENTS (Workers)    │
│                  │ │              │ │                      │
│ PreToolUse:      │ │ ratchet-loop │ │ tdd-test-writer      │
│  - security      │ │ tdd-loop     │ │ tdd-implementer      │
│  - write guard   │ │              │ │ code-reviewer         │
│ PostToolUse:     │ │              │ │ ui-tester            │
│  - autoformat    │ │              │ │                      │
│ Stop:            │ │              │ │                      │
│  - verify tests  │ │              │ │                      │
│ SessionStart:    │ │              │ │                      │
│  - load context  │ │              │ │                      │
└──────────────────┘ └──────────────┘ └──────────────────────┘
              │             │                    │
              └─────────────┼────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                 THE RATCHET LOOP (Engine)                    │
│                                                             │
│  ┌──────────┐   ┌────────────┐   ┌───────────┐            │
│  │1.BASELINE├──►│2.HYPOTHESIZE├──►│3.IMPLEMENT│            │
│  └──────────┘   └────────────┘   └─────┬─────┘            │
│                                        │                    │
│  ┌──────────┐   ┌────────────┐   ┌─────▼─────┐            │
│  │6.ITERATE │◄──┤5.DECIDE    │◄──┤4.MEASURE  │            │
│  │  & LEARN │   │ Keep/Revert│   │           │            │
│  └──────────┘   └────────────┘   └───────────┘            │
│                                                             │
│  Ratchet: score can only go UP. Bad changes revert.        │
│  State persists in .claude/ratchet-state.json              │
│  Directions come from program.md                           │
└─────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                    GIT (Memory & Safety)                     │
│                                                             │
│  - Every kept improvement = atomic commit                   │
│  - Every failed experiment = reverted (no trace in history) │
│  - Feature branches isolate work                            │
│  - Worktrees enable parallel agent sessions                 │
│  - Full history = rollback to any point                     │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Skills vs CLAUDE.md
CLAUDE.md is loaded EVERY session (~150-200 instruction budget).
Skills load ON DEMAND. Put universal rules in CLAUDE.md, specialized
workflows in skills. This prevents context bloat.

### 2. Subagents for Context Isolation
TDD requires separate context for test-writing vs implementation.
If both happen in the same window, the LLM "cheats" by writing
tests that match its planned implementation. Subagents prevent this
by running in isolated context windows.

### 3. Git as Memory
Claude has no memory between sessions. Git provides:
- State persistence (ratchet-state.json is committed)
- Undo capability (revert any experiment)
- Branching for parallel work
- History as documentation

### 4. Hooks are Deterministic, CLAUDE.md is Advisory
CLAUDE.md compliance is ~80%. Hooks execute 100% of the time.
Security-critical rules (no secrets in commits, no destructive commands)
MUST be hooks. Style preferences can be CLAUDE.md.

### 5. The Ratchet Never Goes Backward
Inspired by Karpathy's AutoResearch. The composite score can only
increase. Any change that lowers it is automatically reverted.
This ensures autonomous operation is safe.

### 6. One Change Per Experiment
Multiple simultaneous changes make it impossible to attribute
improvement or regression. Keep changes atomic.

### 7. Instructions Are Scars, Not Theories
Every rule in CLAUDE.md must trace to a specific observed failure.
The meta-ratchet skill enforces this: failures get analyzed, rules
get proposed, the human promotes or rejects. Over time, CLAUDE.md
gets shorter and sharper, not longer and mushier. Rules that don't
prevent named failures get pruned.

### 8. The Human Sees Plain Text, Not Dashboards
The human judges quality through files they can `cat` in terminal:
- JOURNAL.md: current state (updated every turn)
- digest-YYYY-MM-DD.md: daily health report with deltas
- EVOLUTION.md: instruction improvement proposals
No servers, no React apps, no complex tooling to break.

### 9. Continuous Journaling Survives Everything
The Stop hook writes JOURNAL.md on every Claude turn.
If the session crashes, gets rate-limited, hits token ceiling,
or the laptop battery dies, the journal is at most ONE TURN old.
SessionStart reads it on resume. No state is ever truly lost.

### 10. The System Scouts Its Own Tooling
The `/scout` skill periodically reads the Claude Code changelog,
scores new features for applicability, and proposes A/B tests.
Features are never auto-adopted — they go through the same
EVOLUTION.md proposal → human review → experiment → merge pipeline.

### 11. Configurable Thinking Depth
High-order work (plan, design, critique) uses opus at high effort.
Lower-order work (implement, test, scan) uses sonnet at standard/low effort.
Configured in model-config.json, applied via agent frontmatter and
skill effort fields. This maps to the real Claude Code `effort`
frontmatter feature.

### 12. Self-Planning Before Building
Complex features trigger the self-plan skill which runs a structured
self-interview: understand → challenge (via self-critic subagent on opus)
→ simplify → sequence → verify. The critic runs in a SEPARATE context
(subagent) so it genuinely challenges the plan instead of rubber-stamping
its own ideas. PLAN.md becomes the spec that TDD tests against.

### 13. External Control Layer (Conductor)
Claude Code cannot restart itself. When a session dies from rate limits,
token ceilings, or crashes, something OUTSIDE must detect the death and
restart work. The conductor script (`scripts/conductor.sh`) is that
external heartbeat. It:
- Spawns `claude -p` sessions with task context from JOURNAL.md
- Monitors exit codes and output for rate limits vs completions vs errors
- Waits appropriate intervals before restarting (5min for rate limits)
- Tracks cost and enforces budget limits
- Generates a live HTML dashboard that auto-refreshes every 15 seconds
- Can be viewed from any browser, including phones on the same network
- Decides what task to run next by reading TODO.md

The conductor is the ONLY component that runs outside Claude Code.
Everything else (hooks, skills, agents, rules) runs inside sessions.

### 14. Three Levels of Self-Correction
The system has three distinct layers of self-improvement, each
catching a different class of failure:

**Meta-ratchet (rule-level)**: "This session, Claude skipped TDD."
  → Proposes: "Do not edit non-test source without a RED signal."
  → Scope: individual instructions

**Self-critic (plan-level)**: "This plan has a missing edge case."
  → Proposes: revised plan with the gap addressed
  → Scope: feature design

**Assumption-audit (architecture-level)**: "This system assumes
   sessions stay alive. They don't."
  → Proposes: external controller, lifecycle management
  → Scope: entire system topology

Each level feeds questions into the next session's self-plan via
OPEN-QUESTIONS.md. This means discovered blind spots become
PERMANENT parts of future planning cycles.

### 15. Two-Layer Architecture: Supervisor + Workers
Claude Code sessions are WORKERS — skilled but mortal.
The conductor is the SUPERVISOR — simple but immortal.

Workers die. That's expected. The supervisor detects death,
decides what to do (retry, wait, move on), and spawns a new worker.
State survives in files (JOURNAL.md, TODO.md, ratchet-state.json)
that both layers can read.

The conductor is deliberately simple (bash script, not AI) because
the supervisor must be DETERMINISTIC. If the supervisor is also AI,
you have the same fragility problem one level up. The supervisor
uses if/else, not language models.

### 16. There Are No Edge Cases, Only Certainties
This is the foundational design principle of the entire system.
If it can happen, it will happen. Every failure mode is a normal
operating condition, not an exception.

This principle has a corollary for error handling:
**Fail CLOSED, not open.** When a security hook crashes, it must
BLOCK the action (exit 2), not allow it (exit 1). When the conductor
can't parse state, it must STOP, not guess. When a tool is missing,
the hook must REFUSE, not skip validation.

The specific failure cascade we design for:

```
Build WILL break        → Ratchet revert is the PRIMARY path
Claude WILL write bad   → Tests catch it. Humans catch the rest.
  code                    Meta-ratchet improves tests over time.
Hooks WILL fail         → Fail closed (exit 2). Session-start
                          verifies hooks are executable.
Skills WILL fail        → Ratchet reverts. Retro analyzes. Rules improve.
OS WILL fail            → Conductor is re-entrant (cron restarts it).
                          State lives in files, not memory.
Conductor WILL fail     → Pidfile prevents duplicates. Cron restarts.
                          State file is the source of truth.
UI WILL fail            → Plain-text reports (/check, /digest) are
                          the fallback. HTML is convenience, not critical.
Deployment WILL fail    → Git provides rollback to any commit.
                          Every kept improvement is an atomic commit.
Network WILL fail       → All core ops (test, build, lint, git) work
                          offline. Scout and MCP are non-fatal.
Disk WILL fill          → Session-start prunes logs >7 days.
                          Conductor warns at <500MB.
Context WILL exhaust    → Journal writes every turn. Compact hook
                          preserves state. Conductor restarts sessions.
Human WILL be absent    → Conductor runs autonomously. Reports
                          accumulate. System degrades gracefully.
Everything WILL fail    → The system's job is not to prevent failure.
                          It is to RECOVER from failure automatically
                          and LEARN from failure over time.
```

See docs/ESCAPE-HATCHES.md for the complete failure mode catalog.

### Phase 2 Control Plane Strategy
The conductor bash script is the Phase 1 supervisor. It is
deliberately crude — a bash loop with if/else — because the
supervisor MUST be deterministic and must never die.

Phase 2 supervisor candidates (track but do not adopt yet):
- Claude Code native orchestration (agent teams, channels, dispatch)
  → Watch for: stability, lifecycle management, budget controls
- OpenClaw / dedicated orchestrator
  → Watch for: maturity, community adoption, integration cost
- Custom N2N solution
  → Watch for: need exceeding what bash conductor provides

Criteria for Phase 2 transition:
- Phase 1 conductor has been running for 2+ weeks
- At least 3 specific limitations are documented in EVOLUTION.md
- The replacement solves those limitations without introducing new ones
- The replacement reads the same state files (JOURNAL.md, TODO.md, etc)

Do NOT adopt a Phase 2 supervisor because it's shinier.
Adopt it because the Phase 1 conductor is provably insufficient
for documented, specific, repeated failures.

## Context Window Strategy

| Usage | Action |
|-------|--------|
| 0-50% | Work freely |
| 50-70% | Run `/compact` preserving: file list, test status, branch, tasks |
| 70-90% | Commit current work, prepare handoff notes, start new session |
| 90%+ | STOP. `/clear` or new session mandatory |

## Worktree Strategy for Parallel Work
```bash
# Feature work
claude --worktree feat-auth

# Bug fix (separate session, separate files)
claude --worktree fix-login-bug

# Ratchet loop (runs experiments without affecting your work)
claude --worktree ratchet-session
```
Each worktree gets its own branch, files, and Claude context. 



####################################

