defmodule Examples.Component.Button do
  import Scenic.Primitives

  use SnapFramework.Component,
    name: :button,
    template: "lib/components/button.eex",
    state: %{}

  defcomponent :button, :string
end
