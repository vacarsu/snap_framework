defmodule Examples.Component.Button do
  import Scenic.Primitives
  import Examples.Component.ButtonIcon, only: [button_icon: 3]

  use SnapFramework.Component,
    name: :button,
    template: "lib/components/button.eex",
    state: %{icon_cmp: nil, text: ""},
    opts: []

  defcomponent :button, :any

  # def setup(state) do
  #   state = %{state | icon_cmp: &text/2, text: "test"}
  #   Logger.debug("button setup #{inspect(state)}")
  #   state
  # end

  def process_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    id = state.opts[:id]
    send_event({:click, id})
    {:noreply, state}
  end

  def process_input(_, _context, state) do
    {:noreply, state}
  end
end
