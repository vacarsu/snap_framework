defmodule Examples.Scene.TestScene do
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

  # use_effect([assigns: [text_value: :any, button_text: :any]],
  #   run: [:on_text_change]
  # )

  use_effect(:dropdown_value, [:on_dropdown_value_change, :on_text_change])

  # use_effect [on_click: [:test_btn]], :noreply, [
  #   set: [button_text: "button clicked", text_value: "button clicked"],
  # ]

  @impl true
  def mounted(scene) do
    scene
  end

  @impl true
  def process_event({:value_changed, :dropdown, value}, _, scene) do
    {:noreply,
     assign(scene, dropdown_value: value, button_text: "hi", text_value: "selected value #{value}")}
  end

  def process_event(_, _, scene) do
    {:noreply, scene}
  end
end
