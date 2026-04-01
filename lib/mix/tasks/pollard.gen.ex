defmodule Mix.Tasks.Pollard.Gen do
  @shortdoc "Generates a new data transform file"
  @moduledoc """
  Generates a new data transform.

      $ mix pollard.gen name_of_transform

  The generated file will be placed in `priv/repo/transforms/` with a
  timestamp prefix for ordering.

  ## Options

    * `--repo` - The repo module. Defaults to the app's main repo.

  """

  use Mix.Task

  @impl true
  def run(args) do
    case args do
      [] ->
        Mix.raise("Expected a transform name. Usage: mix pollard.gen name_of_transform")

      [name | _rest] ->
        generate(name)
    end
  end

  defp generate(name) do
    timestamp = timestamp()
    module_name = Macro.camelize(name)
    filename = "#{timestamp}_#{name}.exs"
    app = Mix.Project.config()[:app]
    app_module = app |> Atom.to_string() |> Macro.camelize()

    dir = Path.join(["priv", "repo", "transforms"])
    File.mkdir_p!(dir)
    path = Path.join(dir, filename)

    contents = """
    defmodule #{app_module}.Transforms.#{module_name} do
      use Pollard

      transform "#{String.replace(name, "_", " ")}" do
        # Data operations run inside a Repo.transaction
      end
    end
    """

    File.write!(path, contents)
    Mix.shell().info("* creating #{path}")
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()

    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: "#{i}"
end
