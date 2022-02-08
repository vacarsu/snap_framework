defmodule Examples.Component.ButtonList do
  use SnapFramework.Component,
    name: :button_list,
    template: "lib/components/button_list.eex",
    controller: Examples.Component.ButtonListController,
    assigns: [slot: nil, slot_cmp: nil],
    opts: []
end
