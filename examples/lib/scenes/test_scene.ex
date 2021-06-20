defmodule Examples.Scene.TestScene do
  alias Scenic.Components
  alias Scenic.Primitives
  require Logger

  use SnapFramework.Scene,
    name: "test_scene",
    template: "lib/scenes/test_scene.eex",
    state: %{
      graph: Scenic.Graph.build(),
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

  def filter_event({:value_changed, :dropdown, value}, state) do
    Logger.debug(inspect("parent called"))
    state = %{state | dropdown_value: value, text_value: "selected value #{value}"}
    # set_state({:text_value, "selected value #{value}"})
    # set_state({:dropdown_value, value})
    {:noreply, state}
  end

  def filter_event({:click, :test_btn}, state) do
    Logger.debug(inspect("parent called"))
    state = %{state | test_clicked: true, text_value: "button clicked"}
    # Logger.debug(state)
    # set_state({:test_clicked, true})
    # set_state({:text_value, "button clicked? #{state.test_clicked}"})
    {:noreply, state}
  end
end
