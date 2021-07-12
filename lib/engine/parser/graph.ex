defmodule SnapFramework.Parser.Graph do
  require Logger

  def run(ast) do
    ast
    |> parse()
  end

  def parse({:graph, meta, [opts]}) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = Scenic.Graph.build(unquote(opts))
    end
  end

  def parse({:graph, meta, []}) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = Scenic.Graph.build()
    end
  end

  def parse(ast), do: ast
end
