---
paths:
  - "**/*.sh"
  - "**/*.env*"
  - "**/hooks/**"
  - "**/settings.json"
  - "**/Dockerfile"
  - "**/docker-compose*"
---

# Safety Rules for Sensitive Files

These rules apply when working with shell scripts, environment files,
Docker configs, hooks, or settings. They load automatically when you
access files matching the paths above.

## Absolute Rules (Enforced by Hooks + This File)

1. NEVER hardcode secrets, API keys, passwords, or tokens in any file
2. NEVER commit .env files to git (verify .gitignore includes them)
3. NEVER use `eval` on user input in shell scripts
4. NEVER use `curl | bash` or `wget | bash` patterns
5. NEVER chmod 777 anything
6. NEVER disable SSL verification
7. NEVER store credentials in plain text

## Shell Script Standards

- Always start with `#!/usr/bin/env bash`
- Always use `set -euo pipefail` for scripts (NOT for hooks — hooks need custom exit handling)
- Quote all variables: `"$VAR"` not `$VAR`
- Use `[[ ]]` not `[ ]` for conditionals
- Check for required commands before using them
- Handle errors explicitly

## Docker Standards

- Never run as root in containers
- Pin base image versions (no `:latest`)
- Use multi-stage builds to minimize image size
- Don't copy .env files into images
- Scan for vulnerabilities before deploying

## When Modifying Hooks

- Test hooks in isolation first: `echo '{"tool_input":{}}' | bash .claude/hooks/your-hook.sh`
- Hooks must exit 0 for allow, non-zero for block
- JSON output from hooks controls Claude's behavior:
  - `{"decision":"block","reason":"..."}` — prevents the action
  - `{"decision":"allow"}` — explicitly allows
  - No output / exit 0 — implicitly allows
- Keep hooks FAST (< 2 seconds) — they run on every matching tool use
