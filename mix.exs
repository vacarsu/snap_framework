defmodule SnapFramework.MixProject do
  use Mix.Project

  def project do
    [
      app: :snap_framework,
      version: "0.1.0",
      elixir: "~> 1.12",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

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
      {:scenic, git: "https://github.com/boydm/scenic.git", branch: "v0.11"},
      {:scenic_driver_glfw, git: "https://github.com/boydm/scenic_driver_glfw.git", branch: "v0.11"},

      {:truetype_metrics, "~> 0.5", only: [:dev, :test], runtime: false},

      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ring_logger, "~> 0.6"},
      {:map_diff, "~> 1.3.4"}
    ]
  end
end
