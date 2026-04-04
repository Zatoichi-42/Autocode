# Debugging Guide & Recovery Patterns

## Core Principle: There Are No Edge Cases
Every failure documented here WILL happen. These are not theoretical
scenarios or unlikely events. They are normal operating conditions.
When writing fixes, design them as primary code paths, not exception handlers.

## Hook-Specific Failures (These WILL Happen)

### Hook Uses Exit 1 Instead of Exit 2
**Symptom**: Hook appears to run, log says "hook error", but the action proceeds.
**Cause**: In Claude Code, exit 1 is a NON-BLOCKING error. Only exit 2 blocks.
**Fix**: All blocking hooks must use exit 2, OR output JSON with
`{"hookSpecificOutput":{"decision":"block","reason":"..."}}` and exit 0.
Our hooks use the JSON decision format for PreToolUse (most reliable).

### Hook Crashes on Unexpected Input
**Symptom**: Hook encounters a JSON field it didn't expect. jq fails.
Exit code is 1 (non-blocking). Action proceeds unguarded.
**Fix**: All hooks have `trap '... exit 2' ERR` — any crash fails CLOSED.
The trap ensures unexpected errors block the action rather than allowing it.

### jq Not Installed
**Symptom**: Every hook that parses JSON silently fails. All security gone.
**Fix**: Every hook checks `command -v jq` first. If missing, exit 2 with
clear error message. SessionStart hook also warns about missing jq.

### Claude Bypasses Write Hook via Bash
**Symptom**: Claude uses `echo "content" > file.txt` instead of the Write tool.
The PreToolUse:Write hook never fires.
**Fix**: PreToolUse:Bash hook scans for redirect patterns to sensitive files.
PostToolUse:Bash hook can scan changed files after Bash commands.
This is a known gap in Claude Code's hook architecture.

### Stop Hook Infinite Loop
**Symptom**: Claude enters a loop where Stop fires, outputs text, Claude
processes the text, stops, fires Stop again, forever until context dies.
**Fix**: Check `stop_hook_active` field in input JSON. Exit immediately if true.
Our stop-journal.sh checks this FIRST before doing anything.

### Hook File Not Executable
**Symptom**: Hook silently doesn't run. No error. No protection.
**Fix**: SessionStart hook checks and fixes permissions on all sibling hooks.
Bootstrap command also verifies. `chmod +x .claude/hooks/*.sh`

## Claude Code Behavioral Issues

### Claude Ignores CLAUDE.md Instructions
**Symptom**: Claude doesn't follow rules you've set.
**Cause**: File is too long (>200 instructions) or instructions aren't relevant to current task.
**Fix**:
- Trim CLAUDE.md to essential rules only
- Move specialized instructions to skills
- Add emphasis: "IMPORTANT:" or "YOU MUST" for critical rules
- Check if instruction is ambiguous — rewrite as concrete command

### Claude Modifies Tests When It Should Only Fix Code
**Symptom**: Green tests but feature doesn't work as expected.
**Cause**: Claude took the path of least resistance — changing tests instead of implementation.
**Fix**:
- Add to CLAUDE.md: "NEVER modify test files during implementation. Tests are the spec."
- Use TDD subagents (test-writer has no Write permission for src/)
- Add PreToolUse hook that blocks writes to `**/__tests__/**` during implementation
- Commit tests BEFORE starting implementation

### Claude Chases Unrelated Failing Tests
**Symptom**: Claude abandons current task to fix a pre-existing test failure.
**Cause**: Claude sees RED and feels compelled to fix it, even if unrelated.
**Fix**:
- CLAUDE.md rule: "Do not let unrelated failing tests redefine the task"
- Before starting work, run full suite and NOTE pre-existing failures
- Tell Claude explicitly: "These tests were already failing. Ignore them."
- If Claude keeps getting distracted: use scope-lock prompt ("ONLY work on X")

