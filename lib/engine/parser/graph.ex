defmodule SnapFramework.Parser.Graph do
  require Logger

  @moduledoc false

  def run(ast) do
    ast
    |> parse()
  end

  def parse({:graph, meta, [opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :graph,
        opts: unquote(opts)
      ]
    end
  end

  def parse({:graph, meta, []}) do
    quote line: meta[:line] || 0 do
      [
        type: :graph,
        opts: []
      ]
    end
  end

  def parse(ast), do: ast
end
