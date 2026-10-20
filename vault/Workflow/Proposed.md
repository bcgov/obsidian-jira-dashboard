# Proposed

The morning refresh compares your workstream notes with Jira and suggests fixes. Two kinds:

- **Fix my board**: a workstream note is out of date (wrong status, stale next step, missing ticket). Tick = "yes, my board should say this". The note is corrected at the next morning refresh. No task is created and nothing goes to Jira.
- **Draft Jira comments**: a nudge to someone on a ticket. Tick = "I want to send this". Nothing is posted until you run the `apply` workflow in your agent, see the exact comment and ticket, and confirm.

Unticked items expire after 7 days. Hover an ID to see the evidence.

## Fix my board

*Tick = "yes, my board should say this." Applied at the next morning refresh. No task is created and nothing goes to Jira.*

## Draft Jira comments

*Tick = "I want to send this." Nothing is posted until I run `/apply`, see the exact comment, and confirm.*

## Applied

## Details
