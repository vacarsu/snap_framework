defmodule SnapFramework.Engine.Builder.Grid do
  require Logger
  alias __MODULE__

  defstruct start_x: 0,
            start_y: 0,
            next_x: 0,
            next_y: 0,
            item_width: nil,
            item_height: nil,
            max_rows: nil,
            max_cols: nil,
            curr_row: 1,
            curr_col: 1,
            graph: nil

  def build(
        graph,
        type: :grid,
        item_width: item_width,
        item_height: item_height,
        rows: rows,
        cols: cols,
        translate: {x, y},
        children: children
      ) do
    grid = %Grid{
      start_x: x,
      start_y: y,
      next_x: x,
      next_y: y,
      item_width: item_width,
      item_height: item_height,
      max_rows: rows,
      max_cols: cols,
      curr_row: 1,
      curr_col: 1,
      graph: graph
    }

    do_build(grid, children).graph
  end

  def build(graph, _), do: graph

  defp do_build(grid, children) do
    Logger.debug(inspect(children))
    Enum.reduce(children, grid, &render_grid/2)
  end

  defp render_grid([type: :row, children: children], grid) do
    grid = Enum.reduce(children, grid, &render_row/2)

    %Grid{
      grid
      | next_x: grid.start_x,
        next_y: grid.next_y + grid.item_height
    }
  end

  defp render_grid([type: :col, children: children], grid) do
    grid = Enum.reduce(children, grid, &render_col/2)

    %Grid{
      grid
      | next_x: grid.next_x + grid.item_width,
        next_y: grid.start_y
    }
  end

  defp render_grid(_, grid), do: grid

  defp render_row(
         [type: :component, module: module, data: data, opts: opts, children: children],
         grid
       ) do
    render_row_item(grid, module, data, Keyword.merge(opts, children: children))
  end

  defp render_row([type: :primitive, module: module, data: data, opts: opts], grid) do
    render_col_item(grid, module, data, opts)
  end

  defp render_row(_, grid), do: grid

  defp render_col(
         [type: :component, module: module, data: data, opts: opts, children: children],
         grid
       ) do
    render_row_item(grid, module, data, Keyword.merge(opts, children: children))
  end

  defp render_col([type: :primitive, module: module, data: data, opts: opts], grid) do
    render_col_item(grid, module, data, opts)
  end

  defp render_col(_, grid), do: grid

  # RENDERING ROW ITEM
  # Both curr_col and curr_row are below their max.
  # render component as normal
  defp render_row_item(
         %Grid{
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           item_width: item_width,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col
         } = grid,
         module,
         data,
         opts
       )
       when curr_col < max_cols and curr_row < max_rows do
    %Grid{
      grid
      | next_x: next_x + item_width,
        next_y: next_y,
        curr_col: curr_col + 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  # RENDERING ROW ITEM
  # At max columns so this will be the last component in this column.
  # reset curr_col since we're not at the max row yet.
  # and increment to next row.
  defp render_row_item(
         %Grid{
           start_x: start_x,
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           item_height: item_height,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col
         } = grid,
         module,
         data,
         opts
       )
       when curr_col == max_cols and curr_row < max_rows do
    %Grid{
      grid
      | next_x: start_x,
        next_y: next_y + item_height,
        curr_col: 1,
        curr_row: curr_row + 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  # RENDERING COL ITEM
  # At max row so we need to move down to the next col for next pass.
  defp render_row_item(
         %Grid{
           start_y: _start_y,
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           item_width: item_width,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col
         } = grid,
         module,
         data,
         opts
       )
       when curr_col < max_cols and curr_row == max_rows do
    %Grid{
      grid
      | next_x: next_x + item_width,
        curr_col: curr_col + 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  # RENDERING ROW ITEM
  # At max columns and max rows so the grid is full.
  # just increment to the next row and log a warning next
  # pass. We ignore any other primitives from here on.
  defp render_row_item(
         %Grid{
           start_x: start_x,
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           item_height: item_height,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col
         } = grid,
         module,
         data,
         opts
       )
       when curr_col == max_cols and curr_row == max_rows do
    %Grid{
      grid
      | next_x: start_x,
        next_y: next_y + item_height,
        curr_col: 1,
        curr_row: curr_row + 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  defp render_row_item(
         grid,
         module,
         _data,
         _opts
       ) do
    overflow_error(module)
    grid
  end

  # RENDERING COL ITEM
  # Both curr_col and curr_row are below their max.
  # render component as normal
  defp render_col_item(
         %Grid{
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col,
           item_height: item_height
         } = grid,
         module,
         data,
         opts
       )
       when curr_col < max_cols and curr_row < max_rows do
    %Grid{
      grid
      | next_x: next_x,
        next_y: next_y + item_height,
        curr_row: curr_row + 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  # RENDERING COL ITEM
  # At max rows so this will be the last component in this column.
  # reset curr_row since we're not at the max col yet.
  # and increment to next col.
  defp render_col_item(
         %Grid{
           start_y: _start_y,
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           item_width: item_width,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col
         } = grid,
         module,
         data,
         opts
       )
       when curr_col < max_cols and curr_row == max_rows do
    %Grid{
      grid
      | next_x: next_x + item_width,
        next_y: next_y,
        curr_col: curr_col + 1,
        curr_row: 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  # RENDERING COL ITEM
  # At max cols so we need to move down to the next row for next pass.
  defp render_col_item(
         %Grid{
           start_y: _start_y,
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           item_height: item_height,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col
         } = grid,
         module,
         data,
         opts
       )
       when curr_col == max_cols and curr_row < max_rows do
    %Grid{
      grid
      | next_y: next_y + item_height,
        curr_row: curr_row + 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  # RENDERING COL ITEM
  # At max columns and max rows so the grid is full.
  # Increment to the next col, reset the row, and log a warning next
  # pass. We ignore any other primitives from here on.
  defp render_col_item(
         %Grid{
           start_y: start_y,
           next_x: next_x,
           next_y: next_y,
           graph: graph,
           max_rows: max_rows,
           max_cols: max_cols,
           curr_row: curr_row,
           curr_col: curr_col,
           item_width: item_width
         } = grid,
         module,
         data,
         opts
       )
       when curr_col == max_cols and curr_row == max_rows do
    %Grid{
      grid
      | next_x: next_x + item_width,
        next_y: start_y,
        curr_row: 1,
        curr_col: curr_col + 1,
        graph: module.add_to_graph(graph, data, Keyword.merge(opts, translate: {next_x, next_y}))
    }
  end

  defp render_col_item(
         grid,
         module,
         _data,
         _opts
       ) do
    overflow_error(module)
    grid
  end

  defp overflow_error(module) do
    Logger.warn("""
    #{IO.ANSI.red()}Grid overflowed
    #{IO.ANSI.yellow()}
    Could not fit module #{inspect(module)} in grid.
    Try adjusting your max :rows, and max :cols settings.
    """)
  end
end
