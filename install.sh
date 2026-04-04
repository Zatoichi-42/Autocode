#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# CLAUDE CODE BOOTSTRAP INSTALLER
#
# This script installs the complete autonomous development bootstrap into
# your project. It creates all directories, hooks, skills, agents, commands,
# rules, and reference documentation.
#
# Usage:
#   cd /your/project
#   bash /path/to/bootstrap/install.sh
#
# Source repo layout mirrors the installed layout:
#   bootstrap-repo/.claude/hooks/    → your-project/.claude/hooks/
#   bootstrap-repo/.claude/skills/   → your-project/.claude/skills/
#   bootstrap-repo/.claude/agents/   → your-project/.claude/agents/
#   bootstrap-repo/.claude/commands/ → your-project/.claude/commands/
#   bootstrap-repo/.claude/rules/    → your-project/.claude/rules/
#   bootstrap-repo/docs/             → your-project/docs/
#   bootstrap-repo/scripts/          → your-project/scripts/
#   bootstrap-repo/CLAUDE.md.template → your-project/CLAUDE.md  (if not present)
#   bootstrap-repo/program.md.template → your-project/program.md (if not present)
#
# What this does NOT do:
#   - Modify your existing source code
#   - Install npm/pip packages
#   - Initialize git (you should already have a repo)
#   - Make any commits
#   - Touch your existing CLAUDE.md if one exists
#
# Safe to run multiple times (idempotent).
# ============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         CLAUDE CODE BOOTSTRAP INSTALLER v2.1                ║"
echo "║         Autonomous Development Environment                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ---- Colors ----
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'
DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${G}✓${NC} $1"; }
warn() { echo -e "  ${Y}⚠${NC} $1"; }
fail() { echo -e "  ${R}✗${NC} $1"; }
info() { echo -e "  ${B}ℹ${NC} $1"; }
step() { echo -e "\n${BOLD}[$1/$TOTAL_STEPS] $2${NC}"; }

TOTAL_STEPS=10
BOOTSTRAP_SOURCE="${BOOTSTRAP_SOURCE:-$(dirname "${BASH_SOURCE[0]}")}"
# Source .claude/ subdirectory in the bootstrap repo
SRC=".claude"                        # source prefix inside bootstrap repo
BOOTSTRAP_CLAUDE="$BOOTSTRAP_SOURCE/$SRC"
WARNINGS=0
CREATED=0
SKIPPED=0

# ---- Helper: install a single file ----
# Usage: install_file <dest> <source> <description>
install_file() {
  local dest="$1"
  local source="$2"
  local desc="$3"

  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ]; then
    SKIPPED=$((SKIPPED + 1))
    echo -e "    ${DIM}exists${NC}  $dest ${DIM}($desc)${NC}"
  elif [ -f "$source" ]; then
    cp "$source" "$dest"
    CREATED=$((CREATED + 1))
    ok "$dest ${DIM}($desc)${NC}"
  else
    warn "$dest — source not found at $source"
    WARNINGS=$((WARNINGS + 1))
  fi
}

# ============================================================================
step 1 "Creating directory structure"
# ============================================================================

DIRS=(
  ".claude/agents"
  ".claude/commands"
  ".claude/hooks"
  ".claude/skills/ratchet-loop"
  ".claude/skills/tdd-loop"
  ".claude/skills/meta-ratchet"
  ".claude/skills/self-plan"
  ".claude/skills/scout"
  ".claude/skills/assumption-audit"
  ".claude/logs"
  ".claude/rules"
  ".claude/reports"
  ".claude/worktrees"
  "docs"
  "scripts"
)

for dir in "${DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "    ${DIM}exists${NC}  $dir/"
  else
    mkdir -p "$dir"
    ok "$dir/"
    CREATED=$((CREATED + 1))
  fi
done

# ============================================================================
step 2 "Installing hooks (deterministic enforcement layer)"
# ============================================================================
echo -e "  ${DIM}Hooks run on EVERY matching action. They are your safety net.${NC}"
echo -e "  ${DIM}CLAUDE.md is advisory (~80%). Hooks are deterministic (100%).${NC}"
echo ""

