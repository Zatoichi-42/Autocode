---
name: tdd-loop
description: >
  Enforce strict Red-Green-Refactor TDD cycle using subagents to prevent
  context pollution. Use when implementing new features, adding functionality,
  or when user says "implement", "build", "add feature", "TDD", or "/tdd".
  Does NOT trigger for bug fixes, docs, or config changes.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Agent
---

# TDD Loop — Red/Green/Refactor with Subagent Isolation

## Why Subagents
When test-writing and implementing happen in the same context window, the
implementation "bleeds" into test logic. The LLM writes tests that pass by
accident because it already knows the implementation. Subagents have separate
context windows, preventing this pollution.

## Workflow

### Phase 1: PLAN (Main Agent — You)
1. Understand the feature requirement from the user
2. **Name the tests first** — write a plain-language list of what each test will prove, before writing ANY code (even test code)
3. For each behavior, define: input, expected output, edge cases
4. If the user gave an exact error string, one test MUST reproduce that exact string
5. For CLI/output work, plan tests for: startup output, progress output, final output, and flushing

### Phase 2: RED — Write Failing Tests
Delegate to `tdd-test-writer` subagent:

```
Agent(
  agent_type="tdd-test-writer",
  prompt="Write failing tests for: [feature description]. Behaviors to test: [list]. Test file: [path]. DO NOT write any implementation code.",
  model="sonnet"
)
```

After subagent returns:
1. Run the tests: confirm they FAIL (red)
2. If tests pass → tests are wrong (testing existing behavior, not new)
3. If tests error on import → that's expected if module doesn't exist yet
4. Commit the tests: `git add && git commit -m "test: red — [feature] tests"`

### Phase 3: GREEN — Minimal Implementation
Delegate to `tdd-implementer` subagent:

```
Agent(
  agent_type="tdd-implementer",
  prompt="Make these tests pass with MINIMAL code: [test file path]. Read the test file first. Write only what the tests require. Do not modify test files. Run tests to verify.",
  model="sonnet"
)
```

After subagent returns:
1. Run the tests: confirm they PASS (green)
2. If still failing → iterate (give the subagent the error output)
3. Commit: `git add && git commit -m "feat: green — [feature] implementation"`

### Phase 4: REFACTOR — Clean Up
Review the implementation yourself (main agent context):
1. Check for duplication, complexity, naming
2. Refactor incrementally — run tests after EACH change
3. If tests break during refactor → revert that specific change
4. Commit: `git add && git commit -m "refactor: [what was improved]"`

### Phase 5: VERIFY — Integration Check
1. Run the FULL test suite (not just the new tests)
2. Run typecheck
3. Run linter
4. If anything fails that wasn't failing before → fix or revert

### Phase 6: ITERATE
Return to Phase 1 for the next feature/behavior.

## Rules
- Tests are the SPECIFICATION. Never modify tests to make them pass.
- If a test seems wrong, ASK the user. Do not silently change it.
- Do not edit non-test source without a recent RED signal.
- Do not let unrelated failing tests redefine the task — note them and continue.
- If the user gave an exact error string, reproduce that exact string in a test.
- Reproduce the exact user command before claiming a fix.
- For CLI/output bugs, add at least one integration test for the real entrypoint.
- For stdout/stderr requirements, verify startup output, progress output, final output, and flushing.
- No silent failures — adapters must return data or typed errors.
- One behavior per test function. Tests should be readable as documentation.
- Prefer real assertions over snapshot tests for logic.
- Mock external dependencies (APIs, databases) but NEVER mock the unit under test.
