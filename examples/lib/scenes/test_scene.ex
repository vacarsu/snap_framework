defmodule Examples.Scene.TestScene do
  import Scenic.Components, only: [dropdown: 3]
  import Scenic.Primitives, only: [text: 3]
  import Examples.Component.Button, only: [button: 3]
  import Examples.Component.ButtonList, only: [button_list: 3]
  alias Scenic.Component.Input.Dropdown
  alias Scenic.Primitive.Text
  require Logger

  use SnapFramework.Scene,
    name: "test_scene",
    template: "lib/scenes/test_scene.eex",
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

  watch [:dropdown_value]

  use_effect [assigns: [text_value: :any]], [
    modify: [
      dropdown_value_text: {&text/3, {:assigns, [:text_value]}}
    ]
  ]

  use_effect [assigns: [dropdown_value: :primitives]], [
    add: [{&button/3, :button_text, id: :test_btn, translate: {200, 20}}],
  ]

  use_effect [on_click: [:test_btn]], :noreply, [
    set: [button_text: "button clicked", text_value: "button clicked"],
    delete: [:test_btn]
  ]

  def process_event({:value_changed, :dropdown, value}, _, scene) do
    {:noreply, assign(scene, dropdown_value: value, text_value: "selected value #{value}")}
  end
end
