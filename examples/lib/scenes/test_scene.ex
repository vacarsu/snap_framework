defmodule Examples.Scene.TestScene do
  import Scenic.Components, only: [dropdown: 3]
  import Scenic.Primitives, only: [text: 3]
  import Examples.Component.Button, only: [button: 3]
  import Examples.Component.ButtonList, only: [button_list: 3]
  alias Scenic.Component.Input.Dropdown
  alias Scenic.Primitive.Text
  require Logger

  use SnapFramework.Scene,
    template: "lib/scenes/test_scene.eex",
    controller: Examples.Scene.TestSceneController,
    assigns: [
      dropdown_opts: [
        {"Dashboard", :dashboard},
        {"Controls", :controls},
        {"Primitives", :primitives}
      ],
      button_icon: :button_icons,
      test_clicked: false,
      dropdown_value: :dashboard,
      button_text: "test",
      text_value: "selected value <%= @state.dropdown_value %>",
      buttons: ["test", "test_1", "test_2"]
    ]

  # watch [:dropdown_value]

  # use_effect([assigns: [text_value: :any, button_text: :any]],
  #   run: [:on_text_change]
  # )

  use_effect([assigns: [dropdown_value: :any]], run: [:on_dropdown_value_change, :on_text_change])

  # use_effect [on_click: [:test_btn]], :noreply, [
  #   set: [button_text: "button clicked", text_value: "button clicked"],
  # ]

  def mounted(scene) do
    Logger.debug("callback mounted called")
    Logger.debug(inspect(scene.assigns.graph))
    scene
  end

  def process_event({:value_changed, :dropdown, value}, _, scene) do
    # {:ok, [btn_pid]} = child(scene, :test_btn)
    # Scenic.Component.put(btn_pid, "selected value #{value}")
    Logger.debug(inspect @effects_registry)
    Logger.debug("event hit")
    {:noreply,
     assign(scene, dropdown_value: value, button_text: "hi", text_value: "selected value #{value}")}
  end

  def process_event(_, _, scene) do
    Logger.debug("working")
    {:noreply, scene}
  end
end
