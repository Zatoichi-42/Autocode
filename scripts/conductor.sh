#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# CONDUCTOR — External Claude Code Session Controller
#
# This script runs OUTSIDE Claude Code sessions. It is the heartbeat
# that keeps development going through crashes, rate limits, and session
# limits. It spawns claude -p sessions, monitors their exit, decides
# what to do next, and restarts work automatically.
#
# Usage:
#   bash scripts/conductor.sh                    # Interactive menu
#   bash scripts/conductor.sh --auto             # Autonomous mode (overnight)
#   bash scripts/conductor.sh --auto --budget 5  # Cap at $5 total spend
#   bash scripts/conductor.sh --check            # Quick status (no session)
#   bash scripts/conductor.sh --serve            # Start web UI on port 7777
#
# Requirements: claude CLI, jq, git, bash 4+
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_FILE="$PROJECT_DIR/.claude/conductor-state.json"
LOG_FILE="$PROJECT_DIR/.claude/logs/conductor.log"
WEB_DIR="$PROJECT_DIR/.claude/reports"
PIDFILE="$PROJECT_DIR/.claude/conductor.pid"
PORT="${CONDUCTOR_PORT:-7777}"

# Budget and safety limits
MAX_BUDGET="${2:-10}"
MAX_CONSECUTIVE_FAILS=3
MAX_SESSIONS=50
BASE_RATE_LIMIT_WAIT=300     # 5 min base, doubles each time
SESSION_TIMEOUT=600
MAX_TURNS=25

# Colors
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; NC='\033[0m'

