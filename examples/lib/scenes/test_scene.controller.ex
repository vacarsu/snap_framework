defmodule Examples.Scene.TestSceneController do
  import Scenic.Components, only: [dropdown: 3]
  import Scenic.Primitives, only: [text: 3]
  import Examples.Component.Button, only: [button: 3]
  import Examples.Component.ButtonList, only: [button_list: 3]
  alias Scenic.Graph
  require Logger

  def on_text_change(scene) do
    Logger.debug("changed")
    graph =
      scene.assigns.graph
      |> Graph.modify(:dropdown_value_text, &text(&1, scene.assigns.text_value, []))
      |> Graph.modify(:test_btn, &button(&1, scene.assigns.button_text, []))

    Scenic.Scene.assign(scene, graph: graph)
  end

  def on_dropdown_value_change(scene) do
    Logger.debug("changed")
    graph =
      scene.assigns.graph
      |> Graph.modify(:test_btn, &button(&1, scene.assigns.button_text, []))

    Scenic.Scene.assign(scene, graph: graph)
  end
end
