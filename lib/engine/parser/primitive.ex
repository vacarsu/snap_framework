defmodule SnapFramework.Parser.Primitive do
  require Logger

  def run(ast) do
    ast
    |> parse()
  end

  def parse({:primitive, meta, [name, data, opts]}) when is_list(opts) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), unquote(opts))
    end
  end

  def parse({:primitive, meta, [name, opts]}) when is_list(opts) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), nil, unquote(opts))
    end
  end

  def parse({:primitive, meta, [name, data]}) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), [])
    end
  end

  def parse(ast), do: ast
end
