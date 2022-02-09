defmodule SnapFramework.Engine.Builder.Graph do
  def build(_, type: :graph, opts: opts) do
    Scenic.Graph.build(opts)
  end

  def build(graph, _), do: graph
end
