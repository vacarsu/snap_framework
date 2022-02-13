defmodule SnapFramework.Engine.Parser.Assigns do
  @moduledoc false

  def run(ast, assigns) do
    ast
    |> parse(assigns)
  end

  defp parse({:@, meta, [{name, _, _atom}]}, assigns) do
    assign = SnapFramework.Engine.fetch_assign!(assigns, name)

    quote line: meta[:line] || 0 do
      unquote(Macro.escape(assign))
    end
  end

  defp parse(ast, _assigns), do: ast
end
