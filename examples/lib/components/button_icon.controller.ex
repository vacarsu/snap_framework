defmodule Examples.Component.ButtonIconController do
  import Scenic.Primitives, only: [text: 3]
  import Examples.Component.Button, only: [button: 3]
  alias Scenic.Graph

  def on_data_change(scene) do
    graph =
      scene.assigns.graph
      |> Graph.modify(:icon, &text(&1, scene.assigns.data, []))
      |> Graph.modify(:text, &button(&1, scene.assigns.data, []))

    Scenic.Scene.assign(scene, graph: graph)
  end
end
