defmodule SnapFramework.Engine.Builder.Grid do
  def build_grid(%Scenic.Graph{} = graph, children, item_width, item_height, {x, y}) do
    grid = %{
      start_x: x,
      start_y: y,
      next_x: x,
      next_y: y,
      item_width: item_width,
      item_height: item_height,
      graph: graph
    }

    do_build_grid(grid, children)
  end

  def do_build_grid(grid, children) do
    Enum.reduce(children, grid, fn child, grid ->
      case child do
        [type: :row, children: children] ->
          translate_and_render_row(grid, children)

        [type: :col, children: children] ->
          translate_and_render_col(grid, children)

        _ ->
          grid
      end
    end)
  end

  defp translate_and_render_row(grid, children) do
    grid =
      Enum.reduce(children, grid, fn child, grid ->
        case child do
          [type: :component, module: module, data: data, opts: opts] ->
            children = if opts[:do], do: opts[:do], else: nil

            translate_and_render_row_item(
              grid,
              module,
              data,
              Keyword.put_new(opts, :children, children)
            )

          [type: :component, module: module, data: data, opts: opts, children: children] ->
            translate_and_render_row_item(
              grid,
              module,
              data,
              Keyword.put_new(opts, :children, children)
            )

          [type: :primitive, module: module, data: data, opts: opts] ->
            translate_and_render_row_item(grid, module, data, opts)

          _ ->
            grid
        end
      end)

    %{grid | next_x: grid.start_x, next_y: grid.next_y + grid.item_height}
  end

  defp translate_and_render_col(grid, children) do
    grid =
      Enum.reduce(children, grid, fn child, grid ->
        case child do
          [type: :component, module: module, data: data, opts: opts] ->
            children = if opts[:do], do: opts[:do], else: nil

            translate_and_render_col_item(
              grid,
              module,
              data,
              Keyword.put_new(opts, :children, children)
            )

          [type: :component, module: module, data: data, opts: opts, children: children] ->
            translate_and_render_col_item(
              grid,
              module,
              data,
              Keyword.put_new(opts, :children, children)
            )

          [type: :primitive, module: module, data: data, opts: opts] ->
            translate_and_render_row_item(grid, module, data, opts)

          _ ->
            grid
        end
      end)

    %{grid | next_x: grid.start_x, next_y: grid.next_y}
  end

  defp translate_and_render_row_item(
         %{next_x: next_x, next_y: next_y, graph: graph, item_width: item_width} = grid,
         module,
         data,
         opts
       ) do
    %{
      grid
      | next_x: next_x + item_width,
        next_y: next_y,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  defp translate_and_render_col_item(
         %{next_x: next_x, next_y: next_y, graph: graph, item_height: item_height} = grid,
         module,
         data,
         opts
       ) do
    %{
      grid
      | next_x: next_x,
        next_y: next_y + item_height,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end
end
