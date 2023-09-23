defmodule Examples.Scene.TestScene do
  use SnapFramework.Scene

  alias Examples.Component.DropdownText
  alias Examples.Services.MyService

  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= component DropdownText, nil %>
    """
  end

  def process_event({:value_changed, :dropdown, value}, _, scene) do
    MyService.update(:dropdown_value, value)
    {:noreply, scene}
  end
end
