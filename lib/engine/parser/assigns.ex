defmodule SnapFramework.Parser.Assigns do
  require Logger

  @moduledoc false

  def run(ast, assigns) do
    ast
    |> parse(assigns)
  end

  def parse({:@, meta, [{name, _, _atom}]}, assigns) do
    assign = SnapFramework.Engine.fetch_assign!(assigns, name)

    quote line: meta[:line] || 0 do
      unquote(Macro.escape(assign))
    end
  end

  def parse(ast, _assigns), do: ast
end
