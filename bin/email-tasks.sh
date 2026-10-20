#!/bin/bash
# Turns flagged emails into checkboxes on the Dashboard, without Claude ever
# reading them. Called by standup-daily.sh before /standup.
#
# A mail automation (for example a Power Automate flow on "email flagged")
# writes one small JSON file per flagged email (id, from, subject, received)
# into MAIL_DIR, named flag-*.json. This script appends each new one to
# "Email tasks.md" under "## From email", remembers its id so a re-run never
# duplicates it, then deletes the JSON. Lines you tick in Obsidian stay as you
# left them.
#
# Claude is denied Read on "Email tasks.md" and on MAIL_DIR in
# .claude/settings.json; this script logs counts only, never subjects.
#
# MAIL_DIR comes from config.env. Unset = this step is skipped.
# Manual run:  ~/Projects/workflow/bin/email-tasks.sh

set -uo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$PROJECT/config.env" ]] && source "$PROJECT/config.env"
SRC="${MAIL_DIR:-}"
VAULT="$HOME/Documents/Obsidian Vault/Workflow"
OUT="$VAULT/Email tasks.md"
SEEN="$HOME/.claude/state/email-tasks-seen"
JQ="${JQ_BIN:-$(command -v jq || echo /usr/bin/jq)}"

[[ -z "$SRC" ]] && exit 0
mkdir -p "$(dirname "$SEEN")"; touch "$SEEN"

if [[ ! -d "$SRC" ]]; then echo "email-tasks: $SRC not found; skipped"; exit 0; fi
if [[ ! -f "$OUT" ]]; then
  printf '%s\n\n%s\n' "Flagged in email. Tick when done; unflagging in your mail client does not remove a line." "## From email" >"$OUT" \
    || { echo "email-tasks: cannot create $OUT"; exit 1; }
fi

added=0; skipped=0; failed=0
shopt -s nullglob
for f in "$SRC"/flag-*.json; do
  # Two lines: the id, then the markdown checkbox. The subject is made link-safe
  # so it cannot create [[links]], #tags or table pipes in the vault.
  # The "open" link below is the Outlook web deep-link shape; change it for your client.
  row="$("$JQ" -r '
    def clean: tostring | gsub("[\r\n\t]+"; " ") | gsub("\\[|\\]"; "") | gsub("\\|"; "/") | gsub("#"; "\\#");
    (.from | if type == "object" then (.emailAddress.address // .address // "") else (. // "") end) as $from
    | ((.received // "") | tostring | .[0:10]) as $day
    | (.id // "" | tostring | clean),
      "- [ ] \((.subject // "(no subject)") | clean) · \($from | clean) · \($day) · [open](https://outlook.office.com/mail/deeplink/read/\(.id // "" | tostring | @uri))"
    ' "$f" 2>/dev/null)"
  id="${row%%$'\n'*}"; line="${row#*$'\n'}"
  if [[ -z "$row" || -z "$id" || "$line" == "$row" ]]; then failed=$((failed + 1)); continue; fi
  if grep -qxF "$id" "$SEEN"; then skipped=$((skipped + 1)); rm -f "$f"; continue; fi
  if printf '%s\n' "$line" >>"$OUT" 2>/dev/null; then
    printf '%s\n' "$id" >>"$SEEN"; rm -f "$f"; added=$((added + 1))
  else
    failed=$((failed + 1))
  fi
done

(( added + skipped + failed > 0 )) && echo "email-tasks: added $added, already seen $skipped, failed $failed"
(( failed == 0 ))
