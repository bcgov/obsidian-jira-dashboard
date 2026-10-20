#!/bin/bash
# Morning runner, called by launchd (local.workflow.standup) every 30
# minutes. Works only on weekdays between 06:30 and 12:00. Three jobs, each
# with its own "done" stamp so a later failure retries without redoing the rest:
#   1. standup   every weekday   (Dashboard, briefing, Proposed, Team)
#   2. prreview  every weekday   (PR review drafts; read-only tools only)
#   3. weekly    Fridays         (weekly review; proposals into Proposed)
# Until standup succeeds, every failed attempt (VPN down, Jira auth expired)
# writes a banner to the top of the Dashboard saying what to fix.
# Every run, at any hour, first calls bin/email-tasks.sh (flagged emails into
# "Email tasks.md"; plain bash, the agent never reads them).
#
# The agent is chosen by AGENT in config.env: claude (Claude Code) or copilot
# (GitHub Copilot CLI). Both run the same prompts/<name>.md.
#
# Manual run:            ~/Projects/workflow/bin/standup-daily.sh
# Force a re-run today:  ~/Projects/workflow/bin/standup-daily.sh --force
# Also force weekly:     ~/Projects/workflow/bin/standup-daily.sh --force --weekly
# Watch the log:         tail -f ~/Library/Logs/workflow-standup.log

set -uo pipefail

LOG="$HOME/Library/Logs/workflow-standup.log"
STATE="$HOME/.claude/state"
STAMP="$STATE/standup-last-run"
PR_STAMP="$STATE/prreview-last-run"
WK_STAMP="$STATE/weekly-last-run"
PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT="$HOME/Documents/Obsidian Vault/Workflow"
STATUS="$VAULT/Refresh status.md"
TIMEOUT="${TIMEOUT_BIN:-/opt/homebrew/bin/timeout}"   # GNU timeout: brew install coreutils
TODAY="$(date +%F)"
WEEK="$(date +%G-W%V)"
FORCE=0; FORCE_WEEKLY=0
for a in "$@"; do
  [[ "$a" == "--force" ]] && FORCE=1
  [[ "$a" == "--weekly" ]] && FORCE_WEEKLY=1
done

# AGENT, JIRA_HOST, AUTH_CMD, optionally CLAUDE_BIN, COPILOT_BIN, MAIL_DIR.
[[ -f "$PROJECT/config.env" ]] && source "$PROJECT/config.env"
AGENT="${AGENT:-claude}"
CLAUDE="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
COPILOT="${COPILOT_BIN:-copilot}"
JIRA_HOST="${JIRA_HOST:-}"
AUTH_CMD="${AUTH_CMD:-your Jira login command}"

mkdir -p "$(dirname "$LOG")" "$STATE"
exec >>"$LOG" 2>&1

LAST_OK="$(cat "$STAMP" 2>/dev/null || echo never)"
PR_OK="$(cat "$PR_STAMP" 2>/dev/null || echo never)"
WK_OK="$(cat "$WK_STAMP" 2>/dev/null || echo never)"

# What still needs doing today?
NEED_STANDUP=0; NEED_PR=0; NEED_WEEKLY=0
[[ $FORCE -eq 1 || "$LAST_OK" != "$TODAY" ]] && NEED_STANDUP=1
[[ $FORCE -eq 1 || "$PR_OK" != "$TODAY" ]] && NEED_PR=1
if [[ $FORCE_WEEKLY -eq 1 ]] || { [[ "$(date +%u)" == 5 ]] && [[ "$WK_OK" != "$WEEK" ]]; }; then
  NEED_WEEKLY=1
fi

# Run one workflow headless. $1 = workflow name (standup|prreview|weekly);
# the rest = the Claude Code tool allow-list (Copilot takes its tools from
# .github/agents/<name>.agent.md and needs --allow-all-tools when headless).
# Output goes to the log and to $LAST_OUT, so failures can be recognised.
LAST_OUT="$STATE/last-agent-output.txt"
run_agent() {
  local name="$1"; shift
  case "$AGENT" in
    claude)
      (cd "$PROJECT" && "$TIMEOUT" 900 "$CLAUDE" -p "/$name --scheduled" --permission-mode acceptEdits --allowedTools "$@") 2>&1 | tee "$LAST_OUT"
      return "${PIPESTATUS[0]}" ;;
    copilot)
      (cd "$PROJECT" && "$TIMEOUT" 900 "$COPILOT" --agent "$name" -p "Run the $name workflow now. This is a scheduled run: --scheduled" \
        --allow-all-tools --add-dir "$VAULT" -s) 2>&1 | tee "$LAST_OUT"
      return "${PIPESTATUS[0]}" ;;
    *)
      echo "ERROR: AGENT=$AGENT in config.env must be claude or copilot"; return 2 ;;
  esac
}

