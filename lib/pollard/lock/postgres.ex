defmodule Pollard.Lock.Postgres do
  @moduledoc """
  Lock strategy using Postgres advisory locks.

  This is the recommended strategy for Postgres-backed applications. Advisory
  locks are lightweight — they don't hold any table or row locks — which is
  important because transforms can run for minutes on large datasets.

  ## Options

    * `:lock_key` - The integer key for the advisory lock. Defaults to `839_712_541`.

  """

  @behaviour Pollard.Lock

  @default_lock_key 839_712_541

  @impl true
  def acquire(repo, opts) do
    key = Keyword.get(opts, :lock_key, @default_lock_key)

    case repo.query("SELECT pg_try_advisory_lock($1)", [key], log: false) do
      {:ok, %{rows: [[true]]}} -> :ok
      {:ok, %{rows: [[false]]}} -> {:error, :locked}
    end
  end

  @impl true
  def release(repo, opts) do
    key = Keyword.get(opts, :lock_key, @default_lock_key)
    repo.query("SELECT pg_advisory_unlock($1)", [key], log: false)
    :ok
  end
end
