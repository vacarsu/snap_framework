defmodule Examples.Component.Button do
  require Logger
  use SnapFramework.Component, name: :button, type: :tuple, opts: []

  @impl true
  def mount(scene) do
    send_parent(scene, {:test, :test})
    scene
  end

  @impl true
  def event({:click, :btn}, _, scene) do
    {:noreply, assign(scene, button_text: "clicked")}
  end

  def event(_, _, scene) do
    {:noreply, scene}
  end

  @impl true
  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= primitive Scenic.Primitive.RoundedRectangle,
        @data,
        translate: {0, 0},
        id: :bg
    %>

    <%= @children %>
    """
  end
end