# One-line file write through the agent, for the banner fallback below.
agent_write_line() {   # $1 = file, $2 = the line
  local prompt="Read the file \"$1\", then overwrite it so it contains exactly this one line, unchanged, and nothing else. Do not touch any other file. When the file is written, reply with only the word DONE. The line: $2"
  case "$AGENT" in
    claude)  (cd "$PROJECT" && "$TIMEOUT" 120 "$CLAUDE" -p "$prompt" --permission-mode acceptEdits --allowedTools Read Write 2>&1) ;;
    copilot) (cd "$PROJECT" && "$TIMEOUT" 120 "$COPILOT" -p "$prompt" --allow-all-tools --add-dir "$VAULT" -s 2>&1) ;;
    *) echo "AGENT=$AGENT unknown" ;;
  esac
}

# Replace the status banner embedded at the top of the Dashboard.
# Under launchd, macOS privacy protection blocks /bin/bash from writing into
# ~/Documents ("Operation not permitted"), while the agent binary has been
# granted access. So try a direct write first, then let the agent write the line.
write_status() {
  local line; line="$(printf '> [!%s] %s' "$1" "$2")"
  if printf '%s\n' "$line" >"$STATUS" 2>/dev/null; then return 0; fi
  local out; out="$(agent_write_line "$STATUS" "$line")"
  if [[ "$out" == *DONE* ]]; then echo "banner written via $AGENT fallback"
  else echo "WARN: could not write the Dashboard banner. Fallback said: ${out:0:300}"; fi
}

# Failed attempt before the Dashboard refreshed: banner, notification, no stamp.
fail() {
  echo "$1"
  write_status failure "Not refreshed today (last good: $LAST_OK). $2"
  /usr/bin/osascript -e "display notification \"$3\" with title \"Workflow dashboard\"" >/dev/null 2>&1
}

# True when the agent CLI itself could not log in (not Jira, not the VPN).
agent_login_failed() { grep -qiE 'OAuth session expired|Failed to authenticate|Please run /login|not logged in|Invalid API key|not authenticated|gh auth login|copilot login' "$LAST_OUT" 2>/dev/null; }

"$PROJECT/bin/email-tasks.sh" || echo "WARN: email-tasks failed; see above"

