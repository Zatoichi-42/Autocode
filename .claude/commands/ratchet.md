# ============================================================================
# FILE: .claude/commands/ratchet.md
# PURPOSE: Start the autonomous improvement loop
# ============================================================================

# /ratchet — Start Autonomous Improvement Loop

Run the Karpathy-inspired ratchet loop to autonomously improve the codebase.

## Usage
```
/ratchet                    # Run with default program.md directions
/ratchet [specific area]    # Focus on a specific improvement area
```

## Process
1. Load the `ratchet-loop` skill
2. Read `program.md` for directions
3. Establish or load baseline from `.claude/ratchet-state.json`
4. Begin the Six-Step Loop (see skill for details)
5. Continue until a stopping condition is met
6. Report results

## Safety
- Maximum 20 experiments per invocation
- Reverts ALL changes that don't improve metrics
- Never modifies test files
- Commits each improvement individually for easy rollback
