defmodule SnapFramework.Engine.Builder do
  @moduledoc """
  ## Overview

  This module is responsible for taking the parsed EEx template and building the graph.
  """

  def build_graph(list, acc \\ %{}) do
    Enum.reduce(list, acc, fn item, acc ->
      case item do
        [type: :graph, opts: opts] -> Scenic.Graph.build(opts)

        [type: :component, module: module, data: data, opts: opts] ->
          children = if opts[:do], do: opts[:do], else: nil
          acc |> module.add_to_graph(data, Keyword.put_new(opts, :children, children))

        [type: :component, module: module, data: data, opts: opts, children: children] ->

          acc |> module.add_to_graph(data, Keyword.put_new(opts, :children, children))

        [type: :primitive, module: module, data: data, opts: opts] ->
          acc |> module.add_to_graph(data, opts)

        "\n" -> acc

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
