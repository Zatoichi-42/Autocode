---
name: ratchet-loop
description: >
  Autonomous improvement loop inspired by Karpathy's AutoResearch pattern.
  Runs propose-implement-measure-keep/revert cycles. Use when the user says
  "improve", "optimize", "ratchet", "experiment loop", "autoresearch", or
  "make it better". Also auto-triggers on "/ratchet" command.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash .claude/hooks/pre-tool-security.sh"
---

# Ratchet Loop — Autonomous Improvement Cycle

## Philosophy
Like Karpathy's AutoResearch: propose a change, measure it, keep if better, revert if worse. Repeat.
The human sets DIRECTION. The agent handles ITERATION.

## The Six-Step Loop

### Step 1: BASELINE — Establish Ground Truth
Before changing anything:
1. Read `.claude/ratchet-state.json` for existing baseline (create if missing)
2. Run the FULL test suite. Record: pass count, fail count, time
3. Run the build. Record: success/fail, warnings count, bundle size
4. Run linter. Record: error count, warning count
5. If UI project: capture current state description
6. Save all metrics to `.claude/ratchet-state.json`

```json
{
  "best_score": null,
  "experiment_count": 0,
  "baseline_metrics": {
    "tests_passing": 0,
    "tests_failing": 0,
    "test_time_ms": 0,
    "build_success": false,
    "lint_errors": 0,
    "lint_warnings": 0,
    "bundle_size_kb": 0,
    "timestamp": ""
  },
  "experiments": [],
  "kept_improvements": []
}
```

### Step 2: HYPOTHESIZE — Propose ONE Change
Read the `program.md` directions file (or user prompt) for guidance.
Propose exactly ONE atomic change. Write the hypothesis to the log:
- What will change
- Why it should improve things
- What metric will prove it
- What the rollback plan is (usually `git checkout -- <files>`)

IMPORTANT: Only ONE change per cycle. Multiple changes make it impossible to know what worked.

### Step 3: IMPLEMENT — Make the Change
1. Create a git checkpoint: `git stash` or note current HEAD
2. Implement the MINIMAL change to test the hypothesis
3. Keep the diff as small as possible

### Step 4: MEASURE — Run the Gauntlet
Run the exact same measurements as Step 1:
1. Full test suite
2. Build
3. Linter
4. Any custom metrics from `program.md`

Compare EVERY metric against baseline. Compute a composite score:
```
score = (tests_passing / total_tests) * 40
      + (build_success ? 20 : 0)
      + max(0, (1 - lint_errors / max(baseline_lint_errors, 1))) * 15
      + (custom_metric_improvement) * 25
```

### Step 5: DECIDE — Keep or Revert (The Ratchet)
- If score >= baseline score AND no new test failures: **KEEP**
  - `git add -A && git commit -m "ratchet: [description of improvement]"`
  - Update `.claude/ratchet-state.json` with new baseline
  - Log to `kept_improvements` array
- If score < baseline OR new test failures: **REVERT**
  - `git checkout -- .` to revert all changes
  - Log the failed experiment with reason to `experiments` array

NEVER lower the bar. The ratchet only turns one way.

### Step 6: LEARN & ITERATE — Update Direction
1. Log what worked/didn't in `.claude/ratchet-state.json`
2. If 3+ consecutive failures on same area: SKIP that area, try different direction
3. If improvement found: check if same CATEGORY has more potential
4. Read `program.md` for next direction to explore
5. GOTO Step 2

## Stopping Conditions
Stop the loop when ANY of these are true:
- User interrupts (always respect this immediately)
- All directions in `program.md` have been explored
- 5 consecutive experiments with no improvement
- Context window approaching 50% (preserve context for reporting)
- Critical failure (tests go from passing to crashing)

## On Stop: Report
When the loop ends, produce a summary:
- Total experiments run
- Improvements kept (with descriptions)
- Failed experiments (with reasons)
- Current vs original baseline metrics
- Suggestions for next session's `program.md`

## Safety Rails
There are no edge cases. Every one of these WILL happen. These are normal operating procedures:

- Tests WILL be the specification. You WILL not modify them. (Runs every cycle.)
- Ratchet state WILL be the single source of truth. Only this process writes it.
- The build WILL break on most experiments. Revert is the PRIMARY path, not fallback.
- Unrelated tests WILL fail. Note them, do not chase them. Stay on task.
- You WILL NOT edit non-test source without a recent RED signal, even inside the ratchet.
- The session WILL hit context limits. At 50%, stop the loop, commit, write JOURNAL.md, let the conductor restart.
- Rate limits WILL fire. The conductor handles retry. Your job is to leave clean state.
- Maximum 20 experiments per session. The conductor spawns a fresh session for more.
