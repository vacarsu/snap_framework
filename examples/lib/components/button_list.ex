defmodule Examples.Component.ButtonList do
  import Scenic.Primitives
  import Examples.Component.Button, only: [button: 3]

  use SnapFramework.Component,
    name: :button_list,
    template: "lib/components/button_list.eex",
    assigns: [slot: nil, slot_cmp: nil],
    opts: []

  defcomponent :button_list, :any
end
