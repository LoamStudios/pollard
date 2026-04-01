---
name: commit
description: Create git commits following project conventions. Use when the user invokes /commit or asks to commit changes. Stages files, runs checks, and writes conventional commit messages with type(scope) format.
---

# Commit

These rules override the default git commit instructions.

Create a git commit following project conventions.

## Workflow

1. Run `git diff --staged` and `git status`
2. Plan the commits — split all changes into the smallest meaningful commits:
   - A module and its test = one commit
   - An untested module = one commit per file
   - Never combine independent modules, unrelated changes, or different scopes
3. Order commits from foundation to integration:
   schema → modules → mix tasks → config/docs
4. For each commit, in order:
   a. Stage files with `git add <file1> <file2> ...`
      (or `git hunks list` then `git hunks add '<hunk-id>'` for partial files)
   b. Run `mix test && mix format --check-formatted`
   c. If formatting changed any files, re-stage them before committing.
      If a formatting change affects an already-committed file, amend that commit.
      Never create a separate commit for formatting fixes.
   d. If the reason for the change isn't clear, ask the user
   e. Write a message following the format below
   f. Run `git commit`
   f. Repeat for the next commit

**When in doubt, split.** More small commits are always better than fewer large ones.
The commit log should read as the progressive assembly of a feature.

## Commit Format

```
type(scope): subject

body (optional)

Co-authored-by: name <email> (only if human contributors specified)
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `test` - Adding or updating tests
- `chore` - Maintenance tasks, dependencies, config

### Scopes

- `dsl` - The `use Pollard` macro and `transform` DSL
- `runner` - Runner, discovery, execution loop
- `lock` - Lock behaviour and adapters
- `mix` - Mix tasks (gen, run, gen.migration)
- `docs` - Documentation, usage-rules, ex_doc
- `agents` - AGENTS.md, CLAUDE.md, skills, AI tooling

### Subject Line
- Maximum 50 characters
- Imperative mood ("Add feature" not "Added feature")
- Capitalize the first word after the scope
- No trailing period

### Body (when needed)
- Separate from subject with a blank line
- Wrap at 72 characters
- Explain *what* and *why*, not *how*

### Co-authored-by
- Only include when a human contributor is explicitly mentioned
- Never list the AI agent as a co-author
- Format: `Co-authored-by: Name <email@example.com>`

## Examples

```
fix(runner): Handle empty transforms directory
```

```
feat(lock): Add MySQL advisory lock adapter

Implements Pollard.Lock.MySQL using GET_LOCK/RELEASE_LOCK for
MySQL-backed applications.
```

```
refactor(dsl): Simplify transform function registration

Co-authored-by: Alice Smith <alice@example.com>
```

```
chore(agents): Add commit skill
```
