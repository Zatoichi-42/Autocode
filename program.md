# Program: Research & Improvement Directions

## Purpose
This file tells the Ratchet Loop what to explore. The agent reads this,
picks a direction, runs an experiment, and measures the result.
Update this file to steer the agent's overnight/autonomous work.

## How To Use
1. Write directions as numbered items
2. Each direction should be ONE clear hypothesis
3. Include how to measure success
4. The agent explores top-to-bottom, skipping exhausted directions
5. Mark completed directions with ✅, failed with ❌, skipped with ⏭️

## Current Directions

### Performance
1. [ ] Reduce bundle size by identifying and removing unused imports
   - Measure: `npm run build` output size in KB
   - Better = smaller

2. [ ] Optimize component re-renders by memoizing expensive computations
   - Measure: Lighthouse performance score (if applicable) or render count in tests
   - Better = fewer renders, faster test execution

3. [ ] Lazy-load routes/components not needed on initial page load
   - Measure: Initial bundle chunk size
   - Better = smaller initial chunk

### Code Quality
4. [ ] Extract duplicated logic into shared utility functions
   - Measure: `npx jscpd --min-lines 3 src/` (copy-paste detection)
   - Better = fewer duplicates

5. [ ] Add missing TypeScript types — eliminate any remaining `any` types
   - Measure: `grep -r ": any" src/ | wc -l`
   - Better = count closer to 0

6. [ ] Improve error handling — find try/catch blocks that swallow errors
   - Measure: `grep -rn "catch.*{}" src/ | wc -l` + manual review
   - Better = fewer silent catches

### Test Coverage
7. [ ] Add tests for uncovered utility functions
   - Measure: Test pass count before/after
   - Better = more tests passing

8. [ ] Add edge case tests for critical business logic
   - Measure: Test count + mutation testing if available
   - Better = more tests, higher mutation score

### UX/Accessibility
9. [ ] Add ARIA labels to interactive elements missing them
   - Measure: axe-core audit result count
   - Better = fewer violations

10. [ ] Ensure all form inputs have associated labels
    - Measure: accessibility test pass count
    - Better = all passing

## Exhausted Directions (don't retry)

## Completed Improvements
