defmodule Examples.Component.Button do
  import Scenic.Primitives

  use SnapFramework.Component,
    name: :button,
    template: "lib/components/button.eex",
    state: %{text: ""},
    opts: []

  defcomponent :button, :string

  def setup(state) do
    state = %{state | text: "test"}
    Logger.debug("button setup #{inspect(state)}")
    state
  end

  def process_input({:cursor_button, {:left, :press, _, _}}, _context, state) do
    id = state.opts[:id]
    send_event({:click, id})
    {:noreply, state}
  end

  def process_input(_, _context, state) do
    {:noreply, state}
  end
end
