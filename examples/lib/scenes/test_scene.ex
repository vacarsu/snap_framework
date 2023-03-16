defmodule Examples.Scene.TestScene do
  require Logger
  use SnapFramework.Scene, opts: []

  @impl true
  def setup(scene) do
    scene
    |> assign(
      dropdown_opts: [
        {"Dashboard", :dashboard},
        {"Controls", :controls},
        {"Primitives", :primitives}
      ],
      button_icon: :button_icons,
      button_data: {100, 50, 5},
      test_clicked: false,
      dropdown_value: :dashboard,
      button_text: "test",
      show: true,
      buttons: ["test", "test_1", "test_2"]
    )
  end

  @impl true
  def process_info({test, _}, scene) do
    IO.inspect("info")
    {:noreply, scene |> assign(button_text: "test")}
  end

  @impl true
  def process_event({:click, :btn}, _, scene) do
    {:noreply, assign(scene, button_text: "clicked")}
  end

  def process_event(_, _, scene) do
    {:noreply, scene}
  end

  @impl true
  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= grid item_width: 200, item_height: 100, padding: 5, gutter: 5, rows: 10, cols: 10 do %>
        <%= row do %>
          <%= component Examples.Component.Button, @button_data, id: :btn do %>
            <%= primitive Scenic.Primitive.Text, @button_text %>
          <% end %>
        <% end %>
    <% end %>
    """
  end
end
