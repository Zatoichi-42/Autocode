# /walkthrough — Generate Interactive Project Tour

Generate a self-contained HTML walkthrough guide that teaches the human
how the project works. This is a DIFF TUTORIAL — it shows what changed,
why, and how to understand the current state.

Write to: `.claude/reports/walkthrough.html`

## What This Is
A guided tour of the project, designed for:
- The human coming back after days away
- A new team member onboarding
- The human wanting to understand what autonomous sessions built
- Reviewing what the ratchet loop changed overnight

## Sections to Generate

### 1. Project Overview (30-second orientation)
- What is this project? (read from README.md or CLAUDE.md)
- What stack? (from CLAUDE.md)
- Current status: what works, what's in progress, what's planned
- Architecture diagram (embed as SVG inline — read from ARCHITECTURE.md or generate)

### 2. File Explorer (interactive tree)
- Show the project directory structure as a collapsible tree
- Color-code by status:
  - GREEN: files with passing tests
  - YELLOW: files modified recently (last 3 days) without test updates
  - RED: files related to failing tests
  - GRAY: unchanged/stable files
- Click a file to see its purpose (one-line description)

### 3. Recent Changes Tour (the "diff tutorial")
For the last 7 days of commits (or since last walkthrough):
- Show each commit as a "slide" with:
  - Commit message and date
  - Files changed (with diff stats: +lines / -lines)
  - WHY this change was made (infer from commit message and context)
  - Key code snippets showing the important parts (not full diffs)
  - Test coverage: was this change tested? Which tests?

Group related commits into logical sections:
- "Authentication System" (3 commits)
- "Performance Improvements" (2 commits from ratchet)
- "Bug Fixes" (1 commit)

### 4. How It Works (architecture walkthrough)
For each major module/directory:
- Purpose (one paragraph)
- Key files and what they do
- Data flow: how does information move through this module?
- Dependencies: what does this module depend on?
- Tests: where are the tests and what do they cover?

### 5. Current Test Coverage
- Which modules have good coverage?
- Which modules are undertested?
- What are the most important test files to read?

### 6. Ratchet History (if applicable)
- What experiments were tried?
- What improvements were kept?
- What directions were exhausted?
- Visual: staircase chart of score over time

### 7. Known Issues & Technical Debt
- Read from DEBUGGING.md, TODO.md, EVOLUTION.md
- Prioritized list of what needs attention
- For each issue: suggested approach

### 8. How To Continue
- Next 3 tasks from TODO.md
- Recommended starting point for each
- Which tests to read first to understand the requirements

## Technical Implementation
- Single HTML file, no external dependencies except CDN for syntax highlighting
- Use Prism.js from CDN for code highlighting:
  ```html
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js"></script>
  ```
- Navigation: sticky sidebar with section links
- "Slide" navigation for the diff tutorial (Previous/Next buttons)
- Responsive design
- Print-friendly (the human might want a PDF)

## Generation Process
1. Read all source files, git history, test results, docs
2. Build the data model
3. Generate the HTML with embedded data
4. Write to `.claude/reports/walkthrough.html`
5. Print summary to stdout: "Walkthrough generated: N sections, covering M files and K commits"

## Regeneration
- Run `/walkthrough` to regenerate (overwrites previous)
- Include generation timestamp in the file
- Include a "Changes since last walkthrough" section at the top if a previous version exists