install_file ".claude/hooks/pre-tool-security.sh"    "$BOOTSTRAP_CLAUDE/hooks/pre-tool-security.sh"    "blocks secrets, destructive commands"
install_file ".claude/hooks/pre-write-guard.sh"      "$BOOTSTRAP_CLAUDE/hooks/pre-write-guard.sh"      "blocks edits to protected/test files"
install_file ".claude/hooks/post-edit-autoformat.sh" "$BOOTSTRAP_CLAUDE/hooks/post-edit-autoformat.sh" "auto-formats after every edit"
install_file ".claude/hooks/stop-journal.sh"         "$BOOTSTRAP_CLAUDE/hooks/stop-journal.sh"         "writes JOURNAL.md every turn (crash-safe)"
install_file ".claude/hooks/session-start.sh"        "$BOOTSTRAP_CLAUDE/hooks/session-start.sh"        "loads context on session start"
install_file ".claude/hooks/pre-compact-handoff.sh"  "$BOOTSTRAP_CLAUDE/hooks/pre-compact-handoff.sh"  "preserves state before compaction"

# ============================================================================
step 3 "Installing skills (on-demand workflows)"
# ============================================================================
echo -e "  ${DIM}Skills load only when triggered. They don't consume context budget.${NC}"
echo ""

install_file ".claude/skills/ratchet-loop/SKILL.md"    "$BOOTSTRAP_CLAUDE/skills/ratchet-loop/SKILL.md"    "Karpathy-style autonomous improvement"
install_file ".claude/skills/tdd-loop/SKILL.md"        "$BOOTSTRAP_CLAUDE/skills/tdd-loop/SKILL.md"        "TDD with subagent isolation"
install_file ".claude/skills/meta-ratchet/SKILL.md"    "$BOOTSTRAP_CLAUDE/skills/meta-ratchet/SKILL.md"    "learn from failures, propose rules"
install_file ".claude/skills/self-plan/SKILL.md"       "$BOOTSTRAP_CLAUDE/skills/self-plan/SKILL.md"       "self-interview before building"
install_file ".claude/skills/scout/SKILL.md"           "$BOOTSTRAP_CLAUDE/skills/scout/SKILL.md"           "scan releases, A/B test features"
install_file ".claude/skills/assumption-audit/SKILL.md" "$BOOTSTRAP_CLAUDE/skills/assumption-audit/SKILL.md" "find architectural blind spots"

# ============================================================================
step 4 "Installing agents (isolated workers)"
# ============================================================================
echo -e "  ${DIM}Subagents run in separate context windows to prevent pollution.${NC}"
echo ""

install_file ".claude/agents/tdd-test-writer.md" "$BOOTSTRAP_CLAUDE/agents/tdd-test-writer.md" "RED phase — writes failing tests"
install_file ".claude/agents/tdd-implementer.md" "$BOOTSTRAP_CLAUDE/agents/tdd-implementer.md" "GREEN phase — minimal implementation"
install_file ".claude/agents/code-reviewer.md"   "$BOOTSTRAP_CLAUDE/agents/code-reviewer.md"   "code quality & security review"
install_file ".claude/agents/ui-tester.md"       "$BOOTSTRAP_CLAUDE/agents/ui-tester.md"       "UI, accessibility, responsive testing"
install_file ".claude/agents/self-critic.md"     "$BOOTSTRAP_CLAUDE/agents/self-critic.md"     "adversarial plan critique (opus)"

# ============================================================================
step 5 "Installing slash commands"
# ============================================================================
echo -e "  ${DIM}Type these in Claude Code: /bootstrap, /implement, /ratchet, etc.${NC}"
echo ""

install_file ".claude/commands/bootstrap.md"   "$BOOTSTRAP_CLAUDE/commands/bootstrap.md"   "/bootstrap — verify environment"
install_file ".claude/commands/implement.md"   "$BOOTSTRAP_CLAUDE/commands/implement.md"   "/implement — TDD feature build"
install_file ".claude/commands/ratchet.md"     "$BOOTSTRAP_CLAUDE/commands/ratchet.md"     "/ratchet — autonomous improvement"
install_file ".claude/commands/review.md"      "$BOOTSTRAP_CLAUDE/commands/review.md"      "/review — code review"
install_file ".claude/commands/health.md"      "$BOOTSTRAP_CLAUDE/commands/health.md"      "/health — project health check"
install_file ".claude/commands/retro.md"       "$BOOTSTRAP_CLAUDE/commands/retro.md"       "/retro — session retrospective"
install_file ".claude/commands/digest.md"      "$BOOTSTRAP_CLAUDE/commands/digest.md"      "/digest — daily quality report"
install_file ".claude/commands/dashboard.md"   "$BOOTSTRAP_CLAUDE/commands/dashboard.md"   "/dashboard — visual HTML report"
install_file ".claude/commands/walkthrough.md" "$BOOTSTRAP_CLAUDE/commands/walkthrough.md" "/walkthrough — project tour"
install_file ".claude/commands/check.md"       "$BOOTSTRAP_CLAUDE/commands/check.md"       "/check — 30-second spot check"

