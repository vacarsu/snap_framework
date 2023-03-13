defmodule SnapFramework.Engine.Compiler.Scrubber do
  require Logger

  def scrub([]) do
    []
  end

  def scrub(parsed) do
    # Logger.debug("before scrub: #{inspect(parsed, pretty: true)}")
    scrubbed =
      parsed
      |> Enum.reduce([], &scrub_item/2)

    # Logger.debug("after scrub: #{inspect(scrubbed, pretty: true)}")
    scrubbed
  end

  defp scrub_item(
         [type: :graph, opts: _] = child,
         acc
       ) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(nil, acc) do
    acc
  end

  defp scrub_item("\n", acc) do
    acc
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
           "\n",
           [
             type: :layout,
             padding: _padding,
             width: _width,
             height: _height,
             translate: _translate,
             children: children
           ] = child,
           "\n"
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
           "\n",
           [
             type: :grid,
             item_width: _item_width,
             item_height: _item_height,
             padding: _,
             gutter: _,
             rows: _rows,
             cols: _cols,
             translate: _translate,
             children: children
           ] = child,
           "\n"
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
           [
             type: :grid,
             item_width: _item_width,
             item_height: _item_height,
             padding: _,
             gutter: _,
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
           padding: _,
           gutter: _,
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
           padding: _,
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
           type: :col,
           padding: _,
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

  defp scrub_item([["\n", _, "\n"] | _] = children, acc) do
    children = scrub(children)

    Enum.reduce(children, acc, fn child, acc -> List.insert_at(acc, length(acc), child) end)
  end

  defp scrub_item(["\n", _, "\n"] = children, acc) do
    children = scrub(children)

    Enum.reduce(children, acc, fn child, acc -> List.insert_at(acc, length(acc), child) end)
  end

  defp scrub_item(child, acc) when is_list(child) do
    if length(child) == 1 and not is_nil(child[:type]) do
      List.insert_at(acc, length(acc), child)
    else
      Enum.reduce(child, acc, fn child, acc -> List.insert_at(acc, length(acc), child) end)
    end
  end

  defp scrub_item(child, acc) do
    List.insert_at(acc, length(acc), scrub(child))
  end
end
