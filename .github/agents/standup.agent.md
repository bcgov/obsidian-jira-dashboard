---
name: standup
description: 'Morning standup. Refreshes the Obsidian Dashboard from Jira, workstream notes and inbox. Read-only against Jira.'
tools: ['read', 'search', 'edit', 'jira/search_issues', 'jira/list_deployment_slots', 'jira/get_board', 'jira/get_sprint']
---

Read `prompts/standup.md` in this repository and follow it exactly. If the user's message contains `--scheduled`, treat the run as a scheduled, non-interactive run as that file describes. Never call any Jira tool that creates, updates, transitions or comments; this agent is read-only against Jira.
