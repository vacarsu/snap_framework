defmodule Examples.Scene.TestScene do
  use SnapFramework.Scene

  def setup(scene) do
    assign(scene,
      dropdown_opts: [
        {"Option 1", "Option 1"},
        {"Option 2", "Option 2"},
        {"Option 3", "Option 3"}
      ],
      dropdown_value: "Option 1"
    )
  end

  def mount(scene) do
    update_child(scene, :dropdown, {scene.assigns.dropdown_opts, "Option 2"})
    scene
  end

  def render(assigns) do
    ~G"""
    <%= graph font_size: 20 %>

    <%= primitive Scenic.Primitive.Text,
        "selected value #{@dropdown_value}",
        id: :dropdown_value_text,
        translate: {20, 80}
    %>

    <%= component Scenic.Component.Input.Dropdown, {
            @dropdown_opts,
            @dropdown_value
        },
        id: :dropdown,
        translate: {20, 20}
    %>
    """
  end

  def process_event({:value_changed, :dropdown, value}, _, scene) do
    {:noreply, assign(scene, dropdown_value: value)}
  end
end
