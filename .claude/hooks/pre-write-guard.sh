#!/usr/bin/env bash
# ============================================================================
# Prevent edits to locked/protected files AND test files during impl
# ============================================================================

trap 'echo "BLOCKED: Write guard hook crashed — failing closed" >&2; exit 2' ERR

if ! command -v jq &>/dev/null; then
  echo "BLOCKED: jq not installed — write guard cannot function" >&2
  exit 2
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Protect lock files and generated code
if echo "$FILE_PATH" | grep -qE 'package-lock\.json|yarn\.lock|pnpm-lock\.yaml|\.gen\.(ts|js)|\.generated\.'; then
  echo '{"hookSpecificOutput":{"decision":"block","reason":"BLOCKED: This is a protected/generated file. Do not edit directly."}}'
  exit 0
fi

# Protect test files during implementation (unless in RED phase)
if [ "${CLAUDE_TDD_PHASE:-}" != "red" ]; then
  if echo "$FILE_PATH" | grep -qE '\.test\.|\.spec\.|__tests__/|/test/|/tests/'; then
    echo '{"hookSpecificOutput":{"decision":"block","reason":"BLOCKED: Cannot modify test files during implementation. Tests are the specification. Fix the source code instead, or set CLAUDE_TDD_PHASE=red to write new tests."}}'
    exit 0
  fi
fi

exit 0
