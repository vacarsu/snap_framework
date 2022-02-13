defmodule SnapFramework.Engine.Builder.Graph do
  alias Scenic.Graph

  # Ignore if we've already built the graph.
  def build(graph, _) when is_struct(graph, Graph) do
    graph
  end

  def build(graph, type: :graph, opts: opts) when is_map(graph) do
    Scenic.Graph.build(opts)
  end

  def build(graph, _), do: graph
end
