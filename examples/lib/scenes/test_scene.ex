defmodule Examples.Scene.TestScene do
  use SnapFramework.Scene

  alias Examples.Component.DropdownText
  alias Examples.State.MyState

  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= component Scenic.Component.Button, "text", id: :btn_test %>

    <%= component DropdownText, nil, translate: {50, 50} %>
    """
  end
end
