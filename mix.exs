defmodule SnapFramework.MixProject do
  use Mix.Project

  def project do
    [
      app: :snap_framework,
      version: "0.1.0",
      elixir: "~> 1.7",
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
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:ring_logger, "~> 0.6"},
      {:map_diff, "~> 1.3.4"}
    ]
  end
end
