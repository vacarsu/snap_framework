defmodule Examples.Scene.TestScene do
  use SnapFramework.Scene

  alias Examples.Component.DropdownText
  alias Examples.State.MyState

  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= component DropdownText, nil %>
    """
  end

  def event({:value_changed, :dropdown, value}, _, scene) do
    MyState.assign(dropdown_value: value)
    {:noreply, scene}
  end
end
