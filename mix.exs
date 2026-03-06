defmodule GleamAutomerge.MixProject do
  use Mix.Project

  @version "0.1.2"
  @github_url "https://github.com/d-buckner/gleam-automerge"

  def project do
    [
      app: :gleam_automerge,
      version: @version,
      elixir: "~> 1.15",
      compilers: [:gleam] ++ Mix.compilers(),
      erlc_paths: erlc_paths(Mix.env()),
      erlc_include_path: "build/dev/erlang/gleam_automerge/include",
      prune_code_paths: false,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      package: package(),
    ]
  end

  defp erlc_paths(:test) do
    ["build/dev/erlang/gleam_automerge/_gleam_artefacts",
     "build/dev/erlang/gleam_automerge/build",
     "build/dev/erlang/gleam_automerge_test/_gleam_artefacts"]
  end
  defp erlc_paths(_) do
    ["build/dev/erlang/gleam_automerge/_gleam_artefacts",
     "build/dev/erlang/gleam_automerge/build"]
  end

  defp aliases do
    [
      "gleam.test": [
        &write_gleam_dep_mix_exs/1,
        # Compile all deps first. This causes Mix to wipe _build/dev/lib/gleam_stdlib/
        # (removing any _gleam_artefacts/ we might have pre-created), but it also
        # compiles mix_gleam's BEAM files. With mix_gleam compiled, the subsequent
        # "compile.gleam" step can load Mix.Tasks.Compile.Gleam without triggering
        # another round of dep compilation — which means _gleam_artefacts/ survives.
        fn _ -> Mix.Task.run("deps.compile") end,
        &compile_gleam_deps/1,
        "compile.gleam",
        &compile_gleam_tests/1,
        "gleam.test"
      ]
    ]
  end

  defp compile_gleam_tests(_) do
    Mix.Tasks.Compile.Gleam.compile_package(:gleam_automerge, true)
  end

  # Gleam-only hex packages ship without a mix.exs, so Mix can't compile their
  # .erl sources. Generate a minimal one if absent.
  defp write_gleam_dep_mix_exs(_) do
    lock = Mix.Dep.Lock.read()
    for name <- [:gleam_stdlib, :gleeunit] do
      dep_dir = Path.join("deps", "#{name}")
      mix_path = Path.join(dep_dir, "mix.exs")
      if File.exists?(dep_dir) and not File.exists?(mix_path) do
        version =
          case lock[name] do
            {:hex, _, ver, _, _, _, _, _} -> ver
            _ -> "0.1.0"
          end
        module = name |> to_string() |> Macro.camelize()
        File.write!(mix_path, """
        defmodule #{module}.MixProject do
          use Mix.Project
          def project, do: [app: :#{name}, version: "#{version}"]
        end
        """)
      end
    end
  end

  # `gleam compile-package --lib _build/dev/lib` resolves dependency types from
  # .cache files in _build/dev/lib/<name>/_gleam_artefacts/. These are NOT
  # produced by Mix's normal .erl compilation — they come from running
  # `gleam compile-package` on each Gleam dep. We run this after `deps.compile`
  # so the artefacts are created into already-stable dep directories.
  defp compile_gleam_deps(_) do
    build_lib = Mix.Project.build_path() |> Path.join("lib")
    for name <- [:gleam_stdlib, :gleeunit] do
      dep_dir = Path.join("deps", "#{name}")
      out = Path.join(build_lib, "#{name}")
      artefacts = Path.join(out, "_gleam_artefacts")
      if File.dir?(dep_dir) and not File.dir?(artefacts) do
        File.mkdir_p!(out)
        0 = Mix.shell().cmd(
          "gleam compile-package --target erlang --no-beam" <>
            " --package #{dep_dir} --out #{out} --lib #{build_lib}"
        )
      end
    end
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      name: "gleam_automerge",
      description: "Gleam bindings for automerge-rs via Rustler NIF",
      links: %{"GitHub" => @github_url},
      licenses: ["MIT"],
      files: ~w[src lib native mix.exs gleam.toml README.md LICENSE],
    ]
  end
end
