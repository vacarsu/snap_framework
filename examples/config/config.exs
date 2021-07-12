# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :scenic, :assets,
  module: Examples.Assets,
  alias: []

# Configure the main viewport for the Scenic application
config :examples, :viewport, [
  name: :main_viewport,
  size: {700, 600},
  default_scene: Examples.Scene.TestScene,
  drivers: [[
    module: Scenic.Driver.Glfw,
    name: :glfw,
    title: "examples",
    resizeable: false
  ]]
]

config :logger, backends: [RingLogger]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "prod.exs"
