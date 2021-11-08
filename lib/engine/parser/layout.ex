defmodule SnapFramework.Parser.Layout do
  def run(ast) do
    ast
    |> parse()
  end

  def parse({:layout, meta, [opts, [do: {:__block__, [], block}]]}) do
    children =
      block
      |> Enum.reduce([], &build_child_list/2)

    quote line: meta[:line] || 0 do
      [
        type: :layout,
        children: unquote(children),
        padding: unquote(opts[:padding] || 0),
        width: unquote(opts[:width]),
        height: unquote(opts[:height]),
        translate: unquote(opts[:translate] || {0, 0})
      ]
    end
  end

  def parse(ast), do: ast

  def build_child_list({:=, [], [_, component]}, acc) do
    List.insert_at(acc, length(acc), component)
  end

  def build_child_list(_ast, acc) do
    acc
  end
end
