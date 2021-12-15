defmodule Examples.Component.Button do
  import Scenic.Primitives, only: [text: 3, rounded_rectangle: 3]

  use SnapFramework.Component,
    template: "lib/components/button.eex",
    controller: Examples.Component.ButtonController,
    assigns: [icon: "test", text: "test"]

  defcomponent(:button, :any)

  # watch [:data, :opts]

  use_effect([assigns: [text: :any]],
    run: [:on_data_change]
  )

  def setup(scene) do
    assign(scene, icon: scene.assigns.data, text: scene.assigns.data)
  end

  def bounds(data, opts) do
    {0, 0, 100, 50}
  end

  def process_input({:cursor_button, {0, :release, _, _}}, id, scene) do
    send_parent_event(scene, {:click, scene.assigns.opts[:id]})
    {:noreply, scene}
  end

  def process_input(_, _, scene) do
    {:noreply, scene}
  end

  def process_info(:test, scene) do
    Logger.debug("working")
    {:noreply, scene}
  end
end
