defmodule Gleeunit.MixProject do
  use Mix.Project

  @app :gleeunit
  @version "1.9.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      name: "#{@app}",
      archives: [mix_gleam: "~> 0.6"],
      compilers: [:gleam] ++ Mix.compilers(),
      aliases: [
        "deps.get": ["deps.get", "gleam.deps.get"]
      ],
      erlc_paths: [
        "build/dev/erlang/#{@app}/_gleam_artefacts",
        "build/dev/erlang/#{@app}/build"
      ],
      erlc_include_path: "build/dev/erlang/#{@app}/include",
      prune_code_paths: false,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:gleam_stdlib, "~> 0.69"}]
  end
end