log() { echo -e "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

# ---- Pidfile Lock (prevents overlapping conductors) ----

acquire_lock() {
  if [ -f "$PIDFILE" ]; then
    local old_pid=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      log "${R}Another conductor is running (PID $old_pid). Exiting.${NC}"
      exit 1
    else
      log "${Y}Stale pidfile found (PID $old_pid dead). Taking over.${NC}"
      rm -f "$PIDFILE"
    fi
  fi
  echo $ > "$PIDFILE"
  trap 'rm -f "$PIDFILE"' EXIT INT TERM
}

release_lock() {
  rm -f "$PIDFILE"
}

# ---- State Management ----

init_state() {
  mkdir -p "$(dirname "$STATE_FILE")" "$(dirname "$LOG_FILE")" "$WEB_DIR"
  if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" << 'JSON'
{
  "status": "idle",
  "total_sessions": 0,
  "total_cost_usd": 0,
  "consecutive_failures": 0,
  "last_session_id": null,
  "last_exit_reason": null,
  "current_task": null,
  "history": [],
  "started_at": null,
  "stopped_at": null
}
JSON
  fi
}

read_state() { cat "$STATE_FILE" | jq -r "$1" 2>/dev/null; }
update_state() { 
  local tmp=$(mktemp)
  jq "$1" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

# ---- Task Resolution ----

get_next_task() {
  # Priority: incomplete TODO items, then ratchet, then scout
  local task=""
  
  if [ -f "$PROJECT_DIR/.claude/TODO.md" ]; then
    task=$(grep -m1 '^\- \[ \]' "$PROJECT_DIR/.claude/TODO.md" 2>/dev/null | sed 's/^- \[ \] //' || true)
  fi
  
  if [ -z "$task" ]; then
    task="Run /ratchet to autonomously improve the codebase following program.md directions."
  fi
  
  echo "$task"
}

build_prompt() {
  local task="$1"
  local context=""
  
  # Include journal if it exists AND is fresh (stale journal = certainty, not edge case)
  if [ -f "$PROJECT_DIR/.claude/JOURNAL.md" ]; then
    local journal_age=999999
    if stat --version >/dev/null 2>&1; then
      # GNU stat
      journal_age=$(( $(date +%s) - $(stat -c %Y "$PROJECT_DIR/.claude/JOURNAL.md") ))
    else
      # BSD stat (macOS)
      journal_age=$(( $(date +%s) - $(stat -f %m "$PROJECT_DIR/.claude/JOURNAL.md") ))
    fi
    
    if [ "$journal_age" -lt 3600 ]; then
      context="CONTEXT FROM PREVIOUS SESSION (${journal_age}s ago):\n$(cat "$PROJECT_DIR/.claude/JOURNAL.md")\n\n"
    else
      context="WARNING: Last journal is $(( journal_age / 3600 ))h old — may be stale. Verify git status before proceeding.\n\n"
    fi
  fi
  
  cat << PROMPT
${context}You are resuming work on this project. Read CLAUDE.md first.

YOUR TASK: ${task}

RULES:
- Follow CLAUDE.md and all project instructions
- Do not edit non-test source without a recent RED signal
- Commit working code frequently
- If you get stuck after 3 attempts, write what you learned to .claude/JOURNAL.md and stop
- Before stopping, run relevant tests and update .claude/TODO.md
- Write a brief status to .claude/JOURNAL.md when done

BEGIN.
PROMPT
}

# ---- Session Runner ----

run_session() {
  local task="$1"
  local prompt=$(build_prompt "$task")
  local session_num=$(read_state '.total_sessions')
  local start_time=$(date +%s)
  
  log "${B}━━━ Session #$((session_num + 1)) ━━━${NC}"
  log "Task: ${task:0:80}..."
  
  update_state '.status = "running" | .current_task = "'"$(echo "$task" | head -c 200 | sed 's/"/\\"/g')"'"'
  
  # Run claude in headless mode with safety limits
  local result_file=$(mktemp)
  local exit_code=0
  
  timeout "$SESSION_TIMEOUT" claude -p "$prompt" \
    --output-format json \
    --max-turns "$MAX_TURNS" \
    --max-budget-usd "$(echo "$MAX_BUDGET - $(read_state '.total_cost_usd')" | bc 2>/dev/null || echo "$MAX_BUDGET")" \
    --permission-mode auto \
    --allowedTools "Read,Write,Edit,MultiEdit,Bash,Glob,Grep,Agent" \
    > "$result_file" 2>>"$LOG_FILE" || exit_code=$?
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  # Parse result
  local session_id=$(jq -r '.session_id // "unknown"' "$result_file" 2>/dev/null || echo "unknown")
  local cost=$(jq -r '.total_cost_usd // 0' "$result_file" 2>/dev/null || echo "0")
  local is_error=$(jq -r '.is_error // false' "$result_file" 2>/dev/null || echo "false")
  local result_text=$(jq -r '.result // "no result"' "$result_file" 2>/dev/null | head -c 500)
  
  # Determine exit reason
  local exit_reason="completed"
  if [ "$exit_code" -eq 124 ]; then
    exit_reason="timeout"
  elif [ "$is_error" = "true" ]; then
    if echo "$result_text" | grep -qi "rate.limit\|429\|too many"; then
      exit_reason="rate_limit"
    elif echo "$result_text" | grep -qi "token\|context\|limit"; then
      exit_reason="token_limit"
    else
      exit_reason="error"
    fi
  fi
  
  # Update state
  local total_cost=$(read_state '.total_cost_usd')
  local new_cost=$(echo "$total_cost + $cost" | bc 2>/dev/null || echo "$total_cost")
  local consecutive_fails=$(read_state '.consecutive_failures')
  
  if [ "$exit_reason" = "completed" ]; then
    consecutive_fails=0
    log "${G}✓ Session completed${NC} (${duration}s, \$$cost)"
  else
    consecutive_fails=$((consecutive_fails + 1))
    log "${Y}⚠ Session ended: ${exit_reason}${NC} (${duration}s, \$$cost)"
  fi
  
  # Record to history
  update_state "
    .total_sessions += 1 |
    .total_cost_usd = $new_cost |
    .consecutive_failures = $consecutive_fails |
    .last_session_id = \"$session_id\" |
    .last_exit_reason = \"$exit_reason\" |
    .history += [{
      \"session\": (.total_sessions),
      \"task\": \"$(echo "$task" | head -c 100 | sed 's/"/\\"/g')\",
      \"exit_reason\": \"$exit_reason\",
      \"duration_s\": $duration,
      \"cost_usd\": $cost,
      \"timestamp\": \"$(date -Iseconds)\"
    }]
  "
  
  # Generate live dashboard update
  generate_status_page
  
  rm -f "$result_file"
  echo "$exit_reason"
}

# ---- Auto Mode Loop ----

auto_loop() {
  acquire_lock
  log "${G}━━━ CONDUCTOR AUTO MODE ━━━${NC}"
  log "Budget: \$MAX_BUDGET | Max sessions: $MAX_SESSIONS | Timeout: ${SESSION_TIMEOUT}s"
  
  update_state '.status = "auto" | .started_at = "'"$(date -Iseconds)"'"'
  
  local sessions=0
  local rate_limit_count=0
  
  while true; do
    # Check stopping conditions
    local total_cost=$(read_state '.total_cost_usd')
    local consecutive_fails=$(read_state '.consecutive_failures')
    
    if (( $(echo "$total_cost >= $MAX_BUDGET" | bc -l 2>/dev/null || echo 0) )); then
      log "${R}STOP: Budget limit reached (\$total_cost / \$MAX_BUDGET)${NC}"
      break
    fi
    
    if [ "$consecutive_fails" -ge "$MAX_CONSECUTIVE_FAILS" ]; then
      log "${R}STOP: $consecutive_fails consecutive failures${NC}"
      break
    fi
    
    if [ "$sessions" -ge "$MAX_SESSIONS" ]; then
      log "${R}STOP: Max sessions reached ($sessions)${NC}"
      break
    fi
    
    # Get next task
    local task=$(get_next_task)
    if [ -z "$task" ]; then
      log "${G}STOP: No more tasks${NC}"
      break
    fi
    
    # Run session
    local exit_reason=$(run_session "$task")
    sessions=$((sessions + 1))
    
    # Decide what to do — every path is a main path
    case "$exit_reason" in
      completed)
        rate_limit_count=0  # Reset backoff on success
        log "Moving to next task..."
        sleep 5
        ;;
      rate_limit)
        rate_limit_count=$((rate_limit_count + 1))
        local wait_time=$((BASE_RATE_LIMIT_WAIT * (2 ** (rate_limit_count - 1))))
        if [ "$rate_limit_count" -ge 3 ]; then
          log "${R}STOP: 3 consecutive rate limits. Waiting for human.${NC}"
          break
        fi
        log "Rate limited (#$rate_limit_count). Exponential backoff: ${wait_time}s..."
        sleep "$wait_time"
        ;;
      token_limit|timeout)
        rate_limit_count=0
        log "Session limit. Journal preserved. Restarting in 10s..."
        sleep 10
        ;;
      error)
        rate_limit_count=0
        log "Error occurred. Retrying with next task in 30s..."
        sleep 30
        ;;
    esac
  done
  
  update_state '.status = "idle" | .stopped_at = "'"$(date -Iseconds)"'"'
  release_lock
  
  local total_sessions=$(read_state '.total_sessions')
  local total_cost=$(read_state '.total_cost_usd')
  log ""
  log "${G}━━━ CONDUCTOR SUMMARY ━━━${NC}"
  log "Sessions: $total_sessions | Cost: \$total_cost"
  log "Dashboard: .claude/reports/conductor.html"
}

