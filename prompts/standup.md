# /standup

Refresh the Dashboard and write today's briefing. About two minutes of the user's attention. Read-only against Jira: never create, transition, assign, or comment on a ticket from this command. Anything that would write to Jira goes into Proposed for `/apply`.

## Paths

- VAULT = `/Users/YOUR_USER/Documents/Obsidian Vault/Workflow`
- Workstreams = `VAULT/Workstreams/*.md` (one note per workstream; frontmatter: row, area, status, next_action, waiting_on, tickets, last_touch, due)
- Dashboard = `VAULT/Dashboard.md` (one outer `> [!dashboard]` callout whose nested callouts are the tiles, each line prefixed `> > `. Four tiles are generated, identified by callout type: `> > [!todo|span-N] Today …`, `> > [!question|span-N] My turn to review`, `> > [!warning|span-N] Nudge`, `> > [!info|span-N] Upcoming …`. The `|span-N` metadata sets the tile width; keep it exactly as found.)
- Waiting = `VAULT/Waiting For.md` (sections My turn / Nudge due / Waiting, fine are generated; "Not in Jira" is hand-edited)
- Inbox = `VAULT/Inbox.md`
- Tasks = `VAULT/Tasks.md` (small non-Jira todos; sections Next / Later / Done)
- Daily = `VAULT/Daily/YYYY-MM-DD.md` (today, from `date +%F`)
- Proposed = `VAULT/Proposed.md` (the approval queue; format in "Proposed format" below)
- Team settings = `VAULT/Team settings.md` (hand-edited: people, rules, areas). Never edit it.
- Team = `VAULT/Team.md` (generated each run; format in "Step 3c" below)
- `VAULT/Refresh status.md` is the one-line banner at the top of the Dashboard. You write it at the end of Step 3 (see there); the runner script writes it when a run fails.

## Links

Links to workflow notes always carry the vault path, because other folders in the vault may hold same-named notes and a bare `[[Proposed]]` can resolve to the wrong one. Write `[[Workflow/Proposed#…]]`, `![[Workflow/Waiting For#…]]`, `[[Workflow/Tasks]]`, never `[[Proposed]]`. This includes the ID links in Proposed.

Every Jira key you write into any vault file (briefing, Dashboard blocks, Waiting For, Tasks, workstream bodies) is a markdown link: `[KEY-123](https://jira.example.com/browse/KEY-123)`. Deployment slot keys too, if your Jira has them. Never link inside frontmatter; the `tickets` list stays plain keys because Board.base builds its own links from them.

## Step 0: apply what the user ticked

Read Proposed. For every ticked (`- [x]`) item under `## Fix my board`, apply the change in its `<!-- op: … -->` comment exactly (see "Proposed format"). Then move the line to the top of `## Applied`, prefixed with today's date. If an op no longer applies cleanly (note renamed, field already has that value), move it to Applied anyway with `(skipped: <reason>)`. Leave ticked items under `## Draft Jira comments` alone; `/apply` handles them. Whenever an item leaves the open sections (applied, skipped, or expired), delete its `### <ID>` block under `## Details`. Delete lines in `## Applied` older than 14 days.

## Step 1: read everything before writing anything

1. Every Workstreams note (frontmatter is enough), Waiting, Inbox, Tasks.
2. The most recent Daily file for carry-over. If none, skip carry-over.
3. Jira `search_issues`, `maxResults: 100` each:
   - **mine**: `assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC, updated DESC`
   - **waiting**: `reporter = currentUser() AND assignee != currentUser() AND assignee is not EMPTY AND resolution = Unresolved ORDER BY updated ASC`
   - **orphans**: `reporter = currentUser() AND assignee is EMPTY AND resolution = Unresolved ORDER BY priority DESC, created ASC` (if an automation files tickets under your name, add `AND (labels is EMPTY OR labels not in (<its labels>))`)
   - **my turn**: `reporter = currentUser() AND assignee != currentUser() AND status = "Under Review" AND resolution = Unresolved`
   - **changed**: `(assignee = currentUser() OR reporter = currentUser() OR watcher = currentUser()) AND updated >= -1d ORDER BY updated DESC` (use `-3d` on a Monday)
   - **due**: `(assignee = currentUser() OR reporter = currentUser() OR watcher = currentUser()) AND resolution = Unresolved AND due >= startOfDay() AND due <= 14d ORDER BY due ASC`
   - **activity**: `key in (<every key from every Workstreams note's tickets list>) ORDER BY updated DESC`. Only the updated date per key is needed.
