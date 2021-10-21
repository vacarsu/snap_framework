defmodule Examples.Component.ButtonController do
  import Examples.Component.ButtonIcon, only: [button_icon: 3]
  alias Scenic.Graph

  def on_data_change(scene) do
    graph =
      scene.assigns.graph
      |> Graph.modify(:button_icon, &button_icon(&1, scene.assigns.data, []))

    Scenic.Scene.assign(scene, graph: graph)
  end
end
