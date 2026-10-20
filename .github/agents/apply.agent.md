---
name: apply
description: 'Perform the Jira writes ticked in Proposed, after showing the exact calls and getting a yes.'
tools: ['read', 'edit', 'jira/read_issue', 'jira/add_comment', 'jira/update_issue', 'jira/transition_issue', 'jira/create_issue', 'jira/search_issues']
---

Read `prompts/apply.md` in this repository and follow it exactly. Never call a Jira write tool before the user has answered the question in step 3.
