# EVOLUTION.md Promotion Workflow — From Proposed to Accepted

## The Critical Governance Layer

The bootstrap system has **three independent sources of truth**:

| Source | Authority | Update Frequency | Risk |
|--------|-----------|------------------|------|
| **CLAUDE.md** | Universal constitution | Rare (human review) | HIGH — affects every session |
| **EVOLUTION.md** | Experimental proposals | Every session (auto) | MEDIUM — requires human judgment |
| **.claude/rules/** | Path-scoped rules | Manual (human) | LOW — affects only specific paths |

This document defines the **GATE between EVOLUTION.md and CLAUDE.md** — the human's decision point.

---

## Phase 1: Proposal (Meta-Ratchet Writes)

The `/retro` command runs the meta-ratchet skill at the end of each session:

```
Session → FAILURE OBSERVED → Meta-Ratchet Analyzes → EVOLUTION.md Updated
```

The meta-ratchet appends this template to `.claude/EVOLUTION.md`:

```markdown
## [DATE] — Proposed Rule: [Short Title]
**Failure**: [Concrete failure from this session]
Example: "Claude modified test file to make test pass instead of fixing source"

**Rule**: [One-sentence mechanical rule]
Example: "Do not edit files matching **/__tests__/** during implementation phase"

**Placement**: CLAUDE.md / rules/testing.md / rules/safety.md
[Where the human should put it if accepted]

**Rationale**: [Why this rule matters]
Example: "Test files are the specification. Modifying them changes the contract.
Three sessions showed this pattern. Pre-write hook can enforce this."

**Implementation**: [How to actually implement this]
Example: "Add PreToolUse:Write hook matcher on '**/__tests__/**' that exits 2
when CLAUDE_TDD_PHASE != 'red'"

**Evidence**: [List sessions where this failure occurred]
Example: "Session #12 (2026-04-01), Session #15 (2026-04-02)"

**Conflicts**: [Does this conflict with any existing rule?]
Example: "No conflicts. Complements existing 'Do not modify test files' rule."

**Status**: PROPOSED
```

---

## Phase 2: Human Review (You Decide)

As the human, **YOU** review `.claude/EVOLUTION.md` regularly (weekly recommended).

For each PROPOSED rule, answer these questions:

### ✅ YES — Promote to CLAUDE.md
Criteria:
- **Observed in 2+ sessions?** (Not a one-time anomaly)
- **Specific enough to enforce?** (Can a hook or automated check verify compliance?)
- **Prevents a real failure?** (Not theoretical — actually happened)
- **Fits the instruction budget?** (CLAUDE.md <25 rules currently?)
- **Doesn't duplicate existing rules?** (Check all of CLAUDE.md and rules/)

**Process**:
1. Copy the rule text to CLAUDE.md (or appropriate rules/*.md file)
2. **Move the EVOLUTION entry** from "Proposed Rules" section to "Promoted Rules" section
3. Update the status line to: `**Status**: ACCEPTED — promoted [DATE]`
4. Add your decision comment: `**Approved by**: human — [brief reasoning]`
5. Commit: `git add .claude/EVOLUTION.md CLAUDE.md && git commit -m "rule: promote [title]"`

**Example**:
```markdown
## 2026-04-03 — Proposed Rule: Block Test File Edits During Implementation
**Failure**: Claude modified test file to make test pass instead of fixing source
**Rule**: Do not edit files matching **/__tests__/** during implementation phase
**Placement**: rules/testing.md
...
**Status**: ACCEPTED — promoted 2026-04-03
**Approved by**: human — Observed in 3 sessions. Hook implementation ready.
```

### ❌ NO — Reject with Explanation
Criteria for rejection:
- **One-time fluke?** (Only happened once, unlikely to repeat)
- **Too vague to enforce?** (No automated way to check)
- **Redundant?** (Already covered by existing rule)
- **Wrong layer?** (Should be a hook, not a rule)
- **Instruction bloat?** (Budget exhausted, needs to wait)

**Process**:
1. **Move the EVOLUTION entry** from "Proposed Rules" to "Rejected Rules"
2. Add: `**Reason**: [your explanation]`
3. Add: `**Rejected by**: human — [DATE] — [reason]`
4. Commit: `git add .claude/EVOLUTION.md && git commit -m "rule: reject [title] — [reason]"`

**Example**:
```markdown
## 2026-04-03 — Proposed Rule: Use Descriptive Variable Names
**Failure**: Claude used single-letter variables in loop
**Rule**: Always use descriptive variable names (min 3 chars)
...
**Status**: REJECTED
**Reason**: Too vague to enforce. Linter (ESLint) already covers this with naming rules.
**Rejected by**: human — 2026-04-03 — Redundant with existing tooling.
```

### 🔄 MAYBE — Needs More Evidence
Criteria:
- **Interesting but unproven?** (Only 1 session, watch for pattern)
- **Needs clarification?** (Proposal is too vague)
- **Needs implementation design?** (Approved in principle, but HOW to implement is unclear)

**Process**:
1. **Leave in "Proposed Rules"** section (don't move it)
2. Add a comment:
```markdown
**Status**: PROPOSED — NEEDS MORE EVIDENCE
**Comment**: Watch in next 3 sessions. If pattern repeats, promote.
**Follow-up**: [DATE you'll re-review]
```
3. No commit needed (it was already in EVOLUTION.md)

**Example**:
```markdown
## 2026-04-01 — Proposed Rule: Cache Expensive Computations
**Failure**: Component re-rendered unnecessarily on every parent update
**Rule**: Memoize expensive derived state with useMemo
...
**Status**: PROPOSED — NEEDS MORE EVIDENCE
**Comment**: Occurred once in Session #14. Could be project-specific.
Watch for pattern across UI components before promoting.
**Re-review date**: 2026-04-08
```

---

## Phase 3: Implementation (You or Claude Code)

Once promoted to CLAUDE.md, the rule takes effect **immediately in the next Claude Code session**.

### If the rule can be automated (via hook):
1. Write a hook that enforces it
2. Add the hook to `.claude/settings.json` config
3. Test the hook manually:
   ```bash
   echo '{"tool_input":{}}' | bash .claude/hooks/your-hook.sh
   ```

### If the rule is advisory (behavioral):
1. The rule appears in CLAUDE.md
2. Sessions load it automatically
3. Success depends on Claude Code's compliance (~80% for advisory rules)
4. Non-compliance will trigger a new meta-ratchet proposal next session

---

## Decision Matrix: Should This Be Promoted?

```
┌─────────────────────────────────────────────────────────────┐
│ Question                          │ YES → PROMOTE    NO → REJECT
├─────────────────────────────────────────────────────────────┤
│ Observed in 2+ sessions?          │ Required         Skip
│ Prevents real failure?            │ Required         Skip
│ Specific + Actionable?            │ Required         Skip
│ Already covered elsewhere?        │ Consolidate      Reject
│ Can be automated (hook)?          │ Prioritize       Nice-to-have
│ Budget available?                 │ Required         Wait or remove old rule
│ Helps majority of projects?       │ Move to CLAUDE   Move to path-scoped rules/
│ Noisy/Controversial?              │ Require 3+ obs   Reject as subjective
└─────────────────────────────────────────────────────────────┘
```

---

## Example: Full Promotion Workflow

### Session #12 (2026-04-01) — Failure Occurs
```
Claude edits .test.ts file to make test pass instead of fixing source.
```

### Meta-Ratchet Runs (/retro)
```markdown
## 2026-04-01 — Proposed Rule: Do Not Modify Tests During Implementation
**Failure**: Claude edited test file to make test pass
**Rule**: Do not edit files matching **/__tests__/** during implementation
**Placement**: rules/testing.md
**Rationale**: Tests are the specification. Modifying them violates TDD.
**Implementation**: PreToolUse:Write hook blocks *.test.* files when not in RED phase
**Evidence**: Session #12
**Status**: PROPOSED
```

### Session #15 (2026-04-02) — Pattern Repeats
```markdown
[New entry appended]

## 2026-04-02 — Same Pattern: Test File Modification
**Failure**: Same as Session #12 — Claude editing test files during GREEN phase
**Evidence**: Session #15
**Linked**: See 2026-04-01 proposal
**Status**: PROPOSED — PATTERN CONFIRMED
```

### Human Reviews (2026-04-03)
```
Observation: Occurred in Sessions #12 and #15 (2 independent instances).
Decision: YES, this is a real pattern. PROMOTE.
```

### You Copy to CLAUDE.md
```markdown
# CLAUDE.md (updated)

## TDD Protocol — MAX TDD
1. Name the tests first
2. Write/update tests before implementation
3. Confirm RED — tests must fail before you write source code
4. Implement the minimum to go GREEN
5. **DO NOT modify test files during implementation. Tests are the spec.**
6. Refactor only while GREEN
...
```

### You Update EVOLUTION.md
```markdown
## Promoted Rules (Accepted)

### 2026-04-03 — Test File Modification Prevention
**Failure**: Claude modified test files to make tests pass
**Rule**: Do not edit files matching **/__tests__/** during implementation
**Status**: ACCEPTED — promoted 2026-04-03
**Approved by**: human — Observed in 2 sessions (#12, #15). Clear pattern.
**Promotion commit**: a1b2c3d "rule: promote test-file-protection"

---

## Proposed Rules (Awaiting Human Review)
<!-- Meta-ratchet continues writing new proposals here -->
```

### You Add/Update Hook
```bash
# .claude/hooks/pre-write-guard.sh (updated)

if [ "${CLAUDE_TDD_PHASE:-}" != "red" ]; then
  if echo "$FILE_PATH" | grep -qE '\.test\.|\.spec\.|__tests__/|/test/|/tests/'; then
    echo '{"hookSpecificOutput":{"decision":"block","reason":"BLOCKED: Cannot modify test files during implementation"}}'
    exit 0
  fi
fi
```

### You Commit
```bash
git add -A
git commit -m "rule: promote test-file-protection to CLAUDE.md + hook enforcement"
```

### Session #20 — Rule is Live
```
New sessions load CLAUDE.md.
Rule #5 is active.
If Claude tries to edit test file during GREEN phase, hook blocks it.
```

---

## CRITICAL: The One-Way Gate

**Important**: Once a rule is **PROMOTED**, it should almost never be reverted.

Reasons to RETIRE (remove) a rule:
1. **Never prevented a failure** (proposed rule never observed again after promotion)
2. **Superseded by better rule** (two rules doing the same thing)
3. **Hook made it obsolete** (behavioral rule replaced by automated enforcement)
4. **Contradicts newer rules** (rule conflict needs resolution)

Process for RETIRING:
```markdown
## Retired Rules (Removed From Active Duty)

### 2026-04-15 — Rule: Do X (RETIRED)
**Original**: Do X to prevent Y
**Reason for retirement**: Rule never triggered a violation after 10 sessions.
**Removed from**: CLAUDE.md
**Retired by**: human — 2026-04-15
**Archive**: Can be re-promoted if failure re-occurs
```

---

## The Meta-Loop: Continuous Improvement

```
┌────────────────────────────────────────────────┐
│  Session: Claude Code Works on Project        │
│  (Guided by CLAUDE.md rules)                   │
└──────────────────┬─────────────────────────────┘
                   │
        (Claude fails in a specific way)
                   │
                   ▼
┌────────────────────────────────────────────────┐
│  /retro: Meta-Ratchet Analyzes Failure        │
│  Proposes new rule to EVOLUTION.md            │
└──────────────────┬─────────────────────────────┘
                   │
          (1-2 sessions of observation)
                   │
                   ▼
┌────────────────────────────────────────────────┐
│  Human Reviews EVOLUTION.md Proposals          │
│  - Promote if pattern confirmed               │
│  - Reject if anomaly or vague                 │
│  - Wait if needs more evidence                │
└──────────────────┬─────────────────────────────┘
                   │
         (Promoted rules update CLAUDE.md)
                   │
                   ▼
┌────────────────────────────────────────────────┐
│  Next Session: Claude Code Loads Updated      │
│  CLAUDE.md (now with scar-learned rule)       │
│  Avoids the failure that triggered it         │
└────────────────────────────────────────────────┘
```

---

## Checklist: Promoting a Rule

- [ ] Rule has been PROPOSED in EVOLUTION.md
- [ ] Observed in 2+ independent sessions (or 1 session + clear automation)
- [ ] Specific enough to test (not vague philosophy)
- [ ] Doesn't duplicate existing rules
- [ ] Fits instruction budget (CLAUDE.md <25 rules)
- [ ] Chosen placement: CLAUDE.md / rules/*.md / hook
- [ ] Implementation plan is clear (hook or advisory)
- [ ] Moved EVOLUTION.md entry from "Proposed" to "Promoted"
- [ ] Updated CLAUDE.md or rules/ with the new rule
- [ ] Created or updated hook if applicable
- [ ] Tested hook if applicable: `echo '{}' | bash .claude/hooks/your-hook.sh`
- [ ] Committed all changes: `git add -A && git commit -m "rule: promote [title]"`
- [ ] Documented decision in EVOLUTION.md

---

## FAQ

### Q: Can a rule be promoted without human approval?
**A**: No. Meta-ratchet PROPOSES, you DECIDE. This separation is critical
because instructions are too important for unsupervised self-modification.
The bootstrap system deliberately has a gate here to prevent runaway
instruction drift.

### Q: What if a promoted rule turns out to be wrong?
**A**: It happens. If you discover the rule causes more problems than it
solves, RETIRE it. Move it to the "Retired Rules" section with explanation.
The meta-ratchet will likely propose a better rule next session.

### Q: How often should I review EVOLUTION.md?
**A**: Weekly is ideal. After every 3-5 sessions at minimum. If you ignore
it for 2 weeks, you'll have dozens of proposals backed up. Review is the
human's key responsibility in this system.

### Q: Should all proposed rules be promoted?
**A**: No. ~60-70% of proposals should be promoted. The rest are:
- Too vague to enforce (reject)
- One-time anomalies (wait for confirmation)
- Redundant with existing rules (reject)
- Interesting but need clarification (wait)

### Q: Can I promote a rule that hasn't been observed yet?
**A**: Only if it's:
1. A hook-enforceable rule (automation makes it safe)
2. A security rule (blocking known vulnerabilities)
3. A refactoring of existing rules (consolidation, not new behavior)

Advisory rules should NEVER be promoted without evidence. That's how
bloat happens.

### Q: What's the difference between rules in CLAUDE.md vs rules/
**A**: 
- **CLAUDE.md** (universal): Loaded every session. <25 rule budget.
- **rules/*.md** (path-scoped): Loaded only for matching file paths.
  Used for domain-specific rules (testing, UI, security, etc).

If a rule is context-specific, put it in rules/. If it's universal,
put it in CLAUDE.md.

### Q: How does the conductor know about promoted rules?
**A**: The conductor doesn't need to. It spawns `claude -p` sessions with
prompts. Each session loads CLAUDE.md automatically. Rules are live
immediately in the next session after promotion.

### Q: Can the meta-ratchet propose rule REMOVALS?
**A**: Yes. If a rule prevents no failures for 10+ sessions, the meta-ratchet
can propose retiring it. Same promotion workflow: propose → you review → retire.

---

## The Human's Role

You are the **keeper of instruction quality**. Your job:

1. **Review EVOLUTION.md weekly** — scan for proposed rules
2. **Separate signal from noise** — promote real patterns, reject anomalies
3. **Enforce the budget** — keep CLAUDE.md <25 rules
4. **Watch for conflicts** — new rules shouldn't contradict old ones
5. **Champion simplicity** — prefer simple rules over complex ones
6. **Trust the meta-ratchet** — it only proposes evidence-based rules

The best instruction set is **SHORT and SCARRED**. Every rule should tell
a story of a failure it prevented. If a rule can't tell that story, it
doesn't belong in the system.

---

## TL;DR

**To promote an EVOLUTION.md rule to ACCEPTED:**

1. **Wait** for rule to be proposed in EVOLUTION.md (happens automatically via /retro)
2. **Observe** the failure in 2+ sessions
3. **Read** the proposal in EVOLUTION.md
4. **Decide** — PROMOTE, REJECT, or WAIT
5. **If PROMOTE**:
   - Copy rule to CLAUDE.md or rules/*.md
   - Move EVOLUTION.md entry to "Promoted Rules" section
   - Update status: `Status: ACCEPTED`
   - Implement hook if applicable
   - Commit: `git add -A && git commit -m "rule: promote [title]"`
6. **If REJECT**:
   - Move EVOLUTION.md entry to "Rejected Rules" section
   - Add reason
   - Commit
7. **If WAIT**:
   - Leave in "Proposed Rules"
   - Add follow-up date
   - Monitor in future sessions

---

## Next: Review Your EVOLUTION.md

You should have a `.claude/EVOLUTION.md` file. Review it now:

```bash
cat .claude/EVOLUTION.md
```

Scan the "Proposed Rules" section. For each rule:
- Has it been observed 2+ times? → PROMOTE
- Is it vague? → REJECT or rewrite
- Need more data? → WAIT with follow-up date

This is your highest-leverage activity for keeping the bootstrap healthy.
