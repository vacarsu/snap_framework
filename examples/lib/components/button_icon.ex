defmodule Examples.Component.ButtonIcon do
  import Scenic.Primitives, only: [text: 3]

  use SnapFramework.Component,
    name: :button_icon,
    template: "lib/components/button_icon.eex",
    assigns: [slot: nil, slot_cmp: nil],
    opts: []

  defcomponent :button_icon, :any

  use_effect [assigns: [data: :any]], [
    modify: [
      icon: {&text/3, {:assigns, :data}},
      text: {&text/3, {:assigns, :data}}
    ]
  ]
end
