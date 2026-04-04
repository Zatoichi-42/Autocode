## Slash Commands
| Command | What It Does | Effort |
|---------|-------------|--------|
| `/bootstrap` | Initialize/verify all bootstrap files, hooks, directories | standard |
| `/plan [feature]` | Self-interview + critic before building (think first) | **high** |
| `/implement [feature]` | Build feature with strict TDD (Red → Green → Refactor) | standard |
| `/ratchet` | Start autonomous improvement loop (Karpathy-style) | standard |
| `/review` | Code review current changes via subagent | standard |
| `/health` | Project health dashboard (tests, build, lint, coverage) | low |
| `/check` | **30-second spot check** — stdout only, anytime, fast | **low** |
| `/retro` | Session retrospective — analyze failures, propose rules | high |
| `/digest` | Generate plain-text daily quality report | low |
| `/dashboard` | Generate interactive HTML visual dashboard | standard |
| `/walkthrough` | Generate project tour with diff tutorial | standard |
| `/scout` | Scan Claude Code releases, propose feature A/B tests | low |
| `/compact [focus]` | Compact context, preserving specified focus areas | — |
