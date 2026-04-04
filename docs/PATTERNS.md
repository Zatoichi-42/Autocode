# Patterns & Anti-Patterns

## Workflow Patterns

### The Error String Anchor Pattern
When a user reports a bug with an exact error message:
1. Write a test that reproduces the EXACT error string
2. Confirm it fails (RED) — if it doesn't fail, your test is wrong
3. Fix the code until the test passes (GREEN)
4. This test now permanently guards against regression

### The Real Entrypoint Pattern
For CLI bugs, don't just test the internal function:
```
# BAD: tests the function but not the CLI
test("parseArgs handles --verbose") 

# GOOD: tests what the user actually runs
test("cli outputs progress when given --verbose flag") {
  const result = execSync("node cli.js --verbose input.txt")
  expect(result.stdout).toContain("Processing...")
}
```
Integration tests on the real binary catch wiring bugs that unit tests miss.

### The Output Verification Pattern
For CLI/output work, verify ALL layers:
1. Startup output (banner, version, config loaded)
2. Progress output (processing X of Y, percentage)
3. Final output (results, summary, exit code)
4. Flushing (output actually reaches stdout before process exits)

### The Anti-Derailment Pattern
When unrelated tests fail during your work:
1. Note them: "Pre-existing failure: test_xyz in file_abc"
2. Do NOT chase them — they are a separate task
3. Continue your current task
4. Mention them in your summary so they can be tracked

### The Fresh Context Pattern (Ralph Loop)
For long-running work, use session boundaries deliberately:
1. Plan in Session 1 → write plan to `.claude/PLAN.md`
2. Implement Phase 1 in Session 2 → commit, write progress to `TODO.md`
3. Implement Phase 2 in Session 3 → repeat
4. Review in Session 4 using `code-reviewer` subagent

Each session starts clean with full context budget.
Handoff state lives in committed files, not in the context window.

### The Builder-Validator Pattern
Never let the same agent both build and validate:
- Builder subagent: creates code (has Write/Edit permissions)
- Validator subagent: reviews and tests (has Read/Bash permissions only)
- Main agent: orchestrates and decides

### The A/B Worktree Pattern
For uncertain design decisions:
```bash
claude --worktree approach-a    # Build approach A
claude --worktree approach-b    # Build approach B simultaneously
# Compare results, keep the winner, delete the loser
```

### The Ratchet Pattern (Continuous Improvement)
From Karpathy's AutoResearch:
1. Measure baseline
2. Make ONE change
3. Measure again
4. Keep if better, revert if not
5. Repeat

Golden rule: **the ratchet only turns one way** — quality only goes up.

### The Specification-First Pattern
1. Write a spec in natural language → `specs/feature-name.md`
2. Convert spec to tests (use `tdd-test-writer` subagent)
3. Implement to pass tests (use `tdd-implementer` subagent)
4. Spec, tests, and code are always in sync

## Anti-Patterns to Avoid

### The "Edge Case" Delusion
**Don't**: Label failure modes as "edge cases" to justify not handling them.
**Do**: Treat every failure mode as a certainty. If it can happen, it will.
**Why**: "Edge case" is permission to ignore. Every path is a main path.
  Session death, rate limits, build failures, corrupt state, missing tools,
  human absence — these are not edge cases. They are normal operations.

### The Kitchen Sink CLAUDE.md
**Don't**: Put 500 lines of instructions, every possible convention, and full API docs in CLAUDE.md.
**Do**: Keep under 100 lines. Link to skills and docs with `@imports`.
**Why**: Claude starts ignoring instructions after ~150-200 rules. Dilution kills compliance.

### The Yolo Commit
**Don't**: Let Claude commit without running tests.
**Do**: Stop hook verifies test status. Commit only after green.
**Why**: One bad commit poisons the ratchet baseline.

### The Mega-Session
**Don't**: Work for hours in one session until context is exhausted.
**Do**: Commit frequently. Start new sessions for new tasks. Use `/compact` early.
**Why**: Quality degrades after 50% context usage. Fresh sessions are cheap.

### The Silent Failure
**Don't**: `catch(e) {}` — empty catch blocks.
**Do**: Log errors, return Result types, or rethrow with context.
**Why**: Silent failures hide bugs that compound over time.

### The Multi-Change Experiment
**Don't**: Change 5 things and measure once.
**Do**: Change 1 thing, measure, decide, repeat.
**Why**: You can't attribute improvement/regression to a specific change.

### The Test-After-the-Fact
**Don't**: Write all code first, then try to add tests.
**Do**: TDD — write tests first, implement to pass them.
**Why**: Tests written after implementation test what the code *does*, not what it *should do*.

### The Premature Abstraction
**Don't**: Create abstractions, factories, and patterns before you have 3+ concrete uses.
**Do**: Write concrete code first. Refactor to abstractions when duplication appears.
**Why**: Wrong abstractions are worse than duplication. Wait for the pattern to emerge.

## Prompting Patterns for Claude Code

### The Interview Pattern
Start vague → let Claude ask questions:
```
"I need a user authentication system. Interview me about requirements
before proposing a solution."
```

### The Challenge Pattern
After Claude produces something:
```
"Prove to me this works. Grill these changes — find every edge case,
every way this could fail."
```

### The Elegant Redo Pattern
After a mediocre solution:
```
"Knowing everything you know now, scrap this and implement the
elegant solution."
```

### The Scope Lock Pattern
Prevent Claude from expanding scope:
```
"Implement ONLY the login form. Do not add logout, password reset,
or account settings. Stop after the form submits successfully."
```
