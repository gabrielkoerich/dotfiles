# Development Guidelines

> This file contains generic agent recommendations. Project-specific guidelines should live in the project's `AGENTS.md` or `CLAUDE.md` file.

## General Principles

- **Use the right tool for the job** - Choose the appropriate language, framework, and tooling based on the problem domain
- **Produce clean, maintainable code** - Write code that future you will thank you for
- **Keep things simple** - Avoid over-engineering; three similar lines is better than a premature abstraction
- **Validate at boundaries** - Only validate user input and external API responses, trust internal code

## Language-Specific Guidelines

### Python
- Use `uv` for fast package management

### Rust
- Use `cargo` for package management
- Follow Rust idioms and use the borrow checker to your advantage

### Solana / Anchor
- Use `anchor` framework for smart contract development
- Use `avm` for Anchor version management
- Audit with `anchor-sealevel-attacks` and `solana-best-practices` skills before deploying. Create specific tests based on those skills.

### Node.js
- Use `nvm` for version management
- Prefer `bun` for modern JS/TS workflows

## Essential Tools

| Tool | Purpose |
|------|---------|
| `just` | Task runner |
| `git` | Version control |
| `gh` | GitHub interactions |
| `tmux` | Terminal management |
| `rg` | Fast recursive search |
| `qmd` | Local markdown search and knowledge management (use the `qmd` skill) 
| `orchestrator` | Manage and orchestrater task and delegate or worth with coding agents (codex, claude, opencode) |

## Useful Skills

| Skill | Description | Requirements |
|-------|-------------|--------------|
| anchor-sealevel-attacks | Audits Solana/Anchor programs for all 11 sealevel attack vectors. Use when auditing Solana smart contracts or reviewing Anchor programs for security. | See SKILL.md |
| apple-calendar | macOS Calendar.app integration (CRUD, search) | macOS |
| beancount-analytics | Analyze Beancount ledgers with reusable CLI reports and question-driven queries. Use when user asks for last month/last 12 months reports, spending breakdowns, savings trends, or direct finance questions from a .bean ledger. | python3, beancount |
| binance-prices | Real-time crypto prices from Binance public API | python3, curl |
| bird | X/Twitter access via bird CLI | [bird CLI](https://github.com/steipete/bird), Chrome |
| elevenlabs-voices | Voice synthesis with 18 personas, 32 languages | python3, `ELEVEN_API_KEY` |
| gh-issue-worktree | Manage Git worktrees for isolated development environments per GitHub issue. Use `gh issue develop` to register linked branches and `git worktree` for isolated directories. | See SKILL.md |
| gh-pr-polish | Generate high-signal PR titles and bodies from git history and changed files, then open PRs with gh CLI. | See SKILL.md |
| git-worktrees | Manage plain Git worktree feature branches without issue linking. Create a feature branch worktree, develop in isolation, push, and open a PR with commit-based changes summary. | See SKILL.md |
| github | GitHub CLI for issues, PRs, CI runs, and API queries | [gh CLI](https://cli.github.com) |
| github-secrets | Manage GitHub repo/org secrets via API | bun, `GITHUB_TOKEN` |
| notes-review | Analyze personal markdown notes and journals with qmd-powered semantic search plus weekly/monthly reflection reports. Use for questions like what was accomplished, what is pending, and whether work aligns with goals. |  python3, qmd CLI |
| openai-whisper| Local speech-to-text transcription | [whisper CLI](https://github.com/openai/whisper) |
| orchestrator | Thin operational wrapper for a system-wide orchestrator CLI. Use when running and checking `orchestrator <command>` workflows without duplicating orchestration logic in the skill. | See SKILL.md |
| qmd | Local hybrid search for markdown notes and docs | [qmd CLI](https://github.com/tobi/qmd) |
| solana-best-practices | Reviews Solana/Anchor programs for development best practices. Use when writing, reviewing, improving or auditing Solana smart contracts. 31 vulnerability patterns with 4 real-world case studies. | See SKILL.md |
| things3 | Things 3 task manager via CLI (macOS) | [things CLI](https://github.com/ossianhempel/things3-cli), macOS |
| tmux | Remote-control tmux sessions for interactive CLIs | tmux |
| worktree-janitor | Audit and clean git worktrees safely across repositories, including stale metadata and merged local branches. | See SKILL.md |
---

## Documentation

For markdown documents, notes, and knowledge management:
- Use the `qmd` skill for local search, semantic queries, and reflection reports
- Keep documentation close to code
- Update docs when code changes
- For github, use the `github` skill to manage issues, pull requests, and repositories. Use git-worktres for managing worktrees workflows and gh-issue-workktree for github issues related tasks.

## File Deletion

- **Never use `rm`** — it is denied in agent settings and shell aliases don't load in non-interactive shells
- Use `trash -F` instead (moves files to macOS Trash, recoverable)
- On Linux, use `trash-put` instead

## Security

- Use `age` for file encryption
- Audit secrets with `gitleaks` before committing
- Use pre-commit hooks for validation

## AI Assistance

- Use `claude-code`, `codex`, or `opencode` based on task requirements
- Be explicit about requirements with AI assistants
- Review AI-generated code before committing
