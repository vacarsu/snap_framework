defmodule Examples.Component.Button do
  import Scenic.Primitives, only: [rounded_rectangle: 3]
  import Examples.Component.ButtonIcon, only: [button_icon: 3]

  use SnapFramework.Component,
    name: :button,
    template: "lib/components/button.eex",
    state: %{icon: "test", text: "test"},
    opts: []

  defcomponent :button, :any

  def setup(state) do
    Logger.debug(inspect state)
    # state = %{state | icon: data, text: data}
    Logger.debug("button setup #{inspect(state)}")
    state
  end

  def process_input({:cursor_button, {0, :press, _, _}}, :btn, scene) do
    Logger.debug("inputed")
    id = scene.assigns.state.opts[:id]
    send_event({:click, id})
    {:noreply, scene}
  end

  def process_input(_, _context, scene) do
    {:noreply, scene}
  end
end
