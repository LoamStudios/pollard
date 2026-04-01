# Pollard

Pollard provides tracked, ordered, one-way data transformations for Ecto. It mirrors the Ecto migration system but for data, not schema.

## Key concepts

- **Transforms are one-way.** There is no `down`, no rollback. The fix-and-redeploy cycle is the recovery path.
- **Transforms must be idempotent.** Use `ON CONFLICT DO NOTHING`, `WHERE` clauses for unprocessed rows, upserts, and state checks. If a file has three transform blocks and the second fails, blocks one and two re-execute on retry.
- **Each `transform` block is its own transaction.** Multiple blocks per file break work into smaller transactions to avoid long-held locks.
- **Tracking is per-file, not per-block.** The version is recorded only after all blocks in a file succeed.

## Writing transforms

```elixir
defmodule MyApp.Transforms.BackfillShopDetails do
  use Pollard

  transform "Backfill missing shop details" do
    from(s in "shops", where: is_nil(s.details))
    |> MyApp.Repo.update_all(set: [details: %{}])
  end
end
```

Multiple blocks for smaller transactions:

```elixir
defmodule MyApp.Transforms.SeedResourceTypes do
  use Pollard

  transform "Seed productvariant type" do
    MyApp.Repo.insert_all("resource_types", [
      %{name: "productvariant", inserted_at: DateTime.utc_now()}
    ], on_conflict: :nothing)
  end

  transform "Seed metafield type" do
    MyApp.Repo.insert_all("resource_types", [
      %{name: "metafield", inserted_at: DateTime.utc_now()}
    ], on_conflict: :nothing)
  end
end
```

## File convention

Transforms live in `priv/repo/transforms/` with timestamp-prefixed filenames:

```
priv/repo/transforms/
  20260401000000_backfill_shop_details.exs
  20260401000001_seed_resource_types.exs
```

Generate with: `mix pollard.gen name_of_transform`

## Setup

1. Generate the tracking table migration: `mix pollard.gen.migration`
2. Run `mix ecto.migrate`
3. Run transforms: `mix pollard.run`

## Runner options

```elixir
Pollard.Runner.run(MyApp.Repo, path,
  migration_source: "transforms",    # tracking table name (default: "transforms")
  lock: Pollard.Lock.Postgres,       # lock strategy (default)
  log: true                          # log to stdout (default: true)
)
```

Lock strategies: `Pollard.Lock.Postgres` (advisory locks, default), `Pollard.Lock.None` (no-op for single-node/SQLite), or any module implementing `Pollard.Lock`.

## Deploy order

Transforms run after schema migrations (they may depend on new columns) and before the application starts (the app may depend on seeded data):

```
bin/migrate    # schema migrations
bin/transform  # data transforms (Pollard)
bin/server     # start app
```

## Common mistakes to avoid

- Do not use DDL or schema changes in transforms. This is for data only.
- Do not assume a transform runs exactly once within a file. Earlier blocks re-execute if a later block fails.
- Do not skip idempotency. Always use conflict handling, WHERE guards, or upserts.
