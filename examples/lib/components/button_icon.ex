defmodule Examples.Component.ButtonIcon do
  import Scenic.Primitives

  use SnapFramework.Component,
    name: :button_icon,
    template: "lib/components/button_icon.eex",
    state: %{slot: nil, slot_cmp: nil},
    opts: []

  defcomponent :button_icon, :any
end
