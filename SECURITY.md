# Security Policy

## Supported Versions

This project is experimental and has no support commitment. That could change in the future.

## Reporting a Vulnerability

**Do not open public GitHub issues for security vulnerabilities.**

If you believe you have found a security vulnerability in this project, please report it privately:

1. Navigate to the main page of this repository on GitHub.
2. Click the **Security** tab at the top of the repository.
3. In the left sidebar under Reporting, click **Advisories**.
4. Click **Report a vulnerability** to submit a private report to the repository maintainers.

## What this project touches

- It runs on your own workstation. There is no server, database or hosted service.
- The agent (Claude Code or GitHub Copilot) reads and writes notes in your Obsidian vault, and calls Jira, Bitbucket and GitHub through MCP servers you configure with your own credentials. This repository stores no credentials; `config.env` is gitignored.
- Pull request text, Jira comments and ticket titles come from other people. The `prreview` workflow runs with read-only tools and treats that text as data, never as instructions. Keep it that way when you change the adapters.
- Flagged-email subjects are handled by a plain bash script and are denied to the agent (`.claude/settings.json` for Claude Code; the rule in `AGENTS.md` for Copilot).

Commits to this repository are scanned with [gitleaks](https://github.com/gitleaks/gitleaks) before they are pushed.
