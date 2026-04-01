defmodule Mix.Tasks.Pollard.GenTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @test_dir "test_transforms_gen"

  setup do
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    :ok
  end

  test "raises without arguments" do
    assert_raise Mix.Error, ~r/Expected a transform name/, fn ->
      Mix.Tasks.Pollard.Gen.run([])
    end
  end

  test "generates a transform file with timestamp prefix" do
    capture_io(fn ->
      Mix.Tasks.Pollard.Gen.run(["backfill_user_names"])
    end)

    [file] = Path.wildcard("priv/repo/transforms/*backfill_user_names.exs")
    content = File.read!(file)

    assert content =~ "use Pollard"
    assert content =~ "transform"
    assert content =~ "BackfillUserNames"

    # Cleanup
    File.rm_rf!("priv/repo/transforms")
  end
end