# ---- Web UI ----

generate_status_page() {
  local state=$(cat "$STATE_FILE" 2>/dev/null || echo '{}')
  local journal=$(cat "$PROJECT_DIR/.claude/JOURNAL.md" 2>/dev/null | sed 's/"/\\"/g; s/$/\\n/' | tr -d '\n' || echo "No journal")
  local todo_remaining=$(grep -c '^\- \[ \]' "$PROJECT_DIR/.claude/TODO.md" 2>/dev/null || echo 0)
  local todo_done=$(grep -c '^\- \[x\]' "$PROJECT_DIR/.claude/TODO.md" 2>/dev/null || echo 0)
  local test_status="unknown"
  local branch=$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null || echo "unknown")
  
  cat > "$WEB_DIR/conductor.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="refresh" content="15">
<title>Conductor — Project Control</title>
<style>
  :root { --bg: #0d1117; --card: #161b22; --border: #30363d; --text: #e6edf3;
    --green: #3fb950; --yellow: #d29922; --red: #f85149; --blue: #58a6ff; --muted: #8b949e; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, system-ui, sans-serif; background: var(--bg); color: var(--text);
    padding: 1rem; max-width: 1200px; margin: 0 auto; }
  h1 { font-size: 1.5rem; margin-bottom: 1rem; display: flex; align-items: center; gap: .5rem; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 1rem; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; }
  .card h2 { font-size: .9rem; color: var(--muted); text-transform: uppercase; letter-spacing: .05em; margin-bottom: .75rem; }
  .big-num { font-size: 2.5rem; font-weight: 700; line-height: 1; }
  .stat-row { display: flex; justify-content: space-between; padding: .4rem 0; border-bottom: 1px solid var(--border); }
  .stat-row:last-child { border-bottom: none; }
  .badge { display: inline-block; padding: .15rem .5rem; border-radius: 12px; font-size: .75rem; font-weight: 600; }
  .badge-green { background: #23863640; color: var(--green); }
  .badge-yellow { background: #d2992240; color: var(--yellow); }
  .badge-red { background: #f8514940; color: var(--red); }
  .badge-blue { background: #58a6ff30; color: var(--blue); }
  .history-item { padding: .5rem 0; border-bottom: 1px solid var(--border); font-size: .85rem; }
  .history-item:last-child { border-bottom: none; }
  pre { background: #0d1117; border: 1px solid var(--border); padding: .75rem; border-radius: 6px;
    font-size: .8rem; overflow-x: auto; white-space: pre-wrap; max-height: 300px; overflow-y: auto; }
  .controls { display: flex; gap: .5rem; flex-wrap: wrap; margin-bottom: 1rem; }
  .btn { padding: .5rem 1rem; border-radius: 6px; border: 1px solid var(--border); background: var(--card);
    color: var(--text); cursor: pointer; font-size: .85rem; }
  .btn:hover { border-color: var(--blue); }
  .pulse { animation: pulse 2s infinite; }
  @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: .5; } }
  footer { margin-top: 2rem; text-align: center; color: var(--muted); font-size: .75rem; }
  @media (max-width: 600px) { .grid { grid-template-columns: 1fr; } .big-num { font-size: 2rem; } }
</style>
</head>
<body>
HTMLEOF

  # Inject dynamic data
  local status=$(echo "$state" | jq -r '.status // "idle"')
  local total_sessions=$(echo "$state" | jq -r '.total_sessions // 0')
  local total_cost=$(echo "$state" | jq -r '.total_cost_usd // 0')
  local consec_fails=$(echo "$state" | jq -r '.consecutive_failures // 0')
  local last_reason=$(echo "$state" | jq -r '.last_exit_reason // "none"')
  local current_task=$(echo "$state" | jq -r '.current_task // "none"')
  
  local status_badge="badge-blue"
  local status_icon="⏸"
  case "$status" in
    running|auto) status_badge="badge-green"; status_icon="▶";;
    idle) status_badge="badge-blue"; status_icon="⏸";;
    *) status_badge="badge-yellow"; status_icon="⚠";;
  esac

  cat >> "$WEB_DIR/conductor.html" << DYNAMIC
