defmodule Mix.Tasks.Pollard.Gen.Migration do
  @shortdoc "Generates the Pollard tracking table migration"
  @moduledoc """
  Generates a migration that creates the Pollard tracking table.

      $ mix pollard.gen.migration

  This creates a standard Ecto migration in your repo's migrations directory
  that will create the `transforms` tracking table.

  ## Options

    * `--repo` - The repo module. Defaults to the app's main repo.
    * `--migration-source` - Name of the tracking table. Defaults to `"transforms"`.

  """

  use Mix.Task

  import Mix.Ecto
  import Mix.Generator

  @impl true
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [repo: :string, migration_source: :string]
      )

    repos = parse_repo(args)
    source = opts[:migration_source] || "transforms"

    Enum.each(repos, fn repo ->
      ensure_repo(repo, args)

      path = Ecto.Migrator.migrations_path(repo)
      file = Path.join(path, "#{timestamp()}_create_pollard_#{source}_table.exs")
      app_module = repo |> Module.split() |> List.first()

      create_directory(path)

      create_file(file, migration_template(app_module: app_module, source: source))

      Mix.shell().info("""

      Remember to run the migration:

          $ mix ecto.migrate
      """)
    end)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: "#{i}"

  embed_template(:migration, """
  defmodule <%= @app_module %>.Repo.Migrations.CreatePollard<%= Macro.camelize(@source) %>Table do
    use Ecto.Migration

    def change do
      create table(:<%= @source %>, primary_key: false) do
        add :version, :bigint, primary_key: true
        add :inserted_at, :naive_datetime, null: false
      end
    end
  end
  """)
end
