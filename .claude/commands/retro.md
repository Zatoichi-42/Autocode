# /retro — Session Retrospective

Run the meta-ratchet to analyze what went well and what went wrong this
session. Proposes instruction improvements to EVOLUTION.md for human review.

## Process
1. Load the `meta-ratchet` skill
2. Read the session journal (.claude/JOURNAL.md)
3. Read recent git history for this session
4. Identify failures from the failure pattern checklist
5. For each failure, formulate a candidate rule
6. Check if the rule already exists
7. Write proposals to .claude/EVOLUTION.md
8. Score the session
9. Print a plain-text summary to stdout

## When To Use
- End of every work session (even good ones)
- After the human corrected Claude's approach
- After a ratchet loop completed
- When something felt "off" about the session

## Output (to stdout)
```
Session Retro — [DATE TIME]
Duration: ~NN turns

What went well:
  - [concrete positive]
  - [concrete positive]

What went wrong:
  - [failure] → proposed rule: "[rule]"
  - [failure] → existing rule violated: "[rule]" (not followed because: [reason])

Rules proposed: NN (see EVOLUTION.md)
Session score: [GOOD / ACCEPTABLE / POOR]
```

## IMPORTANT
The /retro command PROPOSES rule changes. It does NOT modify CLAUDE.md
or rules files directly. The human reviews EVOLUTION.md and decides
what gets promoted. This separation is critical — instructions are too
important for unsupervised self-modification.
