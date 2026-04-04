---
paths:
  - "src/ui/**"
  - "src/components/**"
  - "src/pages/**"
  - "src/views/**"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---

# UI Component Rules (loaded only when working with UI files)

## Component Structure
- One component per file
- File name matches component name (PascalCase)
- Keep components under 200 lines — extract sub-components when growing
- Props interface/type defined at top of file
- No business logic in components — delegate to hooks/services

## Accessibility (WCAG AA Minimum)
- ALL interactive elements must be keyboard accessible
- ALL images must have meaningful alt text (or alt="" for decorative)
- ALL form inputs must have associated `<label>` elements
- Color contrast: minimum 4.5:1 for normal text, 3:1 for large text
- Focus indicators must be visible
- Use semantic HTML: `<button>` not `<div onClick>`, `<nav>` not `<div class="nav">`
- ARIA attributes only when semantic HTML is insufficient

## Responsive Design
- Mobile-first: design for small screens, then enhance for larger
- Use relative units (rem, em, %) over fixed pixels for sizing
- Test at minimum: 320px (mobile), 768px (tablet), 1024px (desktop)
- No horizontal scrolling at any breakpoint

## Performance
- Memoize expensive renders (useMemo, React.memo, computed)
- Lazy-load components not visible on initial render
- Optimize images: use modern formats (WebP, AVIF), provide srcset
- Avoid layout thrashing: batch DOM reads and writes

## State Management
- Local state for UI-only concerns (open/closed, hover, focus)
- Global state for shared data (user session, theme, app data)
- URL state for anything that should be shareable/bookmarkable
- Server state via data fetching library (React Query, SWR, etc.)

## After Creating/Modifying a Component
1. Write or update component tests
2. Check accessibility with axe-core or similar
3. Verify responsive behavior at 3 breakpoints
4. Run the UI tester subagent if available
