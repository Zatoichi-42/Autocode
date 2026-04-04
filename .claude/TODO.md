# TODO — Project Task Tracker

## How This File Works
- Claude reads this at session start (via session-start hook)
- Mark tasks `[x]` when complete
- Add new tasks as `[ ]`
- Tasks are ordered by priority (top = highest)
- Each task should be small enough for ONE session

## Phase 1: Bootstrap (Do First)
- [ ] Run `/bootstrap` to verify all files and directories exist
- [ ] Customize `CLAUDE.md` with actual project stack and commands
- [ ] Customize `program.md` with project-specific improvement directions
- [ ] Verify all hooks are executable and working
- [ ] Run `/health` to establish baseline
- [ ] Create initial test suite (even if minimal)
- [ ] First clean commit on feature branch

## Phase 2: Core Implementation
- [ ] Define core data models/types
- [ ] Implement core business logic (use `/implement` for TDD)
- [ ] Add API layer / routes
- [ ] Add UI components
- [ ] Integration between layers

## Phase 3: Quality & Polish
- [ ] Run `/ratchet` for autonomous improvements
- [ ] Run `/review` on all code
- [ ] Accessibility audit
- [ ] Error handling audit
- [ ] Performance audit

## Phase 4: Ship
- [ ] Final full test suite run
- [ ] Build succeeds with no warnings
- [ ] Lint passes with no errors
- [ ] Documentation up to date
- [ ] README reflects current state

## Completed
