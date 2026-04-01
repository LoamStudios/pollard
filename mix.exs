defmodule Pollard.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/LoamStudios/pollard"

  def project do
    [
      app: :pollard,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Tracked, ordered, one-way data transformations for Ecto applications.",
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Pollard",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"],
      groups_for_modules: [
        "Lock Strategies": [
          Pollard.Lock,
          Pollard.Lock.Postgres,
          Pollard.Lock.None
        ],
        "Mix Tasks": [
          Mix.Tasks.Pollard.Gen,
          Mix.Tasks.Pollard.Gen.Migration,
          Mix.Tasks.Pollard.Run
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE usage-rules.md)
    ]
  end
end
