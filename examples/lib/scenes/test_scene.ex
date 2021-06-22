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
      text_value: "selected value <%= @state.dropdown_value %>"
    }

  use_effect(
    [:text_value, :dropdown_value],
    :dropdown_value_text,
    &Primitives.text/3
  )

  use_effect(
    :test_clicked,
    :dropdown_value_text,
    &Primitives.text/3
  )

  def process_event({:value_changed, :dropdown, value}, _, state) do
    state = %{state | dropdown_value: value, text_value: "selected value #{value}"}
    {:noreply, state}
  end

  def process_event({:click, :test_btn}, _, state) do
    state = %{state | test_clicked: true, text_value: "button clicked"}
    {:noreply, state}
  end
end
