# ============================================================================
# FILE: .claude/commands/implement.md
# PURPOSE: TDD feature implementation
# ============================================================================

# /implement — Build a Feature with TDD

Implement a feature using strict Test-Driven Development.

## Usage
```
/implement [feature description]
```

## Process
1. Load the `tdd-loop` skill
2. Plan testable behaviors from the feature description
3. Delegate RED phase to `tdd-test-writer` subagent
4. Confirm tests fail
5. Delegate GREEN phase to `tdd-implementer` subagent
6. Confirm tests pass
7. Refactor in main context
8. Run full verification (tests + types + lint)
9. Commit with conventional commit message

## If the user's description is vague
Ask clarifying questions using the AskUserQuestion tool. Get:
- What is the input? What is the output?
- What should happen on error?
- Are there performance requirements?
