#!/usr/bin/env bash
# ============================================================================
# Block dangerous commands before execution
# EXIT CODES: 0 = allow (with optional JSON decision), 2 = block
# CRITICAL: exit 1 is NON-BLOCKING in Claude Code! Only exit 2 blocks.
# ============================================================================

# Fail closed: any unexpected error blocks the action
trap 'echo "BLOCKED: Hook crashed unexpectedly — failing closed for safety" >&2; exit 2' ERR

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "BLOCKED: jq not installed — security hook cannot parse input. Install jq." >&2
  exit 2
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# No command = not a Bash call, allow
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block credential/secret commits
if echo "$COMMAND" | grep -qiE 'git (add|commit)'; then
  if git diff --cached --name-only 2>/dev/null | grep -qE '\.(env|key|pem|p12)$|secrets|credentials'; then
    echo '{"hookSpecificOutput":{"decision":"block","reason":"BLOCKED: Staging/committing sensitive files (.env, .key, .pem, credentials)"}}'
    exit 0
  fi
fi

# Block destructive operations
if echo "$COMMAND" | grep -qE 'rm -rf [^.]|drop (database|table)|truncate|:(){ :|:& };:'; then
  echo '{"hookSpecificOutput":{"decision":"block","reason":"BLOCKED: Destructive command detected"}}'
  exit 0
fi

# Block force-push to main
if echo "$COMMAND" | grep -qE 'git push.*(-f|--force).*(main|master)'; then
  echo '{"hookSpecificOutput":{"decision":"block","reason":"BLOCKED: Force push to main/master"}}'
  exit 0
fi

# Block writing secrets via Bash
if echo "$COMMAND" | grep -qiE '(echo|printf|cat).*>.*\.(env|key|pem)'; then
  echo '{"hookSpecificOutput":{"decision":"block","reason":"BLOCKED: Writing to sensitive file via Bash."}}'
  exit 0
fi

exit 0
