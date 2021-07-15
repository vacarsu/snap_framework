defmodule Examples.Component.Button do
  import Scenic.Primitives, only: [rounded_rectangle: 3]
  import Examples.Component.ButtonIcon, only: [button_icon: 3]

  use SnapFramework.Component,
    name: :button,
    template: "lib/components/button.eex",
    state: %{icon: "test", text: "test"},
    opts: []

  defcomponent :button, :string

  def setup(state) do
    Logger.debug(inspect state)
    state = %{state | icon: state.data, text: state.data}
    Logger.debug("button setup #{inspect(state)}")
    state
  end

  def process_input({:cursor_button, {0, :release, _, _}}, id, scene) do
    Logger.debug(inspect scene.assigns.state.opts[:id])
    send_parent_event(scene, {:click, scene.assigns.state.opts[:id]})
    {:noreply, scene}
  end

  def process_input(_, _, scene) do
    {:noreply, scene}
  end
end