4. Jira `list_deployment_slots` (default window), if your Jira has deployment bookings; otherwise skip. Keep reserved slots whose reserving ticket is on any workstream's `tickets` list, or whose project key is one of <your project keys>.

5. Team (for Step 3c). Read Team settings first.
   - Jira `get_board` <BOARD_ID> with state `active`, then `future`, then `closed`. Take the active sprint, the next future sprint if any, and the three most recent closed sprints.
   - Jira `get_sprint` for each of those (maxResults 200). These compact lists (key, title, status, assignee) are the only source for runway and focus. Do not count open tickets assigned outside the sprints: people carry dozens of stale sub-tasks and ops tickets that make raw counts meaningless.
   - **pool**: `assignee is EMPTY AND resolution = Unresolved AND (project = <TEAM_PROJECT> OR sprint = <active sprint id from get_board> OR key in (<every workstream ticket>)) ORDER BY priority DESC, updated DESC`, maxResults 60. These are the candidates for suggestions. Use the sprint id, never `openSprints()`: that reaches other teams' boards.
   If a team call fails, skip Step 3c, leave Team.md as it is, and say so in the briefing. It does not fail the run.

## Step 2: write `Daily/YYYY-MM-DD.md`

Under 60 lines. Every ticket reference carries the key. Sections in order:

1. **Today (max 3)**: "my turn" tickets first, then workstreams with status stalled or a High/Critical ticket, then carry-over. One line each with ticket key and workstream row.
2. **My turn to review**: the "my turn" query, or one line saying none.
3. **Nudge**: Waiting entries with no Jira update in 14+ days, plus any "waiting" ticket not yet in Waiting. One-sentence nudge each. Do not post it.
4. **Changed since yesterday**: status changes, reassignments, and updates by other people. Skip the user's own edits.
5. **Upcoming (14 days)**: deployment bookings from step 1.4, "due" tickets, workstreams whose `due` is within 14 days, and Tasks lines with a `📅` date within 14 days. One line each, date first.
6. **Inbox to triage**: each unchecked Inbox item with a destination: `→ Jira <PROJECT> (title)`, `→ workstream <name> next action`, `→ waiting for <who>`, `→ drop`.
7. **Drift**: tickets from mine / waiting / orphans on no workstream's `tickets` list; workstreams with last_touch 14+ days old or next_action "TBD"; Tasks in Next that look like they deserve a Jira ticket.
8. **Carry-over**: yesterday's Today items that do not look done.

## Step 3: refresh the generated parts (no approval needed; these are derived from Jira)

- Workstreams: for each note, set `last_touch` to the latest `updated` date among its tickets from the activity query, if that is later than the current value. Change no other field. This is derived data, like the tiles.

- Dashboard: for each of the four generated callouts, replace the whole nested block (the `> > [!type|span-N] Title` line plus every following line that starts with `> >`) with a new nested callout of the same type, same `|span-N`, and same title, every line prefixed `> > `, built from the sections above. Put the date in the Today title. Keep each tile short: at most 3 items in Today, 5 in the others; one line per item. Also update the `[[Workflow/Daily/YYYY-MM-DD|Today's briefing]]` link inside the `[!links|span-12]` tile to today's file. Touch nothing else in the file (the kanban, Tasks, Waiting, PR, Team and Board tiles are live embeds).
- Banner (last, after everything else in Steps 3–3c succeeded): read `VAULT/Refresh status.md`, then overwrite it with exactly one line, the time from `date '+%a %-d %b %H:%M'`:
  `> [!success] Refreshed <time> · [[Workflow/Daily/YYYY-MM-DD|today's briefing]] · [[Workflow/Proposed|Proposed]] · [[Workflow/PR reviews|PR reviews]]`
  Skip this if the run failed; the runner writes the failure banner.
