defmodule SnapFramework.Parser.Graph do
  require Logger

  @moduledoc false

  def run(ast) do
    ast
    |> parse()
  end

  defp parse({:graph, meta, [opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :graph,
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:graph, meta, []}) do
    quote line: meta[:line] || 0 do
      [
        type: :graph,
        opts: []
      ]
    end
  end

  defp parse(ast), do: ast
end
