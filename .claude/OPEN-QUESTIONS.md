# Open Questions — Ask These Before Every Major Decision

## Core Principle
**There are no edge cases, only certainties.** If something can happen,
it will happen. Every code path is a main path. Every failure mode is
a normal operating condition.

## Lifecycle Questions
- What happens if this session dies mid-implementation?
- Who or what restarts this work if the session is killed?
- Is the conductor running? Will it pick this up if we crash?
- If the Stop hook doesn't fire (hard kill), what state is lost?

## Observability Questions
- Can the human see what's happening without typing any commands?
- Will the dashboard/conductor.html reflect this change?
- If this runs at 3am, how does the human know what happened?
- Are we logging enough for the /retro to analyze failures?

## Autonomy Questions
- Does this require human input to proceed?
- Are there permission prompts that will block autonomous execution?
- Is the budget sufficient for this task's likely token usage?

## Architecture Questions
- Are we assuming something exists that might not?
- Does this work with zero tests? Zero commits? Empty project?
- Does this introduce a new external dependency?
- Could a simpler solution work?

## Human Questions
- What if the human doesn't review EVOLUTION.md for a week?
- Does the TODO.md accurately reflect what's actually needed?
- Is the CLAUDE.md under 25 rules?

## Integration Questions
- Does this change break any existing hooks?
- Will this change survive a /compact and session restart?
- Is this change committed to git (survives everything) or only in files?
