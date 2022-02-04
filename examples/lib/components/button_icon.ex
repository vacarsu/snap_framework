defmodule Examples.Component.ButtonIcon do
  use SnapFramework.Component,
    name: :button_icon,
    template: "lib/components/button_icon.eex",
    controller: Examples.Component.ButtonIconController,
    assigns: [slot: nil, slot_cmp: nil]

  # defcomponent(:button_icon, :any)

  use_effect([assigns: [data: :any]],
    run: [:on_data_change]
  )

  def setup(scene) do
    send(scene.parent, :test)
    scene
  end
end
