---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
  - "**/test/**"
  - "**/tests/**"
---

# Testing Rules (loaded only when working with test files)

## Test Structure
- One test file per source file, mirroring the src/ directory structure
- Test file naming: `<source-file>.test.<ext>` or `<source-file>.spec.<ext>`
- Group related tests with `describe()` blocks
- Use descriptive test names: `it("should return 404 when user not found")`

## Test Principles
- Tests are SPECIFICATIONS, not implementation details
- Test behavior, not implementation
- One assertion per test (prefer focused tests)
- Each test should be independent — no shared mutable state between tests
- Tests should be fast — mock slow dependencies (network, disk, DB)

## Bug Fix Protocol
- If the user gives an exact error string, reproduce that EXACT string in a test
- Reproduce the exact user command before claiming a fix when feasible
- For CLI/output bugs, add at least one integration test for the real entrypoint
- For stdout/stderr requirements, verify: startup output, progress output, final output, and flushing
- Do not claim "fixed" until the reproduction test goes from RED to GREEN

## Task Discipline
- Do NOT let unrelated failing tests redefine the current task
- If a pre-existing test is failing and it's unrelated to your work, note it but stay focused
- Track unrelated failures in a comment or TODO, don't chase them

## What to Test
- Happy path: does it work with valid input?
- Edge cases: empty, null, undefined, boundary values
- Error cases: invalid input, network failures, timeouts
- State transitions: does state change correctly?

## What NOT to Test
- Third-party library internals
- Private methods directly (test through public API)
- Implementation details that could change without changing behavior
- Framework boilerplate (routes, config, etc.)

## Mocking Rules
- NEVER mock the unit under test
- Mock external dependencies (APIs, databases, file system)
- Prefer dependency injection over module mocking
- Reset all mocks between tests

## When Writing New Tests
- Run the test BEFORE writing implementation — confirm it fails (RED)
- A passing test on first run means it's testing the wrong thing
- After implementation, run the test again — confirm it passes (GREEN)

## When Tests Fail
- Read the error message carefully — it usually points to the issue
- Fix the IMPLEMENTATION, not the test (tests are the spec)
- If the test genuinely has a bug, ask the user before modifying
- Never delete a failing test to make the suite pass
