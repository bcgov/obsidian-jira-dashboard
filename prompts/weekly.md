# /weekly

Thirty minutes on Friday. Goal: on Monday every workstream note has a true status and a next_action that is a real step. Read-only against Jira until the final approval step.

## Paths

Same as `/standup`. Output goes to `VAULT/Weekly/YYYY-Www.md` (ISO week, from `date +%G-W%V`).

## Links

Links to workflow notes always carry the vault path (`[[Workflow/Proposed#…]]`, `[[Workflow/Weekly/…]]`), never a bare `[[Proposed]]`.

Every Jira key you write into any vault file (briefing, Dashboard blocks, Waiting For, Tasks, workstream bodies) is a markdown link: `[KEY-123](https://jira.example.com/browse/KEY-123)`. Deployment slot keys too, if your Jira has them. Never link inside frontmatter; the `tickets` list stays plain keys because Board.base builds its own links from them.

## Step 1: gather

1. Every Workstreams note, Waiting, Inbox, Tasks, this week's Daily files.
2. Jira `search_issues`, `maxResults: 100`: the six `/standup` queries, plus
   - **week**: `(assignee = currentUser() OR reporter = currentUser()) AND (updated >= -7d OR resolved >= -7d) ORDER BY project, updated DESC`
   - **stale mine**: `assignee = currentUser() AND resolution = Unresolved AND updated <= -14d`
   - **stale waiting**: `reporter = currentUser() AND assignee != currentUser() AND resolution = Unresolved AND updated <= -14d`
   - **stale orphans**: `reporter = currentUser() AND assignee is EMPTY AND resolution = Unresolved AND created <= -30d` (same automation-label exclusion as `/standup`'s orphans query, if you use one)
3. Jira `list_deployment_slots` for the upcoming window, if your Jira has deployment bookings.

## Step 2: write `Weekly/YYYY-Www.md`

1. **Shipped this week**: resolved/closed tickets and merged work, one line each.
1a. **Status report draft**: 4–8 plain-language bullets for the user's manager, grouped by milestone or programme, written from Shipped plus notable progress (decisions made, deployments booked). No ticket jargon; one Jira link per bullet at most. Ready to paste.
2. **Workstreams, one by one**: a table with, per note: current status → proposed status, current next_action → proposed next_action, proposed last_touch, and a one-word reason (`moved`, `stalled`, `blocked`, `done`). A next_action unchanged from last week is `stalled` unless one of its tickets moved. Fully resolved workstreams are proposed as `done`.
3. **New workstreams**: tickets or repos that appeared this week and fit no note.
4. **Stale sweep**: stale mine / stale waiting / stale orphans, each with one proposed action: `nudge` (drafted comment), `reassign to me`, `close as won't do`, `close as duplicate of X`, `park`. Bugs filed by an automation (by label) grouped as one line with a count.
5. **Waiting For**: rows to remove (resolved), rows to add, rows needing a nudge.
6. **Inbox**: anything still unchecked, with a destination. Inbox should be empty after this step.
7. **Tasks**: ticked lines to move to Done; Later items to promote or drop; Next items older than three weeks with a proposal (Jira ticket, drop, or keep with a reason).
8. **Reminders app**: one line: if anything work-related is still in a reminders app, move it to Inbox or Tasks and delete it there.

## Step 3: approve and apply

Show the file in chat. Then ask, one question each, in this order:
1. Apply the workstream changes? (yes / edit first / no). If yes, edit each note's frontmatter (`status`, `next_action`, `last_touch`, `due`), append a dated line to its `## Log`, and move `done` notes' status to `done`.
2. Which stale-sweep actions to take? (multi-select).

Workstream / Waiting / Inbox edits are applied directly. For any approved Jira action (nudge comment, transition, reassign), list the exact calls first and ask for a final yes before making them; Jira writes are visible to the team.

## Scheduled runs

If the run was started with `--scheduled` (Friday mornings, by `bin/standup-daily.sh` after `/standup`), nobody is watching. Then:

- Do Steps 1 and 2 exactly as written. Write the Weekly file.
- Do not ask Step 3's questions. Instead, add to `VAULT/Proposed.md`, following the rules and line style in `/standup`'s "Proposed format" (read `prompts/standup.md` for it; IDs use today's date and continue after the highest number already used today; add a `### <ID>` details block for each):
  - under `## Fix my board`: each workstream change from Step 2.2 (one item per row: status and next step together), each new workstream from 2.3, and the Waiting For / Inbox / Tasks moves from 2.5–2.7.
  - under `## Draft Jira comments`: each `nudge` from the stale sweep, with the exact comment.
  - Never propose something already open in Proposed. The 10-new-items cap per section does not apply to this run.
- Every other stale-sweep action (close, reassign, park) changes Jira in ways a comment can't, so do not queue it. List it in the Weekly file under `## Jira clean-up for you to decide`, one line each with the link and the reason, for the user to do in Jira or in an interactive `/weekly`.
- End with one line: the Weekly file link and how many items were added to Proposed.
- If any Jira query fails, write the Weekly file with a `## Run failed` section and add nothing to Proposed.
