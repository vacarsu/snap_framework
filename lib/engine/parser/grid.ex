defmodule SnapFramework.Parser.Grid do
  def run(ast) do
    ast
    |> parse()
  end

  def parse({:grid, meta, [opts, [do: {:__block__, [], block}]]}) do
    children =
      block
      |> Enum.reduce([], &build_grid_list/2)

    quote line: meta[:line] || 0 do
      [
        type: :grid,
        children: unquote(children),
        item_width: unquote(opts[:item_width] || 100),
        item_height: unquote(opts[:item_height] || 100),
        translate: unquote(opts[:translate] || {0, 0})
      ]
    end
  end

  def parse(ast), do: ast

  def build_grid_list({:=, [], [_, {:row, _, [[do: {:__block__, [], block}]]}]}, acc) do
    children =
      block
      |> Enum.reduce([], &build_child_list/2)
    List.insert_at(acc, length(acc), [type: :row, children: children])
  end

  def build_grid_list({:=, [], [_, {:col, _, [[do: {:__block__, [], block}]]}]}, acc) do
    children =
      block
      |> Enum.reduce([], &build_child_list/2)
    List.insert_at(acc, length(acc), [type: :col, children: children])
  end

  def build_grid_list(_ast, acc) do
    acc
  end

  def build_child_list({:=, [], [_, component]}, acc) do
    List.insert_at(acc, length(acc), component)
  end

  def build_child_list(_ast, acc) do
    acc
  end
end
