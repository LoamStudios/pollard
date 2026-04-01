---
name: pull-request
description: Create pull requests using `gh` that tell the story of a change. Use when the user invokes /pull-request or asks to create a PR. Summarizes the what and why.
---

# Pull Request

Create a pull request that tells the story of the change.

## Workflow

1. Run `git status` to check for uncommitted changes
2. If there are uncommitted changes, use the **commit skill** to commit them first —
   follow all its rules for granularity, ordering, and formatting
3. Run `git log main..HEAD --oneline` and `git diff main...HEAD` to review the full branch
4. If the reason for the change isn't clear from the diff and commit history, ask the user for context
5. Determine the PR title and write the body
6. Push the branch and create the PR with `gh pr create`

## PR Title

Use the same format as commit messages:

```
type(scope): subject
```

- Same types and scopes as commits (feat, fix, refactor, etc.)
- Maximum 50 characters
- Imperative mood, capitalized, no trailing period

## PR Body

Tell the story of the change: what it does and why it was made. Keep it concise — the diff has the details.

Do not hard-wrap PR body text. Write normal flowing prose — let GitHub handle line wrapping.

```markdown
## What

Brief description of the change (2-4 sentences). Focus on what the user or system experiences differently.

## Why

Motivation for the change. Link to issues, user feedback, or business context as applicable.
```

## Creating the PR

```bash
gh pr create --title "type(scope): subject" --body "$(cat <<'EOF'
## What

...

## Why

...
EOF
)"
```

- Always create PRs against `main` unless told otherwise
- Push the branch first if it hasn't been pushed yet: `git push -u origin HEAD`

## Reformatting an existing PR

When asked to reformat, clean up, or "match our PR format" on an existing PR:

1. Run `git log main..HEAD --oneline` to see the current commits
2. Run `git diff main...HEAD` to understand the full changeset
3. Reset all commits back to staged changes: `git reset --soft main`
4. Use the **commit skill** to re-commit everything from scratch —
   proper granularity, proper ordering, proper messages
5. Update the PR title and body to match the format above
6. Force push: `git push --force-with-lease`
7. Update the PR with `gh pr edit` if the title or body changed

## Examples

Simple PR:
```
fix(runner): Stop execution on first failed transform

## What

When a transform block fails, the runner now halts immediately instead of continuing to the next file. The failed file's version is not recorded, so it retries on the next run.

## Why

Continuing after a failure could leave data in an inconsistent state if later transforms depend on earlier ones.
```

Multi-scope PR:
```
feat(lock): Add MySQL advisory lock adapter

## What

New `Pollard.Lock.MySQL` module using GET_LOCK/RELEASE_LOCK for MySQL-backed applications. Configurable lock name and timeout via options.

## Why

Pollard's locking was Postgres-only. This makes it usable for teams on MySQL without requiring a custom lock implementation.
```
