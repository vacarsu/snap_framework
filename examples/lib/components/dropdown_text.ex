defmodule Examples.Component.DropdownText do
  use SnapFramework.Component,
    name: :dropdown_text,
    state: [Examples.State.MyState]

  alias Examples.State.MyState

  def mount(scene) do
    scene
  end

  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= text "selected value #{@dropdown_value}",
        translate: {20, 80}
    %>

    <%= component Scenic.Component.Input.Dropdown, {
        @dropdown_opts,
        @dropdown_value
      },
      id: :dropdown
    %>
    """
  end

  def event({:value_changed, :dropdown, value}, _, scene) do
    MyState.assign(dropdown_value: value)
    {:noreply, scene}
  end
end
