# /apply

Carry out the ticked items under `## Draft Jira comments` in `/Users/YOUR_USER/Documents/Obsidian Vault/Workflow/Proposed.md`. This is the only command in this system that writes to Jira.

1. Read Proposed. Collect every ticked (`- [x]`) line under `## Draft Jira comments` and parse its `<!-- op: … -->` comment. Ignore unticked lines. If nothing is ticked, say so and stop.
2. For each item, Jira `read_issue` the key to confirm it still exists and the op still makes sense (for example, a nudge on a ticket that has since been updated or resolved no longer does). Mark those items "stale" instead of calling them.
3. Print a numbered table: ID, tool, key, and the exact arguments (full comment text, full field values). Then ask one question: apply all, choose which, or none. Never call a write tool before this answer.
4. Call the approved tools one at a time. If one fails, stop and report; do not retry.
5. In Proposed, move each item to the top of `## Applied` prefixed with today's date and `done`, `failed: <error>`, `stale` or `declined`, and delete its `### <ID>` block under `## Details`.

Every Jira key written into Proposed stays a link to `https://jira.example.com/browse/KEY`.
