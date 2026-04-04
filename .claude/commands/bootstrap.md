# /bootstrap — Initialize Project Environment

Check and create all required bootstrap files and directories. Idempotent.

## Steps
1. Verify directory structure exists (create missing dirs)
2. Verify critical files exist (CLAUDE.md, settings.json, hooks)
3. Make all hooks executable: `chmod +x .claude/hooks/*.sh`
4. Verify git initialized (create feature branch if on main)
5. Run health check (tests, build, lint)
6. Initialize ratchet state baseline
7. Report status