### Claude Claims Fix Without Reproducing the Bug
**Symptom**: Claude says "fixed" but the original user-reported behavior still occurs.
**Cause**: Claude fixed what it *thought* the bug was, not what the user actually saw.
**Fix**:
- CLAUDE.md rule: "Reproduce the exact user command before claiming a fix"
- CLAUDE.md rule: "If user gives exact error string, reproduce it in a test"
- Require RED→GREEN cycle on the actual reproduction case
- For CLI bugs: test the real entrypoint, not just internal functions

### Claude Generates Code Then Doesn't Test It
**Symptom**: Code written but never verified.
**Cause**: Prompt didn't explicitly request testing, or context got cluttered.
**Fix**:
- PostToolUse hook on Write|Edit that runs relevant test file
- Stop hook that checks test status and warns if failing
- Add to CLAUDE.md: "After every code change, run the relevant test file"

### Context Window Exhaustion
**Symptom**: Responses become vague, instructions ignored, hallucinations increase.
**Cause**: Context > 70% full.
**Fix**:
- Proactive: `/compact` at 50% with focus notes
- If already at 70%+: commit work, write handoff notes to `.claude/HANDOFF.md`, start fresh
- Emergency: `/clear` (loses all context)
- Prevention: Keep CLAUDE.md lean, use skills not inline instructions

### Ratchet Loop Finds No Improvements
**Symptom**: 5+ consecutive experiments fail or show no improvement.
**Cause**: Either the directions in program.md are too ambitious, metrics are noisy, or genuine plateau.
**Fix**:
- Review program.md — are directions specific enough?
- Check if test suite is flaky (run 3x, check for variance)
- Try different category of improvements
- Accept plateau and move to new area
- Consider if baseline measurement is correct

### Subagent Returns Garbage
**Symptom**: Subagent output is malformed, incomplete, or obviously wrong.
**Cause**: Prompt was too vague, maxTurns too low, or wrong model selected.
**Fix**:
- Increase `maxTurns` in agent frontmatter
- Be more specific in the `prompt` parameter
- Use `sonnet` for most tasks (good speed/quality balance)
- For complex reasoning: use `opus` (costs more but better results)
- Check that the subagent has the right tool permissions

## Recovery Patterns

### Nuclear Reset
When everything is broken and you can't figure out why:
```bash
git stash                              # Save current changes
git checkout main                      # Return to known-good state
git checkout -b fresh-attempt          # New clean branch
git stash pop                          # Optionally bring changes back
```

### Ratchet State Corruption
If `.claude/ratchet-state.json` gets corrupted:
```bash
git log --oneline --all -- .claude/ratchet-state.json  # Find last good version
git checkout <commit-hash> -- .claude/ratchet-state.json
```
Or delete it and let `/bootstrap` recreate from scratch.

### Hook Not Firing
1. Check `.claude/settings.json` — is the hook event spelled correctly?
2. Check file permissions: `chmod +x .claude/hooks/*.sh`
3. Test hook manually: `echo '{}' | bash .claude/hooks/your-hook.sh`
4. Check matcher: does it match the tool name exactly? (case-sensitive)
5. Type `/hooks` in Claude Code to see the read-only browser view

### A/B Testing Pattern for Uncertain Changes
When you're not sure which approach is better:
```bash
# Branch A
git checkout -b experiment/approach-a
# ... implement approach A, run tests, measure metrics

# Branch B  
git checkout -b experiment/approach-b
# ... implement approach B, run tests, measure metrics

# Compare
git diff experiment/approach-a..experiment/approach-b
# Choose the winner, merge to your feature branch
```

## Common Error Messages and Solutions

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| "BLOCKED: Attempting to commit sensitive files" | Hook caught .env or credentials | Remove sensitive file from staging: `git reset HEAD <file>` |
| "BLOCKED: This is a protected/generated file" | Tried to edit lock file or generated code | Don't edit these directly. Change the source and regenerate. |
| "Tests are currently FAILING" | Stop hook warning | Fix failing tests before moving to next task |
| "Permission denied" on hook | Hook file not executable | `chmod +x .claude/hooks/*.sh` |
