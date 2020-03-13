defmodule CoronaWho.MixProject do
  use Mix.Project

  def project do
    [
      app: :corona_who,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CoronaWho.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, ">= 0.0.0"},
      {:table_rex, ">= 0.0.0"},
      {:jason, ">= 0.0.0"}
    ]
  end
end
