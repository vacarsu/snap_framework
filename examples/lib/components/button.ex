defmodule Examples.Component.Button do
  use SnapFramework.Component,
    name: :button,
    type: :string,
    template: "lib/components/button.eex",
    controller: Examples.Component.ButtonController,
    assigns: [icon: "test", text: "test"]

  use_effect(:data, :on_data_change)

  @impl true
  def setup(scene) do
    assign(scene, icon: scene.assigns.data, text: scene.assigns.data)
  end

  @impl true
  def bounds(_data, _opts) do
    {0, 0, 100, 50}
  end

  @impl true
  def process_input({:cursor_button, {0, :release, _, _}}, _, scene) do
    send_parent_event(scene, {:click, scene.assigns.opts[:id]})
    {:noreply, scene}
  end

  def process_input(_, _, scene) do
    {:noreply, scene}
  end
end