# ============================================================================
step 6 "Installing conditional rules (path-scoped)"
# ============================================================================
echo -e "  ${DIM}These load ONLY when Claude touches matching files.${NC}"
echo ""

install_file ".claude/rules/testing.md"       "$BOOTSTRAP_CLAUDE/rules/testing.md"       "testing rules (*.test.*, *.spec.*)"
install_file ".claude/rules/ui.md" "$BOOTSTRAP_CLAUDE/rules/ui.md"                       "UI rules (*.tsx, *.jsx, components/)"
install_file ".claude/rules/safety.md"        "$BOOTSTRAP_CLAUDE/rules/safety.md"        "safety rules (*.sh, *.env, hooks/)"

# ============================================================================
step 7 "Installing reference documentation"
# ============================================================================

install_file "docs/ARCHITECTURE.md"   "$BOOTSTRAP_SOURCE/docs/ARCHITECTURE.md"   "system design decisions"
install_file "docs/PATTERNS.md"       "$BOOTSTRAP_SOURCE/docs/PATTERNS.md"       "code patterns & anti-patterns"
install_file "docs/DEBUGGING.md"      "$BOOTSTRAP_SOURCE/docs/DEBUGGING.md"      "known issues & recovery"
install_file "docs/QUICKREF.md"       "$BOOTSTRAP_SOURCE/docs/QUICKREF.md"       "quick reference card"
install_file "docs/ESCAPE-HATCHES.md" "$BOOTSTRAP_SOURCE/docs/ESCAPE-HATCHES.md" "failure mode catalog"

# ============================================================================
step 8 "Installing state files and conductor"
# ============================================================================

install_file ".claude/settings.json"     "$BOOTSTRAP_CLAUDE/settings.json"     "hooks config, permissions, agent teams"
install_file ".claude/ratchet-state.json" "$BOOTSTRAP_CLAUDE/ratchet-state.json" "experiment baseline (initial)"
install_file ".claude/model-config.json" "$BOOTSTRAP_CLAUDE/model-config.json" "model/effort tier configuration"
install_file ".claude/OPEN-QUESTIONS.md" "$BOOTSTRAP_CLAUDE/OPEN-QUESTIONS.md" "blind spot forcing questions"
install_file ".claude/EVOLUTION.md"      "$BOOTSTRAP_CLAUDE/EVOLUTION.md"      "instruction evolution log"
install_file "scripts/conductor.sh"      "$BOOTSTRAP_SOURCE/scripts/conductor.sh" "external session controller"

# ============================================================================
step 9 "Creating project-specific placeholders"
# ============================================================================
echo -e "  ${DIM}These files need YOUR customization. See instructions inside each.${NC}"
echo ""

# CLAUDE.md — only create if doesn't exist
if [ ! -f "CLAUDE.md" ]; then
  install_file "CLAUDE.md" "$BOOTSTRAP_SOURCE/CLAUDE.md.template" "★ CUSTOMIZE: your project constitution"
else
  warn "CLAUDE.md already exists — not overwriting. Review template at $BOOTSTRAP_SOURCE/CLAUDE.md.template"
  WARNINGS=$((WARNINGS + 1))
fi

install_file "program.md"      "$BOOTSTRAP_SOURCE/program.md.template"   "★ CUSTOMIZE: ratchet experiment directions"
install_file ".claude/TODO.md" "$BOOTSTRAP_CLAUDE/TODO.md.template"      "★ CUSTOMIZE: your task list"

# ============================================================================
step 10 "Setting permissions and verifying tools"
# ============================================================================