if [[ $FORCE -eq 0 ]]; then
  DOW="$(date +%u)"; HM="$(date +%H%M)"
  if (( DOW > 5 )) || (( 10#$HM < 630 )) || (( 10#$HM >= 1200 )); then exit 0; fi
fi
(( NEED_STANDUP + NEED_PR + NEED_WEEKLY == 0 )) && exit 0

echo "--- $(date '+%F %T') morning runner (agent=$AGENT standup=$NEED_STANDUP prreview=$NEED_PR weekly=$NEED_WEEKLY) ---"

# Jira and Bitbucket may sit behind a VPN: check reachability before spending a run.
if [[ -z "$JIRA_HOST" ]]; then
  fail "ERROR: JIRA_HOST not set in config.env" \
    "JIRA_HOST is missing from config.env." "JIRA_HOST missing from config.env"
  exit 1
fi
if ! curl -sS -o /dev/null --max-time 10 "https://$JIRA_HOST" 2>/dev/null; then
  if [[ $NEED_STANDUP -eq 1 ]]; then
    fail "skipped: $JIRA_HOST unreachable (VPN down?); will retry at the next slot" \
      "VPN is not connected. Connect it and the Dashboard refreshes within 30 minutes (until noon), or run \`~/Projects/workflow/bin/standup-daily.sh\` now." \
      "Not refreshed: connect the VPN"
  else
    echo "skipped: $JIRA_HOST unreachable; PR drafts / weekly will retry at the next slot"
  fi
  exit 0
fi
echo "$JIRA_HOST reachable"

# 1. standup
if [[ $NEED_STANDUP -eq 1 ]]; then
  run_agent standup \
    mcp__jira__search_issues mcp__jira__list_deployment_slots mcp__jira__get_board mcp__jira__get_sprint \
    Read Write Edit Glob Grep "Bash(date:*)" "Bash(ls:*)" "Bash(cat:*)" "Bash(head:*)"
  RC=$?
  DAILY="$VAULT/Daily/$TODAY.md"
  if [[ $RC -eq 0 ]] && grep -q '^## Run failed' "$DAILY" 2>/dev/null; then
    if sed -n '/^## Run failed/,$p' "$DAILY" | grep -qiE '401|403|unauthori|auth'; then
      fail "ERROR: Jira auth failed; see $DAILY" \
        "Jira login expired. Run \`$AUTH_CMD\`, then \`~/Projects/workflow/bin/standup-daily.sh\`." \
        "Not refreshed: Jira login expired"
    else
      fail "ERROR: standup reported a failed run; see $DAILY" \
        "A Jira call failed; see [[Workflow/Daily/$TODAY|today's briefing]]. Retrying in 30 minutes." \
        "Not refreshed: a Jira call failed"
    fi
    exit 1
  elif [[ $RC -eq 124 ]]; then
    fail "ERROR: standup timed out after 15 min" \
      "The refresh timed out. Retrying in 30 minutes; log: ~/Library/Logs/workflow-standup.log." "Not refreshed: timed out"
    exit $RC
  elif [[ $RC -ne 0 ]] && agent_login_failed; then
    fail "ERROR: $AGENT login expired" \
      "The $AGENT CLI's login has expired. Open Terminal, run \`$AGENT\`, and log in. The Dashboard refreshes within 30 minutes (until noon)." \
      "Not refreshed: $AGENT login expired. Run $AGENT in Terminal and log in."
    exit $RC
  elif [[ $RC -ne 0 ]]; then
    fail "ERROR: standup exited $RC" \
      "The refresh failed ($AGENT exit $RC). Retrying in 30 minutes; log: ~/Library/Logs/workflow-standup.log." "Not refreshed: $AGENT exited $RC"
    exit $RC
  fi
  echo "$TODAY" >"$STAMP"; LAST_OK="$TODAY"
  echo "OK: standup"
fi

# 2. prreview (read-only Bitbucket/GitHub tools; PR text is untrusted, so no write tools outside the vault)
PR_NOTE=""
if [[ $NEED_PR -eq 1 ]]; then
  run_agent prreview \
    mcp__bitbucket__list_pull_requests mcp__bitbucket__read_pull_request mcp__bitbucket__get_pr_diff \
    mcp__bitbucket__list_pr_commits mcp__bitbucket__list_pr_comments mcp__bitbucket__read_file \
    mcp__github__search_pull_requests mcp__github__pull_request_read \
    Read Write Edit Glob Grep "Bash(date:*)" "Bash(ls:*)"
  RC=$?
  if [[ $RC -eq 0 ]]; then echo "$TODAY" >"$PR_STAMP"; echo "OK: prreview"
  else PR_NOTE=" · PR drafts failed (retrying)"; echo "ERROR: prreview exited $RC; will retry at the next slot"; fi
fi

# 3. weekly (Fridays)
WK_NOTE=""
if [[ $NEED_WEEKLY -eq 1 ]]; then
  run_agent weekly \
    mcp__jira__search_issues mcp__jira__read_issue mcp__jira__list_deployment_slots \
    Read Write Edit Glob Grep "Bash(date:*)" "Bash(ls:*)" "Bash(cat:*)" "Bash(head:*)"
  RC=$?
  if [[ $RC -eq 0 ]] && ! grep -q '^## Run failed' "$VAULT/Weekly/$WEEK.md" 2>/dev/null; then
    echo "$WEEK" >"$WK_STAMP"; echo "OK: weekly"
  else WK_NOTE=" · weekly review failed (retrying)"; echo "ERROR: weekly failed (exit $RC); will retry at the next slot"; fi
fi

WEEKLY_LINK=""
[[ -f "$VAULT/Weekly/$WEEK.md" ]] && WEEKLY_LINK=" · [[Workflow/Weekly/$WEEK|this week's review]]"
# standup writes the success banner itself. Rewrite it here only if a later step
# failed, added the weekly review, or standup didn't run in this invocation.
if [[ $NEED_STANDUP -eq 1 && -z "$PR_NOTE$WK_NOTE$WEEKLY_LINK" ]]; then exit 0; fi
write_status success "Refreshed $(date '+%a %-d %b %H:%M') · [[Workflow/Daily/$TODAY|today's briefing]] · [[Workflow/Proposed|Proposed]] · [[Workflow/PR reviews|PR reviews]]$WEEKLY_LINK$PR_NOTE$WK_NOTE"
exit 0