<h1><span class="badge $status_badge ${status:+pulse}">$status_icon $status</span> Conductor — $(basename "$PROJECT_DIR")</h1>

<div class="controls">
  <span class="btn" onclick="location.reload()">↻ Refresh</span>
  <span class="btn">Branch: $branch</span>
  <span class="btn">Tasks: $todo_done done / $((todo_done + todo_remaining)) total</span>
</div>

<div class="grid">
  <div class="card">
    <h2>Sessions</h2>
    <div class="big-num" style="color:var(--blue)">$total_sessions</div>
    <div class="stat-row"><span>Total cost</span><span>\$$total_cost</span></div>
    <div class="stat-row"><span>Budget remaining</span><span>\$$(echo "$MAX_BUDGET - $total_cost" | bc 2>/dev/null || echo "?")</span></div>
    <div class="stat-row"><span>Consecutive failures</span><span style="color:${consec_fails:+var(--$([ "$consec_fails" -ge 2 ] && echo red || echo green))}">$consec_fails / $MAX_CONSECUTIVE_FAILS</span></div>
    <div class="stat-row"><span>Last exit</span><span class="badge badge-$([ "$last_reason" = "completed" ] && echo green || echo yellow)">$last_reason</span></div>
  </div>

  <div class="card">
    <h2>Current Task</h2>
    <p style="font-size:.9rem; line-height:1.5">$(echo "$current_task" | head -c 300)</p>
  </div>

  <div class="card">
    <h2>Latest Journal</h2>
    <pre>$(cat "$PROJECT_DIR/.claude/JOURNAL.md" 2>/dev/null | head -30 || echo "No journal yet")</pre>
  </div>

  <div class="card">
    <h2>Session History</h2>
