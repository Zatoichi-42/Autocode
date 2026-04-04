#!/usr/bin/env bash
# ============================================================================
# Preserve state before compaction
# ============================================================================

INPUT=$(cat 2>/dev/null || echo '{}')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p .claude/logs

cat > .claude/HANDOFF.md << HANDOFF
# Handoff — ${TIMESTAMP} (pre-compact)
Branch: $(git branch --show-current 2>/dev/null || echo "?")
Modified: $(git diff --name-only 2>/dev/null | head -20)
Last commits: $(git log --oneline -3 2>/dev/null || echo "none")
Resume: read this, check git diff, run tests, continue.
HANDOFF

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  cp "$TRANSCRIPT" ".claude/logs/transcript-${TIMESTAMP}.jsonl" 2>/dev/null || true
fi

echo "Handoff saved."
exit 0
