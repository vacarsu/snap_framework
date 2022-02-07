defmodule Examples.Component.ButtonIcon do
  use SnapFramework.Component,
    name: :button_icon,
    type: :string,
    template: "lib/components/button_icon.eex",
    controller: Examples.Component.ButtonIconController,
    assigns: [slot: nil, slot_cmp: nil]

  use_effect(:data, :on_data_change)

  @impl true
  def setup(scene) do
    scene
  end
end
