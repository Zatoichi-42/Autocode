## Quick Start

```bash
# Start Claude Code
claude
/bootstrap       # Verify environment
/health          # Establish baseline
/implement [feature]  # Build with TDD
/ratchet         # Autonomous improvements
```

## Autonomous Mode

```bash
# Run overnight (external to Claude Code)
bash scripts/conductor.sh --auto --budget 5

# Monitor from browser
bash scripts/conductor.sh --serve
# → http://localhost:7777
```

## Key Files
- `CLAUDE.md` — Project constitution (edit your stack here)
- `program.md` — Ratchet loop experiment directions
- `.claude/TODO.md` — Task tracker
- `docs/QUICKREF.md` — Full command reference
