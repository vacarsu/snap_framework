defmodule Examples.Component.DropdownText do
  use SnapFramework.Component,
    name: :dropdown_text,
    services: [Examples.Services.MyService]

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
end
