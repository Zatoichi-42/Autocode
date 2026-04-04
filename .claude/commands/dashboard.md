# /dashboard — Generate Interactive Visual Dashboard

Generate a SINGLE self-contained HTML file at `.claude/reports/dashboard.html`
that the human can open in any browser. No server needed. No npm install.
No build step. Just double-click the file.

## Requirements
- ONE file. All CSS and JS inline. No external dependencies except CDN chart libs.
- Works offline after first load (CDN libs cached by browser)
- Auto-reads data from sibling JSON/MD files via embedded data (baked in at generation time)
- Mobile-friendly (the human might check from their phone)
- Dark mode default with light mode toggle

## Data Sources (read these at generation time, embed as JS constants)
1. `.claude/ratchet-state.json` → experiment history, scores, improvements
2. `.claude/EVOLUTION.md` → rule proposals, session scores, instruction budget
3. `.claude/TODO.md` → task completion progress
4. `.claude/scout-state.json` → feature scan results (if exists)
5. `.claude/reports/digest-*.md` → historical daily digests (parse for trend data)
6. `git log --oneline --since="7 days ago"` → commit history
7. Current test results, lint results, build status

## Dashboard Sections

### Header
- Project name, current branch, last commit date
- Health traffic light: GREEN / YELLOW / RED (large, visible from across the room)
- Current Claude Code version

### Tests Panel
- Pass/fail donut chart
- Test count trend line (7 days)
- List of currently failing tests (if any, in red)

### Ratchet Progress Panel
- Staircase chart showing score over time (like Karpathy's AutoResearch charts)
- Experiments: total, kept, reverted (bar chart)
- Best improvement description
- Current program.md direction being explored

### Task Progress Panel
- Progress bar: completed / total tasks
- Kanban-style columns: TODO, IN PROGRESS, DONE (just CSS, no framework)
- Estimated completion (linear projection from trend)

### Instruction Evolution Panel
- CLAUDE.md rule count vs budget (gauge chart, like a speedometer, red zone >20)
- Proposed rules awaiting review (list with approve/reject indicators)
- Session quality trend line (7 days)
- Rules promoted / rejected / retired counts

### Git Activity Panel
- Commits per day (7-day bar chart)
- Lines added vs removed (stacked area)
- Active branches

### Warnings Panel
- Any critical warnings from latest digest
- Stale TODO items (>3 days old)
- Ratchet stalls (>5 consecutive failures)
- Context near limits

### Scout Panel (if scout-state.json exists)
- Last scan date and version
- Pending feature proposals
- Active A/B tests
- Completed experiments with results

## Technical Implementation
Use Chart.js from CDN for charts:
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.js"></script>
```

Embed all data as JS objects at the top of the file:
```javascript
const RATCHET_DATA = /* baked in from ratchet-state.json */;
const DIGEST_HISTORY = /* parsed from digest-*.md files */;
const TODO_DATA = /* parsed from TODO.md */;
// etc.
```

Use CSS Grid for layout. Make it responsive:
- Desktop: 3-column grid
- Tablet: 2-column
- Phone: 1-column stack

## Generation Rules
- Timestamp the generation: "Generated: [datetime]"
- Include a "Refresh" note: "Run /dashboard in Claude Code to regenerate"
- Total file size should be under 50KB (it's a report, not an app)
- If data files are missing, show "No data yet" in that panel, don't crash
- ALWAYS generate a working file, even with partial data



###
