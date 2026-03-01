defmodule Automerge.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/YOUR_USERNAME/gleam-automerge"

  def project do
    [
      app: :automerge,
      version: @version,
      elixir: "~> 1.15",
      compilers: [:gleam] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:rustler_precompiled, "~> 0.8"},
      {:rustler, ">= 0.0.0", runtime: false},
      {:mix_gleam, "~> 0.6"},
    ]
  end

  defp package do
    [
      name: "automerge",
      links: %{"GitHub" => @github_url},
      licenses: ["MIT"],
      files: ~w[src lib native mix.exs gleam.toml README.md LICENSE],
    ]
  end
end
