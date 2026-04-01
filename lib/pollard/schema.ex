defmodule Pollard.Schema do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "transforms" do
    field :version, :integer
    timestamps(updated_at: false)
  end

  @doc false
  def versions(repo, source) do
    repo.all(
      from(s in {source, __MODULE__}, select: s.version),
      log: false
    )
  end

  @doc false
  def record_version(repo, source, version) do
    repo.insert!(
      %__MODULE__{version: version, inserted_at: NaiveDateTime.utc_now()}
      |> Ecto.put_meta(source: source),
      log: false
    )
  end
end
