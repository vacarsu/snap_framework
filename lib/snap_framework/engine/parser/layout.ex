defmodule SnapFramework.Engine.Parser.Layout do
  def run(ast) do
    ast
    |> parse()
  end

  defp parse({:layout, meta, [opts, [do: {:__block__, [], block}]]}) do
    children =
      block
      |> Enum.reduce([], &build_child_list/2)

    quote line: meta[:line] || 0 do
      [
        type: :layout,
        padding: unquote(opts[:padding] || 0),
        width: unquote(opts[:width]),
        height: unquote(opts[:height]),
        translate: unquote(opts[:translate] || {0, 0}),
        children: unquote(children)
      ]
    end
  end

  defp parse(ast), do: ast

  defp build_child_list({:=, [], [_, component]}, acc) do
    List.insert_at(acc, length(acc), component)
  end

  defp build_child_list(_ast, acc) do
    acc
  end
end