- Waiting: rewrite the "My turn", "Nudge due" and "Waiting, fine" sections from the "waiting" and "my turn" queries (who, ticket, one-line title, last update). Leave "Not in Jira" untouched. Update the "Last generated" date.

## Step 3c: write Team.md (derived; no approval needed)

Classify every sprint ticket into one area using the Areas table in Team settings (first match wins). Then rewrite `VAULT/Team.md` completely, in plain words (no field names, no JQL), every Jira key a link:

```
# Team: <TEAM>

Generated by the morning refresh on YYYY-MM-DD from the <TEAM> board. Settings: [[Workflow/Team settings|Team settings]]. Read-only: nothing here is written to Jira.

## At a glance
- **Low on work:** <names with (n open)>, or "nobody"
- **All in one area (last 4 sprints):** <name: n% area>, or "nobody"
- **<Sprint name>:** <n> working days left · <n> done · <n> in progress or to do · <n> with no owner
- **Suggestions for planning:** <n> below

## Who has work
| Person | Open in sprint | Their open tickets | Main area, last 4 sprints | Flag |
(one row per Runway = yes person, then the user; Flag is "low on work", "all in one area", both, or blank)

## <Sprint name> (<start> to <end>)
- Done: n. In progress or to do: n. No owner: n (list them).
- In progress with no update for 7+ days: list, with owner and days idle.
- Added after the sprint started: list (created after the start date).

## Milestones
| Area | Milestone | Open | Done in last 4 sprints | No owner |
(from the sprint tickets and the pool; one row per area that has any tickets)

## Suggestions for sprint planning
For each flagged person, up to 3 tickets from the pool, chosen by the rule in Team settings. One line each:
- **Sam** (1 open, all front end) could take [APP-869](…): fix the SQL timeout in the report job. Why: app dev like their front-end work, High, in this sprint with no owner.
Never suggest the same ticket for two people. If nobody is flagged, write "Nobody is low on work or stuck in one area."

## Housekeeping
At most 3 lines: patterns that distort the numbers, e.g. a person carrying many open sub-tasks from a finished release. Suggest raising it at /weekly.
```

Working days exclude weekends. "Done" means status Resolved, Closed or Done.

## Step 3b: write proposals

Add to Proposed everything the user would otherwise have to decide or type by hand. Under `## Fix my board`:

- Each Inbox item's destination from Step 2.6 (tick the Inbox line; add a line to Tasks; set a workstream's `next_action` or `waiting_on`; create a new workstream note from `VAULT/Workstream Template.md` with the next free `row`).
- Each Drift ticket that fits a workstream: add it to that note's `tickets`.
- `next_action` for any workstream where it is "TBD", or where it names a ticket that is now resolved, or is clearly done by the Changed section. Propose one concrete next step, drawn from the workstream's open tickets.
- `status` for any workstream where the evidence is clear: every ticket resolved → `done`; no activity for 30+ days and nothing waiting → `stalled`; `waiting_on` set and the user's own tickets idle → `waiting`.

Under `## Draft Jira comments` (never performed here):

- One Jira comment per Nudge item, with the exact comment text (one or two plain sentences, addressed to the assignee by first name).

Rules: never propose something already in Proposed (compare the op comment, ignoring the ID). Never propose again an op that is in Applied or that expired in the last 7 days. Delete unticked items older than 7 days. Add at most 10 new items per section per run, strongest first; list the rest under Drift in the briefing. Never delete an open item except by the 7-day expiry.

## Proposed format

The first line under `## Fix my board` is always:

    *Tick = "yes, my board should say this." Applied at the next morning refresh. No task is created and nothing goes to Jira.*

and under `## Draft Jira comments` always:

    *Tick = "I want to send this." Nothing is posted until I run `/apply`, see the exact comment, and confirm.*

Keep both. Keep the heading text exactly as written: the Dashboard embeds these sections by name.

Each item is one line: a checkbox, the ID written as the link `[[Workflow/Proposed#<ID>|<ID>]]`, ` · `, a plain to-do, and a hidden op comment that Step 0 or `/apply` executes. Hovering the ID in Obsidian previews the item's block under `## Details`; all evidence, old values and ticket links go there, not on the line.

