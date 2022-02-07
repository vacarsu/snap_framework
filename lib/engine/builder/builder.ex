defmodule SnapFramework.Engine.Builder do
  @moduledoc """
  ## Overview

  This module is responsible for taking the parsed EEx template and building the graph.
  """

  alias SnapFramework.Engine.Builder

  def build_graph(list, acc \\ %{}) do
    Enum.reduce(list, acc, fn item, acc ->
      case item do
        [type: :graph, opts: opts] ->
          Scenic.Graph.build(opts)

        [type: :component, module: module, data: data, opts: opts] ->
          children = if opts[:do], do: opts[:do], else: nil
          acc |> module.add_to_graph(data, Keyword.put_new(opts, :children, children))

        [type: :component, module: module, data: data, opts: opts, children: children] ->
          acc |> module.add_to_graph(data, Keyword.put_new(opts, :children, children))

        [type: :primitive, module: module, data: data, opts: opts] ->
          acc |> module.add_to_graph(data, opts)

        [
          type: :layout,
          children: children,
          padding: padding,
          width: width,
          height: height,
          translate: translate
        ] ->
          Builder.Layout.build_layout(acc, children, padding, width, height, translate).graph

        [
          type: :grid,
          children: children,
          item_width: item_width,
          item_height: item_height,
          translate: translate
        ] ->
          Builder.Grid.build_grid(acc, children, item_width, item_height, translate).graph

        "\n" ->
          acc

        list ->
          if is_list(list) do
            build_graph(list, acc)
          else
            acc
          end
      end
    end)
  end
end
