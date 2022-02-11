defmodule SnapFramework.Engine.Compiler.Scrubber do
  require Logger

  def scrub(parsed) do
    Enum.reduce(parsed, [], &scrub_item/2)
  end

  defp scrub_item("\n", acc) do
    acc
  end

  defp scrub_item(
         [type: :component, module: _, data: _, opts: _, children: []] = child,
         acc
       ) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(
         [type: :component, module: _, data: _, opts: _, children: children] = child,
         acc
       ) do
    children = scrub(children)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(
         [
           type: :layout,
           children: children,
           padding: _padding,
           width: _width,
           height: _height,
           translate: _translate
         ] = child,
         acc
       ) do
    children = scrub(children)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(
         [
           type: :grid,
           children: children,
           item_width: _item_width,
           item_height: _item_height,
           rows: _rows,
           cols: _cols,
           translate: _translate
         ] = child,
         acc
       ) do
    children = scrub(children)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(%{type: _type} = child, acc) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(child, acc) when is_list(child) do
    if is_nil(child[:type]) do
      List.insert_at(acc, length(acc), scrub(List.first(child)))
    else
      List.insert_at(acc, length(acc), child)
    end
  end

  defp scrub_item(child, acc) do
    List.insert_at(acc, length(acc), child)
  end
end
