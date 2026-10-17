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
- Always use braces on `if`, `else`, `for` and `while`, with the body on its own line. No one-liners like `if (x) return y`, including for `throw` and `continue`. Leave a blank line after the closing brace when another statement follows (not before `else`, `catch` or another `}`).

### Rust
- Use `cargo` for package management
- Follow Rust idioms and use the borrow checker to your advantage

### Solana / Anchor
- Use `anchor` framework for smart contract development
- Use `avm` for Anchor version management
- Audit with `anchor-security-audit` and `solana-best-practices` skills before deploying. Create specific tests based on those skills.

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
- For github, use `github` skill to manage issues, pull requests, and repositories. Use `git-worktrees` for managing worktrees workflows and `github-issue-worktree` for github issues related tasks, it auto creates the link between the PR/worktree and the Github Issue.

## Writing Style

Write for an experienced developer. Do not explain what they already know and do not hand-hold.

Use ASD-STE100 Simplified Technical English, key rules: 

- Use one word for one idea. Do not use two words for the same thing.
- Write short sentences. Use 20 words or less for instructions.
- Use active voice. Write "Turn the switch", not "The switch must be turned".
- Write short paragraphs. Keep one topic in each paragraph.

Write clear sentences, DO NOT use paraprosdokians and avoid using dashes. Follow the four principles of quality writing: simplicity, brevity, clarity and humanity.

Cut balanced contrasts used for rhythm. "It costs latency, not correctness" and "a guard, not a boundary" state one fact and then decorate it. Keep the fact, delete the decoration. A contrast is fine where it removes a real ambiguity, as in "a balance is a record, not a number".

Use the plain word. Write like a person talking, not like a brochure. Say use, not leverage or utilize. Say many, not a myriad or a plethora. Say also, not furthermore or moreover. Say main, not paramount. Say show, not showcase. Cut seamless, robust, holistic, cutting-edge, state-of-the-art, game-changer, synergy, delve and endeavor. If a shorter everyday word carries the meaning, it is the right word.

The test is whether people use the word when they talk. Everyday speech is the standard. Legal and official documents are the counterexample: that register exists because contracts and judgments need it, and a blog post does not. Technical terms pass, because that is how engineers talk to each other, and so does any word that maps straight across from Portuguese, like indistinguishable. What fails is the word that only ever appears in writing, and the literary flourish: calling a class of bug a species, or writing that an interface was showing me my own optimism.

Say each thing once. If an idea is already in the document, reference it, do not restate it in other words. Two passages that agree are one too many.

Cut throat-clearing. "It is worth noting", "it is worth stating", "this is not arbitrary" carry no information. Delete the phrase and state the fact.

Do not close a paragraph with an aphorism. A flourish reads as filler and buries the point.

## Markdown files

Never hard-wrap a `.md` file. This covers docs, READMEs, `AGENTS.md`, `CLAUDE.md`, plans, notes, and PR and issue bodies.

- A paragraph is one line, however long. A blank line separates paragraphs.
- Do not break a sentence or a list item at 80 characters or at any other column.
- When you edit a hard-wrapped paragraph, join it into one line.
- Line breaks go only between paragraphs, list items, table rows and headings, and inside code blocks.

Hard wrapping makes diffs worse: changing one word reflows the whole block, so a one-word edit reads as a rewrite. Editors wrap for display anyway. The column limit belongs to code.

## Documentation

A technical document answers three things, then stops: what it is, why it was built that way, and what that cost. Everything else is padding.

- One line per decision. The reader asks if they want more.
- Name the rejected alternative. A decision without one is an assertion.
- State costs plainly. Do not soften them or dramatise them.
- Keep reference material in tables and lists. Prose is for reasoning.
- Verify every claim against the code before writing it. A doc that contradicts the code is worse than no doc.
- Split by purpose: what it is and how to run it, why it is built this way, how to operate it.

## Commenting on code

Only comment when the "why" is non-obvious, and don't restate what the code does. Deeper context goes in the PR or commit message.

Line comments (`//`, `#`, `--`) get one line, or two when one cannot carry it. Never three. Use commas instead of `;`, and never `—` or ` - ` as an aside separator. The last sentence of any comment ends with no punctuation, including in a docblock.

A docblock is for what cannot be understood by reading the code: a protocol quirk, an ordering the type system cannot express, a bug the shape of the code works around. Design and decisions go in the design doc. Use one rarely, never for a thought that fits on one line, and never to get around the two-line limit. Python uses a docstring. Everywhere else, `/**` goes alone on the first line, every text line starts with ` * ` and wraps at the code's line width, and `**/` goes alone on the last line:

```rust
/**
 * Every freed block is wiped before the system allocator gets it back. Decrypting, parsing JSON
 * and decoding keys all pass plaintext through buffers owned by age, serde_json and std, which free
 * them without wiping, so wiping at the one place every free goes through catches all of them.
 * The default `realloc` frees through `dealloc`, so a buffer that grows is wiped too
 **/
struct WipeOnFree;
```

## Git worktrees

Create worktrees with `git cow add -b <branch> [<path>]`, from the `git-cow` crate. It clones `target/`, `node_modules` and other build output from an extra checkout of the repository, so a new worktree takes almost no disk and its first build is fast. Without a path it uses `~/.worktrees/<project>/<branch>`. Run `git cow warm <path>` before removing a merged worktree, so the next one starts with its build output. Claude Code's worktrees in `<project>/.claude/worktrees` go through git cow by the `WorktreeCreate` hook, and the `git-worktrees` and `github-issue-worktree` skills use it too.

## Commits and pull requests

Subject line only. No body, no description paragraph, no bullet list of what changed. `git commit -m "Short subject"` and nothing else. No trailer, and no agent is named nowhere in the commit. Pull request descriptions, comments and reviews carry no attribution either: no "Generated with ..." line, no co-author line.

The reasoning goes in the docs, not the commit. If a change needs explaining, the explanation belongs in `docs/DESIGN.md` or the equivalent, where it can be kept current.

`~/.claude/hooks/prose-check.py` enforces the comment, commit and pull request rules in Claude Code. Other agents must follow them unaided.

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
