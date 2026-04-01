defmodule Pollard.Lock.None do
  @moduledoc """
  No-op lock strategy.

  Use this for single-node deployments or databases where concurrent deploys
  are not a concern (e.g. SQLite).

      Pollard.Runner.run(MyApp.Repo, path, lock: Pollard.Lock.None)

  """

  @behaviour Pollard.Lock

  @impl true
  def acquire(_repo, _opts), do: :ok

  @impl true
  def release(_repo, _opts), do: :ok
end
