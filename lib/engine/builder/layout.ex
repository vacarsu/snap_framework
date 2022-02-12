defmodule SnapFramework.Engine.Builder.Layout do
  @moduledoc """
  ## Overview

  This module is responsible for taking the parsed EEx layout and builds the graph.
  """

  require Logger
  alias __MODULE__

  defstruct last_x: 0,
            last_y: 0,
            padding: 0,
            width: nil,
            height: nil,
            largest_width: 0,
            largest_height: 0,
            graph: nil,
            translate: {0, 0}

  def build(graph,
        type: :layout,
        padding: padding,
        width: width,
        height: height,
        translate: translate,
        children: children
      ) do
    layout = %Layout{
      last_x: 0,
      last_y: 0,
      padding: padding,
      width: width,
      height: height,
      largest_width: 0,
      largest_height: 0,
      graph: graph,
      translate: translate
    }

    do_build(layout, children).graph
  end

  def build(graph, _), do: graph

  defp do_build(layout, children) do
    Enum.reduce(children, layout, &render_layout/2)
  end

  defp render_layout(child, layout) do
    render_child(child, layout)
  end

  defp render_child(
         [type: :component, module: module, data: data, opts: opts, children: children],
         layout
       ) do
    translate_and_render(layout, module, data, Keyword.put_new(opts, :children, children))
  end

  defp render_child(
         [
           type: :layout,
           padding: padding,
           width: width,
           height: height,
           translate: translate,
           children: children
         ],
         layout
       ) do
    {x, y} = translate

    nested_layout = %Layout{
      layout
      | padding: padding,
        width: width,
        height: height,
        last_x: x,
        last_y: y,
        translate: translate
    }

    graph = do_build(nested_layout, children).graph
    %Layout{layout | graph: graph}
  end

  defp render_child(_, layout), do: layout

  defp translate_and_render(layout, module, data, opts) do
    {l, t, r, b} = get_bounds(module, data, opts)
    {tx, ty} = layout.translate

    layout =
      case fits_in_x?(r + layout.last_x + layout.padding, layout.width) do
        true ->
          x = l + layout.last_x + layout.padding + tx
          y = layout.last_y + ty

          %Layout{
            layout
            | last_x: r + layout.last_x + layout.padding,
              graph:
                module.add_to_graph(layout.graph, data, Keyword.merge(opts, translate: {x, y}))
          }

        false ->
          x = l + tx + layout.padding
          y = t + layout.last_y + layout.largest_height + layout.padding

          %Layout{
            layout
            | last_x: l + tx + r + layout.padding,
              last_y: t + layout.last_y + layout.largest_height + layout.padding,
              graph:
                module.add_to_graph(layout.graph, data, Keyword.merge(opts, translate: {x, y}))
          }
      end

    layout = if r > layout.largest_width, do: %Layout{layout | largest_width: r}, else: layout
    if b > layout.largest_height, do: %Layout{layout | largest_height: b}, else: layout
  end

  defp get_bounds(mod, data, opts) do
    mod.bounds(data, opts)
  end

  defp fits_in_x?(potential_x, max_x), do: potential_x <= max_x

  # defp fits_in_y?(potential_y, max_y), do: potential_y <= max_y
end