The to-do must be readable at a glance:

- Start with the row's short name and a colon ("Storage:", "Tomcat:", "Inbox:"), then say what changes in everyday words: "mark as done", "next step is …", "now waiting on …", "add a row: …", "rename the row to …". For Draft Jira comments, start with "Ask <first name> …".
- At most about 12 words. No field names (`next_action`, `waiting_on`, `status`), no arrows, no markdown links. A bare ticket number only when it is the point of the item.
- A short reason in brackets only when it makes the choice obvious: "(done 25 Sep)", "(no longer needed)".

Order `## Fix my board`: quick bookkeeping first (tick Tasks/Inbox lines, mark done, clear dates, add a ticket, change who I'm waiting on), then next-step changes, then renames and new rows.

```
- [ ] [[Workflow/Proposed#P0928-9|P0928-9]] · Tasks: tick off "Email the working group" (done 25 Sep) <!-- op: {"file":"Tasks.md","tick":"Email the working group"} -->
- [ ] [[Workflow/Proposed#P0928-2|P0928-2]] · Storage: next step is verifying 2.0.1 on TEST (old step is done) <!-- op: {"file":"Workstreams/Storage migration.md","set":{"next_action":"Verify document-api 2.0.1 on TEST and close APP-376 and APP-377"}} -->
- [ ] [[Workflow/Proposed#P0928-19|P0928-19]] · Add a row: Wiki migration <!-- op: {"newWorkstream":true,"name":"Wiki migration.md","set":{…},"body":"…"} -->
- [ ] [[Workflow/Proposed#P0928-11|P0928-11]] · Ask Sam if the 3 bugs from February are still real <!-- op: {"jira":"add_comment","key":"APP-253","body":"Hi Sam, …"} -->
```

For every item, add a block at the end of `## Details` (the last section of the file):

```
### P0928-1
**Row 11 · Tomcat: replace "TBD" with the next app**

- **Changes:** every field's old value → new value, quoted; tickets added. For a Jira write: the ticket, its assignee, and the full comment.
- **Why:** the evidence, with linked keys, statuses, dates, and who did what. Say what is stale and since when.
- **Tick if / Skip if:** when to accept it, and when to do something else instead.
- **Effect:** "Changes your Obsidian notes only, at the next morning refresh. Nothing goes to Jira." or "Queued for `/apply`; nothing posted until you confirm there".
```

The heading is the bare ID so the link resolves. Number new IDs after the highest `P<MMDD>-<n>` already used today anywhere in Proposed (open, Applied or Details), so a second run the same day never reuses an ID. Keep each block under 8 lines.

Ops: `set` (frontmatter fields; keep YAML valid and quoted), `addTicket`, `tick` (an Inbox or Tasks line by its text), `appendLine` (`{"file":…,"section":…,"text":…}`), `newWorkstream` (`{"name":…,"set":{…},"body":…}`; next free `row`), `rename` (`{"file":…,"rename":"New name.md"}`; also rewrite every link to it in VAULT, bare or path-qualified: `[[Old name]]`, `[[Old name|…]]`, `[[Workflow/Workstreams/Old name|…]]`), and for `/apply` only, `jira` with the MCP tool name and its arguments.

## Scheduled (non-interactive) runs

If the run was started with `--scheduled` (the scheduled job does this), nobody is watching. Then:

- Do Steps 1 to 3 exactly as written.
- Skip Step 4's question. Apply nothing except Step 0 (ticked items) and Step 3 (derived fields).
- End the briefing with one line: how many items are open in Proposed, linked as `[[Workflow/Proposed|Proposed]]`.
- If any Jira query fails (VPN down, auth expired), stop: leave the Dashboard and Waiting For exactly as they are, write the briefing with a `## Run failed` section naming the error, and say so in your final line. Never write a tile with empty or invented content.

## Step 4: report and ask once (interactive runs only)

Print the briefing in chat. Then ask one question (multi-select where the host supports it) listing the open `## Fix my board` items in Proposed by ID. Tick the chosen ones in Proposed and apply them as in Step 0. If the user picks nothing, change nothing. Remind the user that ticked `## Draft Jira comments` items wait for `/apply`.
