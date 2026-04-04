---
name: self-plan
description: >
  Autonomous planning mode. Claude interviews itself, self-critiques,
  and produces a verified plan before implementation begins.
  Trigger: "/plan", "think about", "plan this", "design a solution for".
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Agent
effort: high
---

# Self-Planning — Think Before You Build

## The Self-Interview Protocol

### Round 1: UNDERSTAND
1. What is the user actually asking for?
2. What does "done" look like?
3. What are the inputs and outputs?
4. What existing code does this touch?

### Round 2: CHALLENGE
Read `.claude/OPEN-QUESTIONS.md`. Ask each question about the current plan.
Delegate to `self-critic` subagent (opus) for adversarial thinking.

### Round 3: SIMPLIFY
1. What's the SMALLEST change that satisfies criteria?
2. Can we do this WITHOUT new dependencies or abstractions?
3. How many files need to change? (If >5, break it down)

### Round 4: SEQUENCE
Write implementation order: which tests first, which files first.

### Round 5: VERIFY PLAN
Check: criteria testable? Edge cases addressed? Simplest path? No premature abstractions?

## Output: .claude/PLAN.md
