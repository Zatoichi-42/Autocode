---
name: assumption-audit
description: >
  Challenge the architectural assumptions of the bootstrap itself.
  Not code review — SYSTEM review. Finds blind spots by asking questions
  the system was never designed to answer. Use when: "/audit-assumptions",
  "what are we missing", "blind spots", "challenge the architecture",
  "what will break", or at the start of any major phase.
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Agent
effort: high
---

# Assumption Audit — Finding What We Can't See

## Why This Exists
The meta-ratchet catches rule-level failures (wrong instruction → bad output).
The self-critic catches plan-level failures (wrong design → wrong feature).
This skill catches ARCHITECTURE-level failures (wrong assumptions → wrong system).

Example of what this catches that nothing else does:
"We assumed Claude Code sessions stay alive. They don't. We need
an external controller." — This gap existed for 4 iterations of the
bootstrap before a human noticed it. Nothing in the system could find
it because everything in the system runs inside the thing that dies.

## The Inversion Protocol

### Step 1: LIST — What does the system depend on being true?
Read CLAUDE.md, ARCHITECTURE.md, settings.json, all skills, all agents.
For each component, write down what it ASSUMES:

Example assumptions to find:
- "A Claude Code session is running" (when does this not hold?)
- "The human will review X" (what if they don't for a week?)
- "Git is initialized" (what if it's not?)
- "Tests exist" (what if the project has zero tests yet?)
- "Internet is available" (what if it's not?)
- "The previous session wrote JOURNAL.md" (what if it crashed before the Stop hook?)
- "jq is installed" (what if it's not?)
- "The project is Node/Python" (what about Go, Rust, etc?)

### Step 2: INVERT — What happens when each assumption is FALSE?
For each assumption, imagine it's false. Trace the consequences:

```
Assumption: "The Stop hook writes JOURNAL.md every turn"
Inversion: "The process was killed before the Stop hook fired"
Consequence: JOURNAL.md is stale. Next session has wrong context.
Gap: Nothing detects stale journals. No timestamp comparison.
Fix: Conductor checks JOURNAL.md timestamp vs last known session end.
```

Delegate inversions to the self-critic subagent for genuine adversarial thinking:

```
Agent(
  agent_type="self-critic",
  prompt="Here are the assumptions this system makes: [list].
  For each one, imagine it's FALSE. What breaks? What gap exists?
  What would a production engineer say about this system's reliability?
  Be ruthless. Write findings to .claude/ASSUMPTION-AUDIT.md",
  model="opus"
)
```

### Step 3: CATEGORIZE — What kind of gap is each finding?
- **Topology gap**: Wrong process architecture (like the missing controller)
- **Dependency gap**: Assumes a tool/service exists that might not
- **Lifecycle gap**: Doesn't handle a state transition (startup, crash, resume)
- **Observability gap**: Something happens but nobody can see it
- **Human gap**: Assumes human attention that might not exist
- **Scale gap**: Works for 1 but breaks at 10

### Step 4: PRIORITIZE — What would hurt most?
Score each gap:
- Likelihood it actually occurs (1-5)
- Severity when it occurs (1-5)
- Score = Likelihood × Severity

Gaps scoring ≥15 are critical. Gaps scoring ≥9 are important.

### Step 5: PROPOSE — Write fixes to EVOLUTION.md
For each critical/important gap:

```markdown
## [DATE] — Assumption Audit Finding
**Assumption**: [what we assumed]
**Reality**: [what actually happens]
**Gap type**: [topology / dependency / lifecycle / observability / human / scale]
**Score**: [likelihood] × [severity] = [total]
**Proposed fix**: [specific, actionable change]
**Status**: PROPOSED
```

### Step 6: GENERATE QUESTIONS — For next session's self-plan
Write questions to `.claude/OPEN-QUESTIONS.md` that the self-plan
skill should ask before starting any major feature:

```markdown
- What happens if this session dies mid-implementation?
- Who/what restarts this work?
- Can the human see what's happening without running any commands?
- What happens if the human doesn't look at this for 3 days?
- What external dependencies are we introducing?
- What happens when this fails at 3am with nobody watching?
```

These questions become STANDARD questions in the self-plan protocol.

## When To Run
- At the START of any new project (before the first feature)
- After the first 5 sessions (enough history to see patterns)
- After any major architectural change
- Monthly, as a health check
- Whenever the human says "what are we missing?"

## Integration With Self-Plan
After this audit runs, the self-plan skill reads OPEN-QUESTIONS.md
and includes those questions in every Round 2 (CHALLENGE) phase.
This means the system's known blind spots become part of every
future planning cycle.
