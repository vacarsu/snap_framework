defmodule SnapFramework.MixProject do
  use Mix.Project

  @version "0.2.0-beta"
  @github "https://github.com/vacarsu/snap_framework"

  def project do
    [
      app: :snap_framework,
      name: "SnapFramework",
      version: @version,
      elixir: "~> 1.13",
      package: package(),
      description: description(),
      docs: docs(),
      build_embedded: false,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # mod: {SnapFramework, []},
      extra_applications: [:crypto, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:scenic, "0.11.1"},
      {:truetype_metrics, "~> 0.5"},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ring_logger, "~> 0.6"},
      {:map_diff, "~> 1.3.4"}
    ]
  end

  defp description do
    """
    A Framework for building for building Scenic applications.
    """
  end

  defp package do
    [
      contributors: ["Alex Lopez"],
      maintainers: ["Alex Lopez"],
      licenses: ["MIT"],
      links: %{Github: @github},
      files: [
        # only include *.ex files
        "lib/**/*.ex",
        "mix.exs",
        "README.md",
        "LICENSE"
      ]
    ]
  end

  defp docs do
    [
      groups_for_modules: [
        SnapFramework: [
          SnapFramework.Scene,
          SnapFramework.Component
        ],
        Engine: [
          SnapFramework.Engine,
          SnapFramework.Engine.Builder
        ]
      ],
      source_ref: "v#{@version}",
      source_url: @github
    ]
  end
end
