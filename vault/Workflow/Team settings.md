# Team settings

Hand-edited. The morning refresh reads this note to build [[Workflow/Team|Team]]. Change a row here and the next refresh uses it.

## People

Only rows with **Runway = yes** are checked for "low on work". Skills are matched against the planning suggestions, so keep them honest.

| Person | Jira username | Role | Runway | Skills (for suggestions) |
|---|---|---|---|---|
| Sam Example | SEXAMPLE | Developer | yes | Java app dev; bug fixing |
| Alex Example | AEXAMPLE | Developer / ops | yes | Deployments and runbooks; servers and proxies |
| You | currentUser() | Lead | no | — |

## Rules

- **Low on work:** fewer than **3** open tickets in the current sprint plus the next sprint (board <BOARD_ID>).
- **Stuck in one area:** **80%** or more of their tickets in the last four sprints (current + three closed) fall in one area.
- **Suggestions:** for each person flagged above, up to 3 tickets that have no owner, preferring: in the current sprint → High priority → a different area from their usual one → a match to their skills.

## Areas

A ticket goes in the first area that matches, top to bottom. Milestone numbers are from your roadmap.

| Area | Milestone | Matches when |
|---|---|---|
| API gateway | M1 | project GATE; or title mentions gateway, routing |
| Document storage | M2 | project DOCS; or title mentions object storage, migration |
| Front end | M3 | project WEB; or title mentions React, map, UI |
| Tomcat / JDK | — | title mentions Tomcat, JDK |
| Other | — | anything else |

## Repos to watch for PRs

The morning refresh checks these Bitbucket repos for PRs where you're a pending reviewer, and writes a review draft for each into [[Workflow/PR reviews|PR reviews]]. GitHub review requests are found automatically, with no list needed. Add a row for any repo the team works in; the project key and repo name are in the Bitbucket URL (`/projects/<KEY>/repos/<repo>`).

| Project key | Repo | Why |
|---|---|---|
| GATE | gateway-config | Routing config |
| DOCS | document-api | Document API |
