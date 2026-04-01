Pollard is an Elixir library for tracked, ordered, one-way data transformations in Ecto applications. It mirrors the Ecto migration system but for data, not schema.

## Project structure

- `lib/pollard.ex` — `use Pollard` macro and `transform` DSL
- `lib/pollard/runner.ex` — file discovery, advisory lock, execution loop
- `lib/pollard/schema.ex` — Ecto schema for the tracking table
- `lib/pollard/lock.ex` — lock behaviour
- `lib/pollard/lock/` — lock adapters (Postgres, None)
- `lib/mix/tasks/` — mix tasks (gen, run, gen.migration)

## Running checks

- `mise precommit` — format, compile (warnings-as-errors), then credo + tests in parallel
- `mise signoff` — runs precommit then `gh signoff test`
- `mise test` — run tests only
- `mise lint` — format check + credo strict

Always rebase on latest `main` before pushing a PR: `git fetch origin main && git rebase origin/main`

## Design principles

- **One-way only.** No `down`, no rollback. Fix-and-redeploy is the recovery path.
- **Idempotent by convention.** Transforms must be safe to re-run.
- **Database agnostic.** Core runs on any Ecto adapter. Locking is pluggable.
- **Data only.** No schema DSL, no DDL.

## Key conventions

- Transforms live in `priv/repo/transforms/` with timestamp-prefixed filenames
- Each `transform` block runs in its own database transaction
- Tracking is per-file, not per-block
- The tracking table is created via a host app migration, not auto-created
