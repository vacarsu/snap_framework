defmodule Examples.Scene.TestScene do
  require Logger
  use SnapFramework.Scene

  @impl true
  def mount(scene) do
    scene
    |> assign(
      dropdown_opts: [
        {"Dashboard", :dashboard},
        {"Controls", :controls},
        {"Primitives", :primitives}
      ],
      button_icon: :button_icons,
      test_clicked: false,
      dropdown_value: :dashboard,
      button_text: "test",
      show: true,
      buttons: ["test", "test_1", "test_2"]
    )
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

    <%= grid item_width: 200, item_height: 100, padding: 5, gutter: 5, rows: 1, cols: 3 do %>
        <%= row do %>
            <%= component Scenic.Component.Button, @button_text, id: :btn %>
            <%= component Scenic.Component.Button, @button_text, id: :btn %>
            <%= component Scenic.Component.Button, @button_text, id: :btn %>
        <% end %>

        <%= col do %>
            <%= component Scenic.Component.Button, @button_text, id: :btn %>
            <%= component Scenic.Component.Button, @button_text, id: :btn %>
            <%= component Scenic.Component.Button, @button_text, id: :btn %>
        <% end %>
    <% end %>
    """
  end
end
