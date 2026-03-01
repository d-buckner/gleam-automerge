defmodule Automerge.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/d-buckner/gleam-automerge"

  def project do
    [
      app: :automerge,
      version: @version,
      elixir: "~> 1.15",
      compilers: [:gleam] ++ Mix.compilers(),
      erlc_paths: erlc_paths(Mix.env()),
      erlc_include_path: "build/dev/erlang/automerge/include",
      prune_code_paths: false,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      package: package(),
    ]
  end

  defp erlc_paths(:test) do
    ["build/dev/erlang/automerge/_gleam_artefacts",
     "build/dev/erlang/automerge/build",
     "build/dev/erlang/automerge_test/_gleam_artefacts"]
  end
  defp erlc_paths(_) do
    ["build/dev/erlang/automerge/_gleam_artefacts",
     "build/dev/erlang/automerge/build"]
  end

  defp aliases do
    [
      "gleam.test": ["compile.gleam", &compile_gleam_tests/1, "gleam.test"]
    ]
  end

  defp compile_gleam_tests(_) do
    Mix.Tasks.Compile.Gleam.compile_package(:automerge, true)
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:rustler_precompiled, "~> 0.8"},
      {:rustler, ">= 0.0.0", runtime: false},
      {:mix_gleam, "~> 0.6"},
      {:gleam_stdlib, "~> 0.69"},
      {:gleeunit, "~> 1.9", only: [:dev, :test]},
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
