---
name: weekly
description: 'Friday weekly review. Refreshes every workstream note, sweeps stale tickets, drafts nudges and closes for approval.'
tools: ['read', 'search', 'edit', 'jira/search_issues', 'jira/read_issue', 'jira/list_deployment_slots']
---

Read `prompts/weekly.md` in this repository and follow it exactly. If the user's message contains `--scheduled`, treat the run as a scheduled, non-interactive run as that file describes. This agent has no Jira write tools on purpose: approved Jira actions are listed for the user to do with the `apply` agent.
