defmodule Examples.Component.Button do
  import Scenic.Primitives, only: [rounded_rectangle: 3]
  import Examples.Component.ButtonIcon, only: [button_icon: 3]

  use SnapFramework.Component,
    name: :button,
    template: "lib/components/button.eex",
    assigns: [icon: "test", text: "test"],
    opts: []

  defcomponent :button, :string

  def setup(scene) do
    assign(scene, icon: scene.assigns.data, text: scene.assigns.data)
  end

  def process_input({:cursor_button, {0, :release, _, _}}, id, scene) do
    send_parent_event(scene, {:click, scene.assigns.opts[:id]})
    {:noreply, scene}
  end

  def process_input(_, _, scene) do
    {:noreply, scene}
  end
end
