# /check — Random Spot-Check Review

Quick, anytime quality check the human can run in 30 seconds.
Not a "morning review" — designed for ANY moment: lunch break,
between meetings, 2am curiosity, phone check while walking the dog.

## Effort Level
effort: low

This command is FAST. No full test suite. No deep analysis.
Snapshot of right now, nothing more.

## Output: Print directly to stdout (NO file generation)

```
━━━ SPOT CHECK [datetime] ━━━━━━━━━━━━━━━━━━━━━━━━

🚦 [GREEN/YELLOW/RED]  [one-sentence reason]

SINCE LAST CHECK ([time ago]):
  Commits: N        Files changed: N
  Tests:   N pass / N fail / N new
  Ratchet: N experiments, N kept

LAST 3 COMMITS:
  • [hash] [message] ([time ago])
  • [hash] [message] ([time ago])
  • [hash] [message] ([time ago])

CONCERNS:
  [list anything worrying, or "None — looking good"]

NEXT TASK:
  [first incomplete item from TODO.md]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Data Gathering (FAST — all <5 seconds)
```bash
# Commits since last check (or last 24h)
git log --oneline --since="24 hours ago" | head -5

# Test status (quick, no full suite)
# Just check if tests pass, don't analyze deeply
npm run test -- --passWithNoTests --silent 2>&1 | tail -3

# Modified files
git diff --stat

# TODO next item
grep -m1 '^\- \[ \]' .claude/TODO.md

# Ratchet state (just the summary numbers)
cat .claude/ratchet-state.json | jq '{experiments: .experiment_count, kept: (.kept_improvements | length), score: .best_score}' 2>/dev/null
```

## Concerns Detection (fast heuristics)
Flag these if true:
- Tests failing → "⚠ N tests failing"
- No commits in 12+ hours during active work → "⚠ No activity in [N] hours"
- Ratchet stalled (5+ consecutive failures) → "⚠ Ratchet stalled"
- Context >60% → "⚠ Context at [N]% — consider /compact"
- Uncommitted changes >10 files → "⚠ [N] uncommitted files — commit soon"
- EVOLUTION.md has >3 unreviewed proposals → "📋 [N] rule proposals awaiting review"

## Rules
- NEVER generate a file. Print to stdout ONLY.
- NEVER run full test suite. Use --passWithNoTests or equivalent quick mode.
- NEVER take more than 10 seconds total.
- Keep output under 25 lines.
- This is a GLANCE, not an audit.
