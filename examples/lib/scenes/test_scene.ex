defmodule Examples.Scene.TestScene do
  import Scenic.Components, only: [dropdown: 3]
  import Scenic.Primitives, only: [text: 3]
  import Examples.Component.Button, only: [button: 3]
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
      button_icon: :button_icon,
      test_clicked: false,
      dropdown_value: :dashboard,
      button_text: "test",
      text_value: "selected value <%= @state.dropdown_value %>"
    }

  use_effect [state: [text_value: :any]], [
    modify: [
      dropdown_value_text: {&text/3, :text_value}
    ]
  ]

  use_effect [state: [dropdown_value: :primitives]], [
    add: [{&button/3, nil, id: :test_btn, translate: {200, 20}}],
  ]

  use_effect [on_click: [:test_btn]], :noreply, [
    set: [button_text: "button clicked", text_value: "button clicked"],
    delete: [:test_btn]
  ]

  def setup(state) do
    Logger.debug("scene setup #{inspect(state)}")
    state
  end

  def process_event({:value_changed, :dropdown, value}, _, state) do
    state = %{
      state |
      dropdown_value: value,
      text_value: "selected value #{value}"
    }
    {:noreply, state}
  end
end
