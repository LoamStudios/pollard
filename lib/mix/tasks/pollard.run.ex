defmodule Mix.Tasks.Pollard.Run do
  @shortdoc "Runs all pending data transforms"
  @moduledoc """
  Runs all pending data transforms.

      $ mix pollard.run

  Discovers transform files in `priv/repo/transforms/`, checks which have
  already been applied, and executes pending ones in version order.

  ## Options

    * `--repo` - The repo module. Defaults to the app's main repo.
    * `--migration-source` - Name of the tracking table. Defaults to `"transforms"`.

  """

  use Mix.Task

  @impl true
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [repo: :string, migration_source: :string]
      )

    Mix.Task.run("app.start")

    repo = get_repo(opts)
    source = opts[:migration_source] || "transforms"
    path = Path.join(["priv", "repo", "transforms"])

    case Pollard.Runner.run(repo, path, migration_source: source) do
      :ok ->
        :ok

      {:error, name, reason} ->
        Mix.raise("Transform #{inspect(name)} failed: #{inspect(reason)}")

      {:error, :locked} ->
        Mix.raise("Could not acquire advisory lock. Another transform runner may be active.")
    end
  end

  defp get_repo(opts) do
    case opts[:repo] do
      nil ->
        app = Mix.Project.config()[:app]

        app
        |> Application.get_env(:ecto_repos, [])
        |> List.first() ||
          Mix.raise(
            "No repo found. Specify one with --repo or configure :ecto_repos in your app config."
          )

      repo_string ->
        Module.concat([repo_string])
    end
  end
end
