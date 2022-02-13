defmodule SnapFramework.Engine.Builder do
  @moduledoc """
  ## Overview

  This module is responsible for taking the parsed EEx template and building the graph.
  """

  require Logger
  alias __MODULE__

  def build_graph(list, acc \\ %{}) do
    Enum.reduce(list, acc, &render_graph/2)
  end

  defp render_graph(child, graph) do
    graph
    |> Builder.Graph.build(child)
    |> Builder.Grid.build(child)
    |> Builder.Layout.build(child)
    |> Builder.Component.build(child)
    |> Builder.Primitive.build(child)
  end
end
