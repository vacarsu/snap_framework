defmodule Examples.MixProject do
  use Mix.Project

  def project do
    [
      app: :examples,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Examples, []},
      extra_applications: [:crypto, :ring_logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic_driver_local, "~> 0.11.0"},
      {:truetype_metrics, "~> 0.5"},
      {:ex_image_info, "~> 0.2.4", runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ring_logger, "~> 0.6"},
      {:snap_framework, path: Path.relative_to_cwd("..")}
    ]
  end
end
