# ============================================================================
# FILE: .claude/commands/review.md
# PURPOSE: Code review current changes
# ============================================================================

# /review — Review Current Changes

Delegate a thorough code review to the `code-reviewer` subagent.

## Usage
```
/review              # Review staged changes
/review --branch     # Review all changes on current branch vs main
/review [file]       # Review a specific file
```

## Process
1. Determine scope (staged, branch diff, or specific file)
2. Delegate to `code-reviewer` subagent
3. Present findings organized by severity
4. If critical issues found: suggest specific fixes
5. If APPROVE: suggest commit message
