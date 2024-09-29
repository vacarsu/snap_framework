defmodule SnapFramework.Scene.Renderer do
  @moduledoc """
  This module handles the drawing and redrawing of scene.

  You should not have to call any of the functions in this module directly.
  """
  alias Scenic.Primitive
  alias Scenic.Scene
  alias Scenic.Graph

  @spec maybe_render(Scene.t(), Scene.t(), list()) :: Scene.t()
  def maybe_render(old_scene, new_scene, tracked_assigns) do
    case assigns_changed?(old_scene.assigns, new_scene.assigns, tracked_assigns) do
      true -> draw(new_scene)
      _ -> new_scene
    end
  end

  @spec maybe_render(Scene.t(), Scene.t(), any(), list()) :: Scene.t()
  def maybe_render(old_scene, new_scene, additional_assigns, tracked_assigns) do
    new_scene_assigns = Map.merge(new_scene.assigns, additional_assigns)

    case assigns_changed?(old_scene.assigns, new_scene_assigns, tracked_assigns) do
      true -> draw(new_scene, new_scene_assigns)
      _ -> new_scene
    end
  end

  @spec draw(Scene.t()) :: Scene.t()
  def draw(scene) do
    do_draw(scene, scene.assigns)
  end

  @spec draw(Scene.t(), any()) :: Scene.t()
  def draw(scene, additional_assigns) do
    do_draw(scene, Map.merge(scene.assigns, additional_assigns))
  end

  defp do_draw(scene, assigns) do
    graph_list = apply(scene.assigns.module, :render, [assigns])

    graph =
      graph_list
      |> SnapFramework.Engine.Compiler.Scrubber.scrub()
      |> SnapFramework.Engine.Compiler.compile_graph()

    graph =
      case Map.get(scene.assigns, :graph) do
        nil -> graph
        _ -> Graph.map(graph, &map_scene_ids(&1, scene.assigns.graph))
      end

    scene
    |> Scene.assign(graph: graph)
    |> Scene.push_graph(graph)
  end

  @spec assigns_changed?(any(), any(), list()) :: boolean()
  defp assigns_changed?(old_assigns, new_assigns, tracked_assigns) do
    case MapDiff.diff(old_assigns, new_assigns) do
      %{added: added} ->
        Enum.reduce_while(added, false, fn {key, _}, acc ->
          if key in tracked_assigns do
            {:halt, true}
          else
            {:cont, acc}
          end
        end)

      _ ->
        false
    end
  end

  @spec map_scene_ids(Primitive.t(), Graph.t()) :: Primitive.t()
  defp map_scene_ids(
         %Scenic.Primitive{
           module: Scenic.Primitive.Component,
           data: {new_module, data, _scene_id},
           opts: opts
         } = prim,
         old_graph
       ) do
    old_prims = find_primitives(old_graph, opts[:ref])

    case find_primitive(old_prims, new_module) do
      nil ->
        prim

      %{module: Scenic.Primitive.Component, data: {_old_module, _data, scene_id}} ->
        %{prim | data: {new_module, data, scene_id}}
    end
  end

  @spec map_scene_ids(Primitive.t(), Graph.t()) :: Primitive.t()
  defp map_scene_ids(prim, _scene) do
    prim
  end

  @spec find_primitives(Graph.t(), any()) :: list()
  defp find_primitives(graph, ref) do
    Graph.reduce(graph, [], fn p, acc ->
      p
      |> finder(ref)
      |> case do
        true -> [p | acc]
        false -> acc
      end
    end)
    |> Enum.reverse()
  end

  defp finder(%{opts: opts}, ref) do
    opts[:ref] == ref
  end

  @spec find_primitive(list(), module()) :: Primitive.t() | nil
  defp find_primitive(primitives, module) do
    Enum.find(primitives, fn
      %{
        data: {prim_module, _, _}
      } ->
        module == prim_module
    end)
  end
end
