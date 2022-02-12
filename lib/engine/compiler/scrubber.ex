defmodule SnapFramework.Engine.Compiler.Scrubber do
  require Logger

  def scrub([]) do
    []
  end

  def scrub(parsed) do
    Enum.reduce(parsed, [], &scrub_item/2)
  end

  def scrub(parsed, acc) do
    Enum.reduce(parsed, acc, &scrub_item/2)
  end

  defp scrub_item(nil, acc) do
    acc
  end

  defp scrub_item("\n", acc) do
    acc
  end

  defp scrub_item(
         [type: :graph, opts: _] = child,
         acc
       ) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(
         [
           "\n",
           [type: :component, module: _, data: _, opts: _, children: children] = child,
           "\n"
         ],
         acc
       ) do
    children = scrub(children)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(
         [[type: :component, module: _, data: _, opts: _, children: children] = child],
         acc
       ) do
    children = scrub(children)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(
         [type: :component, module: _, data: _, opts: _, children: children] = child,
         acc
       ) do
    children = scrub(children)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(
         ["\n", [type: :primitive, module: _, data: _, opts: _] = child, "\n"],
         acc
       ) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(
         [[type: :primitive, module: _, data: _, opts: _] = child],
         acc
       ) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(
         [type: :primitive, module: _, data: _, opts: _] = child,
         acc
       ) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(
         [
           [
             type: :layout,
             padding: _padding,
             width: _width,
             height: _height,
             translate: _translate,
             children: children
           ] = child
         ],
         acc
       ) do
    if length(children) > 0 and not is_nil(List.first(children)[:type]) do
      children = scrub(children)
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    else
      children = scrub(children)
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    end
  end

  defp scrub_item(
         [
           type: :layout,
           padding: _padding,
           width: _width,
           height: _height,
           translate: _translate,
           children: children
         ] = child,
         acc
       ) do
    if length(children) > 0 and not is_nil(List.first(children)[:type]) do
      children = scrub(children)
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    else
      children = scrub(List.first(children))
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    end
  end

  defp scrub_item(
         [
           [
             type: :grid,
             item_width: _item_width,
             item_height: _item_height,
             rows: _rows,
             cols: _cols,
             translate: _translate,
             children: children
           ] = child
         ],
         acc
       ) do
    if length(children) > 0 and not is_nil(List.first(children)[:type]) do
      children = scrub(children)
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    else
      children = scrub(List.first(children))
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    end
  end

  defp scrub_item(
         [
           type: :grid,
           item_width: _item_width,
           item_height: _item_height,
           rows: _rows,
           cols: _cols,
           translate: _translate,
           children: children
         ] = child,
         acc
       ) do
    if length(children) > 0 and not is_nil(List.first(children)[:type]) do
      children = scrub(children)
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    else
      children = scrub(List.first(children))
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    end
  end

  defp scrub_item(
         [
           type: :row,
           children: children
         ] = child,
         acc
       ) do
    Logger.debug("row children: #{inspect(children)}")

    if length(children) > 0 and not is_nil(List.first(children)[:type]) do
      children = scrub(children)
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    else
      children = scrub(List.first(children))
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    end
  end

  defp scrub_item(
         [
           type: :col,
           children: children
         ] = child,
         acc
       ) do
    if length(children) > 0 and not is_nil(List.first(children)[:type]) do
      children = scrub(children)
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    else
      children = scrub(List.first(children))
      List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
    end
  end

  # defp scrub_item([["\n" | _]] = children, acc) do
  #   Logger.debug("special case")
  #   List.insert_at(acc, length(acc), Enum.reduce(children, acc, &scrub_item/2))
  # end

  # defp scrub_item([%{type: _type} | _] = child, acc) do
  #   List.insert_at(acc, length(acc), child)
  # end

  defp scrub_item([["\n", _, "\n"] | _] = children, acc) do
    Logger.debug("nested #{inspect(children)}")
    children = scrub(children)

    Enum.reduce(children, acc, fn child, acc -> List.insert_at(acc, length(acc), child) end)
  end

  defp scrub_item(child, acc) do
    Logger.debug(inspect(child))
    List.insert_at(acc, length(acc), scrub(child))
  end
end
