defmodule Examples.Scene.TestScene do
  import Scenic.Components, only: [dropdown: 3, button: 3]
  import Scenic.Primitives, only: [text: 3]
  require Logger

  use SnapFramework.Scene,
    name: "test_scene",
    template: "lib/scenes/test_scene.eex",
    state: %{
      dropdown_opts: [
        {"Dashboard", :dashboard},
        {"Controls", :controls},
        {"Primitives", :primitives}
      ],
      test_clicked: false,
      dropdown_value: :dashboard,
      button_text: "test",
      text_value: "selected value <%= @state.dropdown_value %>"
    }

  use_effect [on_changed: [:text_value]], [
    modify: [
      dropdown_value_text: {&text/3, :text_value}
    ]
  ]

  use_effect [on_changed: [:dropdown_value]], [
    add: [{&button/3, :button_text, id: :test_btn, translate: {200, 20}}],
  ]

  use_effect [on_click: [:test_btn]], :noreply, [
    set: [button_text: "button clicked", text_value: "button clicked"],
    delete: [:test_btn]
  ]

  def process_event({:value_changed, :dropdown, value}, _, state) do
    state = %{
      state |
      dropdown_value: value,
      text_value: "selected value #{value}"
    }
    {:noreply, state}
  end
end
