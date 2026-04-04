---
name: scout
description: >
  Scan Claude Code changelog for new features relevant to this project's
  bootstrap. Propose A/B tests for promising features. Use when: "/scout",
  "check for updates", "new features", "what's new in claude code",
  "upgrade bootstrap", or periodically in autonomous loops.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
effort: low
---

# Scout — Release Scanner & Feature A/B Tester

## Purpose
Claude Code ships updates multiple times per week. New hooks, new
frontmatter fields, new agent capabilities, performance fixes — any of
these could improve this bootstrap. Scout finds them and proposes
controlled experiments to test whether they help.

## Step 1: FETCH — Get Latest Changelog
```bash
# Fetch the official changelog
curl -s https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md \
  | head -300 > /tmp/cc-changelog-latest.md
```

Read the fetched changelog. Also check the current installed version:
```bash
claude --version 2>/dev/null || echo "claude CLI not in PATH"
```

## Step 2: FILTER — Identify Relevant Changes
Scan changelog entries since last scout run (check `.claude/scout-state.json`
for last scanned version). Focus on:

- **Hook events**: New events we could use (e.g., PermissionDenied, PostToolUseFailure)
- **Frontmatter fields**: New skill/agent capabilities (e.g., effort, background, memory)
- **Agent features**: Changes to subagents, agent teams, task tool
- **Performance fixes**: Anything that affects long sessions, compaction, resume
- **Security**: New permission modes, sandbox features
- **Context management**: Changes to compaction, memory, CLAUDE.md loading
- **Control plane / lifecycle**: Channels, Dispatch, Remote Control, session management,
  scheduling, /loop — anything that could upgrade the conductor from bash to native.
  Flag these prominently as PHASE 2 CANDIDATES in the scout report.
- **Orchestration**: Agent teams stability, worktree improvements, parallel execution
  — anything that could enable Phase 3 multi-agent patterns.

Ignore: UI cosmetic fixes, IDE-specific features, platform-specific fixes
not relevant to our OS.

## Step 3: ASSESS — Score Each Feature
For each relevant feature, assess:

1. **Applicability**: Does this relate to something in our bootstrap? (0-3)
2. **Risk**: Could adopting this break existing functionality? (0-3, lower=safer)
3. **Effort**: How much work to integrate? (0-3, lower=easier)
4. **Impact**: How much would this improve our workflow? (0-3, higher=better)

Score = (Applicability + Impact) - Risk - (Effort / 2)
Features with score >= 3 are worth testing.

## Step 4: PROPOSE A/B TEST — Write Experiment Plan
For each high-scoring feature, write a test plan to `.claude/EVOLUTION.md`:

```markdown
## [DATE] — Feature Scout: [Feature Name]
**Source**: Claude Code v[version] changelog
**Feature**: [description]
**Score**: [N] (applicability=[N] impact=[N] risk=[N] effort=[N])
**Hypothesis**: [What we expect to improve]
**Test plan**:
  - Branch A (control): current bootstrap behavior
  - Branch B (experiment): bootstrap with feature integrated
  - Measure: [what metric proves it works]
  - Duration: [how many sessions to test]
**Status**: PROPOSED
```

## Step 5: EXECUTE A/B TEST (if human approves)
When the human promotes a scout proposal:

1. Create a worktree for the experiment: `claude --worktree scout-test-[feature]`
2. Integrate the feature in the experiment worktree
3. Run normal work in BOTH worktrees for the specified duration
4. Compare metrics (test pass rate, session quality scores, ratchet progress)
5. Write results to EVOLUTION.md
6. If experiment wins: merge feature into main bootstrap
7. If control wins: delete experiment worktree, note result

## Step 6: UPDATE STATE
Write to `.claude/scout-state.json`:
```json
{
  "last_scanned_version": "2.1.90",
  "last_scan_date": "2026-04-03",
  "features_assessed": 5,
  "experiments_proposed": 2,
  "experiments_active": 0,
  "experiments_completed": []
}
```

## Schedule
- Run `/scout` weekly, or after any `claude --version` bump
- Can be included in ratchet loop as a periodic check
- Human reviews proposals in EVOLUTION.md before any changes are made

## Safety
- NEVER auto-adopt features. Always propose → human reviews → test → merge.
- If a changelog entry mentions breaking changes, flag it prominently.
- Keep scout-state.json updated so we don't re-assess old features.