echo "  Setting hook permissions..."
chmod +x .claude/hooks/*.sh 2>/dev/null && ok "All hooks marked executable" || warn "Could not chmod hooks"
chmod +x scripts/conductor.sh 2>/dev/null && ok "Conductor marked executable" || warn "Could not chmod conductor"

echo ""
echo "  Checking required tools..."

check_tool() {
  if command -v "$1" &>/dev/null; then
    ok "$1 found: $($1 --version 2>&1 | head -1)"
  else
    if [ "$2" = "required" ]; then
      fail "$1 NOT FOUND — $3"
      WARNINGS=$((WARNINGS + 1))
    else
      warn "$1 not found — $3"
    fi
  fi
}

check_tool "git"     "required" "essential for version control"
check_tool "jq"      "required" "hooks depend on it. Install: brew install jq / apt install jq"
check_tool "claude"  "required" "install from https://code.claude.com"
check_tool "node"    "optional" "needed for JS/TS projects"
check_tool "python3" "optional" "needed for Python projects"

# .gitignore
echo ""
echo "  Updating .gitignore..."
GITIGNORE_ENTRIES=(
  ".env"
  ".env.*"
  "*.key"
  "*.pem"
  ".claude/logs/"
  ".claude/worktrees/"
  ".claude/HANDOFF.md"
  ".claude/JOURNAL.md"
  ".claude/conductor.pid"
  "CLAUDE.local.md"
  ".claude/settings.local.json"
  "node_modules/"
)

[ ! -f ".gitignore" ] && touch .gitignore
for entry in "${GITIGNORE_ENTRIES[@]}"; do
  if ! grep -qF "$entry" .gitignore 2>/dev/null; then
    echo "$entry" >> .gitignore
    ok "Added to .gitignore: $entry"
  fi
done

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    INSTALLATION COMPLETE                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "  Files created:  ${G}$CREATED${NC}"
echo -e "  Files skipped:  ${DIM}$SKIPPED (already existed)${NC}"
echo -e "  Warnings:       ${Y}$WARNINGS${NC}"
echo ""

if [ "$WARNINGS" -gt 0 ]; then
  echo -e "${Y}⚠ Review warnings above before proceeding.${NC}"
  echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BOLD}NEXT STEPS — DO THESE IN ORDER:${NC}"
echo ""
echo -e "${BOLD}1. CUSTOMIZE CLAUDE.md (REQUIRED)${NC}"
echo "   Open CLAUDE.md and replace ALL [BRACKETED] values:"
echo "   - [PROJECT_NAME] → your project name"
echo "   - [DEFINE YOUR STACK HERE] → e.g. 'Next.js 14, TypeScript, Tailwind'"
echo "   - [your test command] → e.g. 'npx vitest run'"
echo "   - [your build command] → e.g. 'npm run build'"
echo "   - [your lint command] → e.g. 'npx eslint src/'"
echo "   - [your typecheck command] → e.g. 'npx tsc --noEmit'"
echo ""
echo -e "${BOLD}2. CUSTOMIZE program.md (RECOMMENDED)${NC}"
echo "   Edit program.md to list improvement directions specific to"
echo "   your project. The ratchet loop reads this for experiment ideas."
echo ""
echo -e "${BOLD}3. CUSTOMIZE .claude/TODO.md (RECOMMENDED)${NC}"
echo "   Replace placeholder tasks with your actual project phases."
echo ""
echo -e "${BOLD}4. START CLAUDE CODE${NC}"
echo "   cd $(pwd)"
echo "   claude"
echo "   Then type: /bootstrap"
echo "   Then type: /health"
echo ""
echo -e "${BOLD}5. FOR AUTONOMOUS OVERNIGHT RUNS${NC}"
echo "   In a separate terminal (NOT inside Claude Code):"
echo "   bash scripts/conductor.sh --auto --budget 5"
echo "   Open browser: http://localhost:7777 (after --serve)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BOLD}WHAT'S REQUIRED vs OPTIONAL:${NC}"
echo ""
echo "  REQUIRED (won't work without these):"
echo "    ✦ CLAUDE.md with your stack and commands filled in"
echo "    ✦ .claude/settings.json (installed, don't need to edit)"
echo "    ✦ .claude/hooks/*.sh (installed, don't need to edit)"
echo "    ✦ git initialized in your project"
echo "    ✦ jq installed on your system"
echo ""
echo "  RECOMMENDED (significantly better with these):"
echo "    ✦ program.md customized for your project"
echo "    ✦ .claude/TODO.md with your actual tasks"
echo "    ✦ Test runner configured and working"
echo ""
echo "  OPTIONAL (can add later):"
echo "    ✦ .claude/rules/*.md (add project-specific rules)"
echo "    ✦ .claude/model-config.json (change model tiers)"
echo "    ✦ scripts/conductor.sh (for overnight autonomous runs)"
echo "    ✦ /dashboard, /walkthrough (visual reports)"
echo ""
echo "  LEAVE ALONE (don't edit, system manages these):"
echo "    ✦ .claude/ratchet-state.json (ratchet loop manages)"
echo "    ✦ .claude/JOURNAL.md (stop hook manages)"
echo "    ✦ .claude/HANDOFF.md (hooks manage)"
echo "    ✦ .claude/EVOLUTION.md (meta-ratchet manages, you review)"
echo "    ✦ .claude/reports/ (commands generate)"
echo "    ✦ .claude/logs/ (hooks generate)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${DIM}Full manual: docs/MANUAL.md${NC}"
echo -e "  ${DIM}Quick reference: docs/QUICKREF.md${NC}"
echo -e "  ${DIM}Failure catalog: docs/ESCAPE-HATCHES.md${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
