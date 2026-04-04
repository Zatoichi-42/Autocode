# ============================================================================
# FILE: .claude/commands/health.md
# PURPOSE: Quick project health check
# ============================================================================

# /health — Project Health Check

Run a comprehensive health check on the project.

## Checks
1. **Git status**: clean? uncommitted changes? current branch?
2. **Tests**: all passing? how many? execution time?
3. **Build**: succeeds? warnings?
4. **Lint**: errors? warnings?
5. **TypeCheck**: passes?
6. **Dependencies**: outdated? vulnerabilities? (`npm audit`)
7. **Ratchet state**: current baseline metrics
8. **TODO status**: remaining vs completed tasks
9. **Context**: current usage percentage

## Output
Produce a concise dashboard-style report. Flag anything that needs attention.
