# How the system works

Jira holds tickets. It does not hold the two things that actually slip:

1. **What is my next step on each workstream.** With a dozen workstreams that list lives only in memory, so the quiet ones go silent for months.
2. **What I am waiting on from other people.** Nothing tracks it, so nobody nudges.

Free-form daily notes do not fix this, because capture without a review step just accumulates. The review has to happen without you starting it. So: Jira stays the system of record for anything the team can see. On top of it sits one thin personal layer in the Obsidian vault (`Workflow/`, synced to the phone), and an AI agent (Claude Code or GitHub Copilot) that runs the review workflows every morning so the reviewing actually happens.

## The pieces

| Piece | Holds | Never holds |
|---|---|---|
| **Jira** | Every team-visible work item, decision, deployment | Your private next steps, your nudges |
| **Dashboard** (`Workflow/Dashboard.md`) | One screen: today's top 3, your turn to review, nudges, the board, upcoming deployments, waiting-for, inbox | Anything typed by hand except the order of tiles |
| **Workstream notes** (`Workflow/Workstreams/`) | One note per workstream with properties: status, next action, who you are waiting on, tickets, last touch, due | Ticket details, analysis |
| **Board.base** | Live views over the workstream notes: Board, Needs attention, Due soon, Cards, Parked, All | Data (it only renders) |
| **Waiting For** | One line per thing you have asked of someone, with date; the Jira part regenerated daily | Things you are doing yourself |
| **Tasks** | Small non-Jira todos, one line each, optional workstream link and date | Anything that deserves a Jira ticket, or a workstream's next action |
| **Inbox** | Anything captured on the go that is not yet one of the above | Anything for more than a day |
| **Proposed** | The approval queue: checkboxes the refresh writes, you tick | Anything applied without a tick |
| **Your head** | Nothing | Everything |

The dashboard is native Obsidian: the core Bases plugin renders the workstream notes as filtered, sorted tables and cards with computed idle-days and status colours, embedded in the Dashboard note. No community plugin is required. It works on mobile.

### Workstream status

`moving`, `waiting` (on someone else), `stalled` (no next step or no activity), `parked` (deliberately not now), `done`. The Board view hides parked and done; the Needs attention view shows stalled, stale (no touch in 14 days) and `TBD` next actions.

### Rules for where something goes

- Someone asks you to do a thing: if it is real work, a Jira ticket assigned to you, then a workstream next action if it is the next step. If it is small and not ticket-worthy, do it now or add one line to Tasks.
- You ask someone for a thing: Waiting For, with the date. If it is on a ticket, the ticket key.
- A thought, a promise in a meeting, a "look into X": Inbox. Phone, watch, or Obsidian mobile. Do not sort it, just write it.
- You finish a next action: replace it in the workstream note immediately. `TBD` is allowed but Needs attention will keep showing it.
- A new workstream: copy `Workflow/Workstream Template.md` into `Workflow/Workstreams/`, or click New in the Board view.
- Phone or voice capture: an iOS Shortcut that appends to Inbox through the Obsidian URI: `obsidian://new?vault=<vault name>&file=Workflow%2FInbox&append=true&content=-%20%5B%20%5D%20<text>`.

## Cadence

**Every morning, 5 minutes, nothing to run.** launchd runs `/standup` every 30 minutes on weekday mornings (06:30 to 12:00) until it succeeds. It reads the workstream notes, Waiting For, Inbox, Jira and the deployment bookings; writes `Workflow/Daily/YYYY-MM-DD.md`; refreshes the Dashboard tiles, the Jira sections of Waiting For, and each workstream's `last_touch`; and writes everything you would otherwise have to decide into `Workflow/Proposed.md` as checkboxes. It is read-only against Jira. If the VPN is down or the Jira login has expired, the banner at the top of the Dashboard says so and names the fix. Your part: open the Dashboard, work the Today tile, tick the proposals you agree with. Ticked board changes apply at the next refresh; ticked Jira comments wait for `/apply`, which shows the exact calls and asks first.

**Every Friday, 15 minutes, nothing to run.** After the morning refresh, the same job runs `/weekly`. It writes `Workflow/Weekly/YYYY-Www.md`: what shipped, a paste-ready status report draft, a workstream-by-workstream review, a stale-ticket sweep, and a "Jira clean-up for you to decide" list (closes, reassigns, parks). Workstream changes land in Proposed under **Fix my board**, and nudges under **Draft Jira comments**, same as the daily ones. Run `/weekly` yourself if you would rather go through it in chat.

**PR reviews, every morning.** After the refresh, `/prreview` checks the repos listed in `Workflow/Team settings.md` (and GitHub review requests) for PRs where you are a pending reviewer, and writes a first-pass review draft for each into `Workflow/Reviews/`. The Dashboard tile "PRs waiting on my review" links them. Drafts only: nothing is posted. It runs with read-only Bitbucket and GitHub tools, because PR text is written by others.

**Team view, every morning.** `Workflow/Team.md`: who is low on sprint work, who has been in one area for four sprints, sprint health, milestone backlog, and read-only suggestions for sprint planning. Settings in `Workflow/Team settings.md`. This is a judgment about colleagues' workloads; keep the note private and treat the suggestions as a starting point for a conversation, not a verdict.

**When you have a spare minute.** Open Inbox on your phone and dump. That is it.

## First week

1. Open `Workflow/Dashboard.md` and turn on the `dashboard` CSS snippet. Create a workstream note for each thing you are responsible for; write one line of next action in each, `TBD` if you do not know yet.
2. Run `/standup`. Read the briefing. Tick the proposals you agree with.
3. Friday: run `/weekly`. Expect the stale sweep to propose closing or nudging about a dozen tickets. Decide.
4. Next Monday: if the board still feels true, the system works. If a tile is never used, delete it.

## Known gaps

- **Calendar.** Not wired in. If your work account is in macOS Calendar, `/standup` could include today's meetings.
- **Apple Reminders.** Scripting access from a launchd job needs an automation permission that is awkward to grant; the weekly review just reminds you to drain it by hand.
- **Open on launch.** Obsidian has no built-in "open this note at startup". The community plugin Homepage does that; otherwise pin the Dashboard tab.

## To undo

Delete `Workflow/` and `.obsidian/snippets/dashboard.css` from the vault, unload the launchd job, and delete this repository. Nothing in Jira was changed by the daily refresh.
