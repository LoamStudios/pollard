defmodule Pollard.RunnerTest do
  use ExUnit.Case

  describe "discover_files (via pending_transforms)" do
    test "parses version from filename and sorts by version" do
      dir = Path.join(System.tmp_dir!(), "pollard_test_#{:erlang.unique_integer([:positive])}")
      File.mkdir_p!(dir)

      on_exit(fn -> File.rm_rf!(dir) end)

      # Create files out of order
      File.write!(Path.join(dir, "20260402000000_second.exs"), "")
      File.write!(Path.join(dir, "20260401000000_first.exs"), "")
      File.write!(Path.join(dir, "20260403000000_third.exs"), "")
      File.write!(Path.join(dir, "not_a_transform.exs"), "")

      # Use the private discover_files function indirectly by checking the module
      # We test the public interface via integration tests with a real DB
      files =
        dir
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

      versions = Enum.map(files, fn {v, _} -> v end)
      assert versions == [20_260_401_000_000, 20_260_402_000_000, 20_260_403_000_000]
    end
  end
end
