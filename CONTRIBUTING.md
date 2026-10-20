# How to Contribute

Government employees, members of the public, and the private sector are encouraged to contribute to this repository.

## Contribution licensing

Unless otherwise noted, you retain copyright in your contribution and agree that any contribution submitted for inclusion in this repository is provided under the same license terms that apply to this project. See [`LICENSE`](LICENSE) for details.

## How this repository is organised

- The four workflows live in `prompts/`. Edit those. The files in `.claude/commands/` and `.github/agents/` are thin adapters that only declare tools and point at a prompt.
- `AGENTS.md` holds the rules every agent follows. A change to a rule goes there, once.
- `vault/` holds skeleton notes. Keep them empty of real tickets, names and hosts.

## Workflow

1. Branch from a fresh `main`.
2. Make the change. If it touches a prompt, run that workflow once against a test vault and say what happened in the PR.
3. Before pushing, scan for secrets: `gitleaks dir .`
4. Open a pull request. Describe what changed for the person running the dashboard, not the diff.

## What not to contribute

Anything from a real vault or a real Jira: ticket keys, people, hostnames, board ids. The placeholders in the README are there so that nothing real is needed to read or test this repository.
