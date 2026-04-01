defmodule Pollard.Runner do
  @moduledoc """
  Discovers and executes pending data transforms.

  The runner acquires a lock (to prevent concurrent execution), discovers
  transform files, checks which have already been applied, and executes
  pending ones in version order. Each `transform` block within a file runs
  in its own database transaction.

  ## Options

    * `:migration_source` - Name of the tracking table. Defaults to `"transforms"`.
    * `:lock` - Lock module implementing `Pollard.Lock`. Defaults to `Pollard.Lock.Postgres`.
    * `:log` - Whether to log transform execution. Defaults to `true`.

  Any extra options are forwarded to the lock module's `acquire/2` and
  `release/2` callbacks.
  """

  require Logger

  @default_source "transforms"
  @default_lock Pollard.Lock.Postgres

  @doc """
  Run all pending transforms found at `path` against `repo`.

      Pollard.Runner.run(MyApp.Repo, "priv/repo/transforms")

  """
  def run(repo, path, opts \\ []) do
    source = Keyword.get(opts, :migration_source, @default_source)
    lock_mod = Keyword.get(opts, :lock, @default_lock)
    log? = Keyword.get(opts, :log, true)

    with_lock(repo, lock_mod, opts, fn ->
      pending = pending_transforms(repo, path, source)

      if pending == [] do
        log?(log?, "No pending transforms.")
        :ok
      else
        log?(log?, "Found #{length(pending)} pending transform(s).")
        run_pending(repo, pending, source, log?)
      end
    end)
  end

  defp pending_transforms(repo, path, source) do
    completed = MapSet.new(Pollard.Schema.versions(repo, source))

    path
    |> discover_files()
    |> Enum.reject(fn {version, _path} -> MapSet.member?(completed, version) end)
  end

  defp discover_files(path) do
    path
    |> Path.join("**/*.exs")
    |> Path.wildcard()
    |> Enum.map(fn file ->
      basename = Path.basename(file)

      case Integer.parse(basename) do
        {version, "_" <> _rest} -> {version, file}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(fn {version, _} -> version end)
  end

  defp run_pending(repo, pending, source, log?) do
    Enum.reduce_while(pending, :ok, fn {version, file}, :ok ->
      log?(log?, "Running #{Path.basename(file)}...")

      case run_file(repo, file, log?) do
        :ok ->
          Pollard.Schema.record_version(repo, source, version)
          log?(log?, "Completed #{Path.basename(file)}")
          {:cont, :ok}

        {:error, name, reason} ->
          log?(
            log?,
            "FAILED transform #{inspect(name)} in #{Path.basename(file)}: #{inspect(reason)}"
          )

          {:halt, {:error, name, reason}}
      end
    end)
  end

  defp run_file(repo, file, log?) do
    modules = load_file(file)
    module = List.last(modules)

    transforms = module.__pollard_transforms__()

    Enum.reduce_while(transforms, :ok, fn {name, func_name}, :ok ->
      log?(log?, "  -> #{name}")

      case run_transform(repo, module, func_name) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, name, reason}}
      end
    end)
  end

  defp run_transform(repo, module, func_name) do
    case repo.transaction(fn -> apply(module, func_name, []) end) do
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_file(file) do
    Code.compiler_options(ignore_module_conflict: true)
    modules = Code.compile_file(file) |> Enum.map(fn {mod, _binary} -> mod end)
    Code.compiler_options(ignore_module_conflict: false)
    modules
  end

  defp with_lock(repo, lock_mod, opts, fun) do
    case lock_mod.acquire(repo, opts) do
      :ok ->
        try do
          fun.()
        after
          lock_mod.release(repo, opts)
        end

      {:error, :locked} ->
        {:error, :locked}
    end
  end

  defp log?(false, _msg), do: :ok
  defp log?(true, msg), do: Logger.info("[Pollard] #{msg}")
end
