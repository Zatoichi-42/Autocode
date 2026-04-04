---
name: meta-ratchet
description: >
  Analyze what went wrong this session and propose instruction improvements.
  Runs at end of sessions or when things go badly. Use when Claude made a
  mistake, chased a rabbit hole, shipped untested code, or the user had to
  correct Claude's approach. Trigger: "/retro", "what went wrong", "improve
  instructions", "retrospective", "postmortem".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Meta-Ratchet — Learning From Failure

## Philosophy
Good instructions are SCARS, not THEORIES. Every rule in CLAUDE.md should
trace to a specific failure that it prevents. If a rule can't name the
failure it prevents, it's noise.

The human wrote 10 lines that beat 500 lines of theoretical bootstrap.
Why? Because every line was born from watching Claude fail. This skill
makes Claude do the same analysis: watch yourself fail, write the rule
that prevents it, propose it for review.

## The Failure → Rule Pipeline

### Step 1: IDENTIFY — What went wrong this session?
Read the session journal (.claude/JOURNAL.md) and recent git history.

REMEMBER: There are no edge cases. If any of these happened, they are
CERTAINTIES that will happen again. Design the rule as a main path:

- **Untested changes**: Did you edit source without a RED test first?
- **Rabbit holes**: Did you chase unrelated failures instead of staying on task?
- **False fixes**: Did you claim something was fixed without reproducing the original problem?
- **Silent failures**: Did you write code with empty catch blocks or swallowed errors?
- **Scope creep**: Did you build more than was asked for?
- **Context death**: Did compaction or session limits cause loss of important state?
- **Test pollution**: Did you modify tests to make them pass instead of fixing source?
- **Output blindness**: Did you produce results the human can't easily verify?
- **Wrong abstraction**: Did you build complex infrastructure before proving simple works?
- **Ignored instructions**: Did you skip a CLAUDE.md rule? Which one? Why?

### Step 2: FORMULATE — What rule would have prevented this?
For each identified failure, write a candidate rule. Rules must be:

- **Specific**: Not "be careful" but "reproduce the exact error string in a test"
- **Actionable**: Claude can follow it mechanically without judgment
- **Testable**: You can tell whether the rule was followed or not
- **Short**: One sentence. If it needs two sentences, it's two rules.
- **Battle-scarred**: Name the failure it prevents

Bad rule: "Always write good tests"
Good rule: "Do not edit non-test source without a recent RED signal"

Bad rule: "Stay focused"
Good rule: "Do not let unrelated failing tests redefine the task"

### Step 3: CHECK — Does this rule already exist?
Read CLAUDE.md, .claude/rules/*.md, and active skill files.
If the rule already exists but was ignored:
- Was the phrasing ambiguous? Propose clearer phrasing.
- Was it buried in a long file? Propose moving it higher.
- Was it in a skill that wasn't loaded? Propose moving to CLAUDE.md.

If the rule is genuinely new, proceed to Step 4.

### Step 4: PROPOSE — Write it to the evolution log
Append the proposal to `.claude/EVOLUTION.md`:

```markdown
## [DATE] — Proposed Rule
**Failure**: [what went wrong]
**Rule**: [the one-sentence rule]
**Placement**: [CLAUDE.md / rules/testing.md / etc]
**Status**: PROPOSED
```

Do NOT directly edit CLAUDE.md or rules files. The human reviews proposals
and promotes them. This is critical — the meta-ratchet proposes, the human
decides. Instructions are too important for unsupervised changes.

### Step 5: AUDIT — Check for instruction bloat
Count the total rules in CLAUDE.md. If approaching 25 rules:
- Can any two rules be merged into one?
- Can any rule move to a path-scoped .claude/rules/ file?
- Is any rule never triggered (no recent failure it prevents)?
- Propose removals alongside additions

The ~150-200 instruction budget is real. Every addition must justify its
cost by preventing a specific, observed failure.

### Step 6: LOG — Record the session quality score
Append to `.claude/EVOLUTION.md`:

```markdown
### Session Score: [DATE]
- Tasks attempted: [N]
- Tasks completed correctly on first try: [N]
- Times human had to correct Claude: [N]
- Rules violated: [list]
- New rules proposed: [N]
- Overall: [GOOD / ACCEPTABLE / POOR]
```

## When To Run This
- End of every session (even good ones — "what almost went wrong?")
- After any human correction ("you should have done X instead")
- After a ratchet loop with many failed experiments
- Weekly review (read EVOLUTION.md, look for patterns across sessions)

## The Meta-Ratchet Promise
Over time, CLAUDE.md should get SHORTER and SHARPER, not longer and
mushier. Each rule earns its place by preventing a named failure. Rules
that don't prevent failures get pruned. The file converges toward the
minimum set of instructions that prevent the maximum number of real
failures — exactly like the human's 10-line methodology.
