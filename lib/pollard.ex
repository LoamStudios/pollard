defmodule Pollard do
  @moduledoc """
  Tracked, ordered, one-way data transformations for Ecto applications.

  Pollard mirrors the Ecto migration system — same conventions, same workflow —
  but for data, not schema. Transforms are one-way (no rollback), tracked in a
  database table, and protected by advisory locks to prevent concurrent execution.

  ## Usage

      defmodule MyApp.Transforms.BackfillShopDetails do
        use Pollard

        transform "Backfill missing shop details" do
          from(s in "shops", where: is_nil(s.details))
          |> MyApp.Repo.update_all(set: [details: %{}])
        end
      end

  Each `transform` block runs in its own database transaction. Multiple blocks
  per file break work into smaller transactions to avoid holding locks too long.

  ## Running transforms

  Via Mix task:

      mix pollard.run

  Via release module:

      Pollard.Runner.run(MyApp.Repo, path)

  """

  defmacro __using__(_opts) do
    quote do
      import Pollard, only: [transform: 2]
      Module.register_attribute(__MODULE__, :pollard_transforms, accumulate: true)
      @before_compile Pollard
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __pollard_transforms__ do
        @pollard_transforms |> Enum.reverse()
      end
    end
  end

  @doc """
  Defines a named transform block.

  The block runs inside a `Repo.transaction/1` call. Each `transform` in a file
  gets its own transaction.

      transform "Seed resource types" do
        MyApp.Repo.insert_all("resource_types", [
          %{name: "product", inserted_at: DateTime.utc_now()}
        ], on_conflict: :nothing)
      end

  """
  defmacro transform(name, do: block) do
    func_name = :"__pollard_transform_#{:erlang.unique_integer([:positive])}__"

    quote do
      @pollard_transforms {unquote(name), unquote(func_name)}
      def unquote(func_name)(), do: unquote(block)
    end
  end
end