DYNAMIC

  # Add history entries
  echo "$state" | jq -r '.history[-10:] | reverse | .[] | "<div class=\"history-item\"><span class=\"badge badge-" + (if .exit_reason == "completed" then "green" else "yellow" end) + "\">" + .exit_reason + "</span> #" + (.session | tostring) + " — " + (.task // "?")[0:60] + " <span style=\"color:var(--muted)\">(" + (.duration_s | tostring) + "s, $" + (.cost_usd | tostring) + ")</span></div>"' 2>/dev/null >> "$WEB_DIR/conductor.html" || echo '<p style="color:var(--muted)">No sessions yet</p>' >> "$WEB_DIR/conductor.html"

  cat >> "$WEB_DIR/conductor.html" << 'ENDHTML'
  </div>
</div>

<footer>
  Auto-refreshes every 15 seconds. Generated by Conductor.
  <br>Run <code>bash scripts/conductor.sh --serve</code> to start the web server.
</footer>
</body>
</html>
ENDHTML
}

serve_ui() {
  generate_status_page
  log "${G}Serving dashboard at http://localhost:$PORT${NC}"
  log "Open in browser or on phone (same network)"
  cd "$WEB_DIR"
  python3 -m http.server "$PORT" 2>/dev/null || python -m SimpleHTTPServer "$PORT" 2>/dev/null || {
    log "${R}Python not found. Open .claude/reports/conductor.html directly.${NC}"
    exit 1
  }
}

# ---- Status Check ----

status_check() {
  init_state
  generate_status_page
  
  local status=$(read_state '.status')
  local sessions=$(read_state '.total_sessions')
  local cost=$(read_state '.total_cost_usd')
  local fails=$(read_state '.consecutive_failures')
  local last=$(read_state '.last_exit_reason')
  
  echo -e "${B}━━━ CONDUCTOR STATUS ━━━${NC}"
  echo -e "Status:     $status"
  echo -e "Sessions:   $sessions"
  echo -e "Cost:       \$$cost / \$$MAX_BUDGET"
  echo -e "Failures:   $fails / $MAX_CONSECUTIVE_FAILS"
  echo -e "Last exit:  $last"
  echo -e "Dashboard:  .claude/reports/conductor.html"
  echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ---- Main ----

cd "$PROJECT_DIR"
init_state

case "${1:-}" in
  --auto)
    auto_loop
    ;;
  --check)
    status_check
    ;;
  --serve)
    serve_ui
    ;;
  --reset)
    rm -f "$STATE_FILE"
    init_state
    log "State reset."
    ;;
  *)
    echo "Conductor — External Claude Code Session Controller"
    echo ""
    echo "Usage:"
    echo "  conductor.sh --auto [--budget N]  Autonomous mode (overnight)"
    echo "  conductor.sh --check              Quick status"
    echo "  conductor.sh --serve              Start web UI on port $PORT"
    echo "  conductor.sh --reset              Reset conductor state"
    echo ""
    status_check
    ;;
esac
