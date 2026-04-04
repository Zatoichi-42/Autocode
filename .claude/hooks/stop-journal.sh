#!/usr/bin/env bash
# ============================================================================
# Write JOURNAL.md on every turn (survives crashes, rate limits, session death)
# WARNING: Stop hooks that output text cause Claude to process it,
#          triggering another Stop → infinite loop. Check stop_hook_active.
# ============================================================================

# CRITICAL: Prevent infinite loop
INPUT=$(cat 2>/dev/null || echo '{}')
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
MODIFIED_COUNT=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
LAST_COMMITS=$(git log --oneline -3 2>/dev/null || echo "none")

# Quick test status (timeout 30s)
TEST_STATUS="unknown"
if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
  if timeout 30 npm run test -- --passWithNoTests --silent 2>/dev/null; then
    TEST_STATUS="PASSING"
  else
    TEST_STATUS="FAILING"
  fi
elif [ -f "pyproject.toml" ] || [ -f "pytest.ini" ]; then
  if timeout 30 python -m pytest --tb=no -q 2>/dev/null; then
    TEST_STATUS="PASSING"
  else
    TEST_STATUS="FAILING"
  fi
fi

TODO_NEXT=$(grep -m3 '^\- \[ \]' .claude/TODO.md 2>/dev/null || echo "none")

mkdir -p .claude

cat > .claude/JOURNAL.md << JOURNAL
# Journal — ${TIMESTAMP}
Branch: ${BRANCH} | ${MODIFIED_COUNT} uncommitted files
Commits: ${LAST_COMMITS}
Tests: ${TEST_STATUS}
Next: ${TODO_NEXT}
Resume: read this, check git diff, run tests, continue next task.
JOURNAL

cp .claude/JOURNAL.md .claude/HANDOFF.md 2>/dev/null || true

if [ "$TEST_STATUS" = "FAILING" ]; then
  echo "Tests are FAILING." >&2
fi

exit 0
