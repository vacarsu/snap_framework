defmodule SnapFramework.Engine.Builder.Layout do
  @moduledoc """
  ## Overview

  This module is responsible for taking the parsed EEx layout and builds the graph.
  """

  def build_layout(%Scenic.Graph{} = graph, children, padding, width, height, translate) do
    layout = %{
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

    Enum.reduce(children, layout, fn child, layout ->
      case child do
        [type: :component, module: module, data: data, opts: opts] ->
          children = if opts[:do], do: opts[:do], else: nil
          translate_and_render(layout, module, data, Keyword.put_new(opts, :children, children))

        [type: :component, module: module, data: data, opts: opts, children: children] ->
          translate_and_render(layout, module, data, Keyword.put_new(opts, :children, children))

        [type: :primitive, module: _module, data: _data, opts: _opts] ->
          layout

        [
          type: :layout,
          children: children,
          padding: padding,
          width: width,
          height: height,
          translate: translate
        ] ->
          {x, y} = translate
          {prev_x, prev_y} = layout.translate
          nested_layout = %{
            layout |
            # | last_x: x + prev_x + layout.padding,
            #   last_y: layout.last_y + y + layout.largest_height + layout.padding,
              padding: padding,
              width: width,
              height: height,
              translate: {x + prev_x, y + prev_y}
          }

          graph = build_layout(nested_layout, children).graph
          %{layout | graph: graph}

        "\n" ->
          layout

        list ->
          if is_list(list) do
            build_layout(layout, list)
          else
            layout
          end
      end
    end)
  end

  defp build_layout(layout, children) do
    Enum.reduce(children, layout, fn child, layout ->
      case child do
        [type: :component, module: module, data: data, opts: opts] ->
          children = if opts[:do], do: opts[:do], else: nil
          translate_and_render(layout, module, data, Keyword.put_new(opts, :children, children))

        [type: :component, module: module, data: data, opts: opts, children: children] ->
          translate_and_render(layout, module, data, Keyword.put_new(opts, :children, children))

        [type: :primitive, module: _module, data: _data, opts: _opts] ->
          layout

        [
          type: :layout,
          children: children,
          padding: padding,
          width: width,
          height: height,
          translate: translate
        ] ->
          {x, y} = translate
          {prev_x, prev_y} = layout.translate
          nested_layout = %{
            layout |
            # | last_x: x + prev_x + layout.padding,
            #   last_y: layout.last_y + y + layout.largest_height + layout.padding,
              padding: padding,
              width: width,
              height: height,
              translate: {x + prev_x, y + prev_y}
          }

          build_layout(nested_layout, children)

        "\n" ->
          layout

        list ->
          if is_list(list) do
            build_layout(layout, list)
          else
            layout
          end
      end
    end)
  end

  defp translate_and_render(layout, module, data, opts) do
    {l, t, r, b} = get_bounds(module, data, opts)
    {tx, ty} = layout.translate

    layout =
      case fits_in_x?(r + layout.last_x + layout.padding, layout.width) do
        true ->
          x = l + layout.last_x + layout.padding + tx
          y = layout.last_y + ty

          %{
            layout
            | last_x: r + layout.last_x + layout.padding,
              graph:
                module.add_to_graph(layout.graph, data, Keyword.merge(opts, translate: {x, y}))
          }

        false ->
          x = l + tx + layout.padding
          y = t + layout.last_y + layout.largest_height + layout.padding

          %{
            layout
            | last_x: l + tx + r + layout.padding,
              last_y: t + layout.last_y + layout.largest_height + layout.padding,
              graph:
                module.add_to_graph(layout.graph, data, Keyword.merge(opts, translate: {x, y}))
          }
      end

    layout = if r > layout.largest_width, do: %{layout | largest_width: r}, else: layout
    if b > layout.largest_height, do: %{layout | largest_height: b}, else: layout
  end

  defp get_bounds(mod, data, opts) do
    mod.bounds(data, opts)
  end

  defp fits_in_x?(potential_x, max_x), do: potential_x <= max_x

  # defp fits_in_y?(potential_y, max_y), do: potential_y <= max_y
end
