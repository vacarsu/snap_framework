defmodule Examples.Scene.TestScene do
  use SnapFramework.Scene, services: [Examples.Services.MyService]

  alias Examples.Services.MyService

  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= primitive Scenic.Primitive.Text,
        "selected value #{@dropdown_value}",
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

  def process_event({:value_changed, :dropdown, value}, _, scene) do
    MyService.update(:dropdown_value, value)
    {:noreply, scene}
  end
end
