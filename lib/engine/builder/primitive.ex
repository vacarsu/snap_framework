defmodule SnapFramework.Engine.Builder.Primitive do
  def build(graph, type: :primitive, module: module, data: data, opts: opts) do
    module.add_to_graph(graph, data, opts)
  end

  def build(graph, _), do: graph
end
