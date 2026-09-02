# Pollard

[![Hex.pm](https://img.shields.io/hexpm/v/pollard.svg)](https://hex.pm/packages/pollard)
[![Hexdocs](https://img.shields.io/badge/hexdocs-pollard-blue.svg)](https://hexdocs.pm/pollard)
[![License](https://img.shields.io/hexpm/l/pollard.svg)](https://github.com/LoamStudios/pollard/blob/main/LICENSE)

Tracked, ordered, one-way data transformations for Ecto applications. Mirrors the Ecto migration system — same conventions, same workflow — but for data, not schema.

## Installation

Add `pollard` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pollard, "~> 0.1.0"}
  ]
end
```

Then generate the tracking table migration:

```bash
mix pollard.gen.migration
mix ecto.migrate
```

## Usage

Generate a new transform:

```bash
mix pollard.gen backfill_shop_details
```

This creates a timestamped file in `priv/repo/transforms/`:

```elixir
defmodule MyApp.Transforms.BackfillShopDetails do
  use Pollard

  transform "Backfill missing shop details" do
    from(s in "shops", where: is_nil(s.details))
    |> MyApp.Repo.update_all(set: [details: %{}])
  end
end
```

Each `transform` block runs in its own database transaction. Use multiple blocks to break large operations into smaller transactions:

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

Run pending transforms:

```bash
mix pollard.run
```

## Idempotency

Transforms must be safe to re-run. If a file has three transform blocks and the second fails, blocks one and two will both execute on retry. Use `ON CONFLICT DO NOTHING`, `WHERE` clauses, upserts, and state checks.

## Locking

The runner acquires a lock before executing to prevent concurrent runs across nodes. The lock strategy is configurable:

```elixir
# Postgres advisory locks (default)
Pollard.Runner.run(MyApp.Repo, path)

# No locking (single-node / SQLite)
Pollard.Runner.run(MyApp.Repo, path, lock: Pollard.Lock.None)

# Custom lock implementation
Pollard.Runner.run(MyApp.Repo, path, lock: MyApp.Lock.Redis)
```

## Release Support

```elixir
defmodule MyApp.Release do
  def transform do
    Pollard.Runner.run(MyApp.Repo, transforms_path())
  end

  defp transforms_path do
    Application.app_dir(:my_app, "priv/repo/transforms")
  end
end
```

Deploy order:

```bash
bin/migrate      # schema migrations (Ecto)
bin/transform    # data transforms (Pollard)
bin/server       # start the application
```

## Documentation

Documentation is available at [HexDocs](https://hexdocs.pm/pollard).
