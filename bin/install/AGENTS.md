
# Agent Guidelines

> This file contains generic agent recommendations. Project-specific guidelines should live in the project's `AGENTS.md` or `CLAUDE.md` file.

## General Principles

- **Use the right tool for the job** - Choose the appropriate language, framework, and tooling based on the problem domain
- **Produce clean, maintainable code** - Write code that future you will thank you for
- **Keep things simple** - Avoid over-engineering; three similar lines is better than a premature abstraction
- **Validate at boundaries** - Only validate user input and external API responses, trust internal code

## Language-Specific Guidelines

### Python
- Use `uv` for fast package management

### Node.js
- Use `nvm` for node version management
- Before running any command, check for the project setup:
    - If the project has a `yarn.lock`, you should use `yarn`.
    - If it has a `package-lock.json`, you should use `npm`.
    - If it has a `bun.lock`, you should use `bun`
- Prefer `bun` for modern JS/TS workflows, specially on new projects.

### Rust
- Use `cargo` for package management
- Follow Rust idioms and use the borrow checker to your advantage

### Solana / Anchor
- Use `anchor` framework for smart contract development
- Use `avm` for Anchor version management
- Audit with `anchor-sealevel-attacks` and `solana-best-practices` skills before deploying. Create specific tests based on those skills.

## EVM / Solidity
- Use `hardhat` framework
- Audit with `evm-contract-audit` skills before deploying. Create specific tests based on those skills.

## Essential Tools

| Tool | Purpose |
|------|---------|
| `just` | Task runner |
| `git` | Version control |
| `gh` | GitHub interactions |
| `tmux` | Terminal management |
| `rg` | Fast recursive search, use it instead of `grep` |
| `qmd` | Local markdown search and knowledge management (use the `qmd` skill)
| `orch` | Manage and orchestrate tasks and delegate to coding agents (codex, claude, opencode) |

## Documentation

For markdown documents, notes, and knowledge management:
- Use the `qmd` skill for local search, semantic queries, and reflection reports
- Keep documentation close to code, update docs when code changes
- For github, use `github` skill to manage issues, pull requests, and repositories. Use `git-worktres` for managing worktrees workflows and `gh-issue-worktree` for github issues related tasks - it auto creates the link between the PR/worktree and the Github Issue.

## Writing Style

Use ASD-STE100 Simplified Technical English, key rules: 

- Use one word for one idea. Do not use two words for the same thing.
- Write short sentences. Use 20 words or less for instructions.
- Use active voice. Write "Turn the switch", not "The switch must be turned".
- Write short paragraphs. Keep one topic in each paragraph.

Write clear sentences, DO NOT use paraprosdokians and avoid using dashes. Follow the four principles of quality writing: simplicity, brevity, clarity and humanity.

## Commenting on code

Keep comments to one line. No trailing dot. Use commas instead of ';'. Don't use '—' or ' - ' as an aside separator, use commas or split lines. If deeper context is needed, put it in the PR/commit message, not the code. Only comment when the "why" is non-obvious. Don't restate what the code does.

## File Deletion

Deletion must be recoverable. `trash` moves to macOS Trash, everything below does not.

- **Never use `rm`** — it is denied in agent settings and shell aliases don't load in non-interactive shells
- Use `trash` instead (moves files to macOS Trash, recoverable)
- On Linux, use `trash-put` instead
- **Prefer using `rg` instead of `grep`**

Also denied, since they bypass the `rm` rule:

| Denied | Use instead |
|--------|-------------|
| `rmdir` | `trash` (handles empty dirs) |
| `find … -delete`, `find … -exec rm` | `find` to list, pipe the paths to `trash` |
| `shred` | `trash`, or `age` if the goal is secrecy |

These prompt before running, they destroy uncommitted work rather than files:

| Prompts | Use instead |
|---------|-------------|
| `git clean -f/-d/-x` | `git clean -n` to list, then `trash` those paths |
| `git reset --hard` | `git stash` (keeps the work, still gives a clean tree) |
| `git checkout -- `, `git restore` | `git stash` |

## Security

- Use `age` for file encryption
- Audit secrets with `gitleaks` before committing
- Use pre-commit hooks for validation
- Credential paths are read-denied in agent settings: including `~/.ssh`, `~/.gnupg`, `.env*` (except `.env.example`), `*.pem`, `*.key`, `*.agekey`
- Those rules gate the agent's file-read tool, not the shell. Don't work around them by `cat`-ing a credential file into context
- Give agents scoped credentials, a fine-grained token for one repo, never the main `gh auth` session

## AI Assistance

- Use `claude-code`, `codex`, or `opencode` based on task requirements
- Be explicit about requirements with AI assistants
- Review AI-generated code before committing
