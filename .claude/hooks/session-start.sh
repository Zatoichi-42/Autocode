#!/usr/bin/env bash
# ============================================================================
# Load context on session start, verify hooks are healthy
# ============================================================================

echo "=== Session Start ==="
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'not in git')"
echo "Modified: $(git diff --name-only 2>/dev/null | wc -l | tr -d ' ') files"

# Verify sibling hooks are executable
for hook in .claude/hooks/*.sh; do
  if [ -f "$hook" ] && [ ! -x "$hook" ]; then
    chmod +x "$hook" 2>/dev/null && echo "Fixed permissions: $hook"
  fi
done

# Check jq
if ! command -v jq &>/dev/null; then
  echo "WARNING: jq is not installed. Security hooks will FAIL CLOSED (block everything)."
  echo "Install jq: brew install jq / apt install jq"
fi

# Check disk space
DISK_FREE=$(df -m . 2>/dev/null | awk 'NR==2{print $4}' || echo "unknown")
if [ "$DISK_FREE" != "unknown" ] && [ "$DISK_FREE" -lt 500 ]; then
  echo "WARNING: Only ${DISK_FREE}MB disk space remaining. Prune .claude/logs/"
fi

# Prune old logs
find .claude/logs/ -name "*.log" -mtime +7 -delete 2>/dev/null || true
find .claude/logs/ -name "*.jsonl" -mtime +7 -delete 2>/dev/null || true

# Load journal
if [ -f ".claude/JOURNAL.md" ]; then
  echo ""
  echo "=== Previous Journal ==="
  cat .claude/JOURNAL.md
  echo "=== End Journal ==="
fi

# Ratchet state
if [ -f ".claude/ratchet-state.json" ] && command -v jq &>/dev/null; then
  echo "Ratchet: $(jq -r '"exp=" + (.experiment_count|tostring) + " kept=" + (.kept_improvements|length|tostring)' .claude/ratchet-state.json 2>/dev/null || echo 'unreadable')"
fi

# TODO status
if [ -f ".claude/TODO.md" ]; then
  REMAINING=$(grep -c '^\- \[ \]' .claude/TODO.md 2>/dev/null || echo 0)
  echo "Tasks remaining: $REMAINING"
fi

echo "====================="
exit 0
