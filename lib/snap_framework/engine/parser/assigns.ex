defmodule SnapFramework.Engine.Parser.Assigns do
  @moduledoc false

  # @assigns_var Macro.var(:assigns, nil)

  def run(ast) do
    ast
    |> parse()
  end

  defp parse({:@, meta, [{name, _, _atom}]}) do
    # assign = SnapFramework.Engine.fetch_assign!(assigns, name)

    quote line: meta[:line] || 0 do
      var!(assigns)[unquote(name)]
    end
  end

  defp parse(ast), do: ast
end
