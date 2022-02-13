defmodule SnapFramework.Engine.Builder.Component do
  def build(graph, type: :component, module: module, data: data, opts: opts, children: children) do
    module.add_to_graph(graph, data, Keyword.put_new(opts, :children, children))
  end

  def build(graph, _), do: graph
end
