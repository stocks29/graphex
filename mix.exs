defmodule Graphex.Mixfile do
  use Mix.Project

  def project do
    [app: :graphex,
     version: "0.1.0",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:logger],
      mod: {Graphex.Application, []}
    ]
  end

  def description do
    """
    A task graph execution library for elixir
    """
  end

  def package do
    [contributors: ["Bob Stockdale", "Mike Brennan"],
     licenses: ["MIT License"],
     links: %{"GitHub" => "https://github.com/stocks29/graphex"}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.7", only: :dev},
      {:dialyze, "~> 0.2.0", only: :dev}
    ]
  end
end
