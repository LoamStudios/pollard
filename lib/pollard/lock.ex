defmodule Pollard.Lock do
  @moduledoc """
  Behaviour for acquiring and releasing locks around transform execution.

  Pollard uses a lock to prevent concurrent transform runs across nodes in a
  cluster. The lock strategy is configurable via the `:lock` option on
  `Pollard.Runner.run/3`.

  ## Built-in implementations

    * `Pollard.Lock.Postgres` - Uses Postgres advisory locks. Recommended for
      Postgres-backed applications.
    * `Pollard.Lock.None` - No-op lock. Use for single-node deployments or
      databases where concurrent deploys are not a concern (e.g. SQLite).

  ## Custom implementations

      defmodule MyApp.Lock.Redis do
        @behaviour Pollard.Lock

        @impl true
        def acquire(repo, opts) do
          # acquire a distributed lock
          :ok
        end

        @impl true
        def release(repo, opts) do
          :ok
        end
      end

  Then pass it as an option:

      Pollard.Runner.run(MyApp.Repo, path, lock: MyApp.Lock.Redis)

  """

  @doc """
  Attempt to acquire the lock.

  Returns `:ok` if the lock was acquired, or `{:error, :locked}` if another
  runner already holds it.
  """
  @callback acquire(repo :: module(), opts :: keyword()) :: :ok | {:error, :locked}

  @doc """
  Release a previously acquired lock.
  """
  @callback release(repo :: module(), opts :: keyword()) :: :ok
end
