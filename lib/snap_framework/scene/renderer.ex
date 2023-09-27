defmodule SnapFramework.Scene.Renderer do
  def maybe_render(old_scene, new_scene, tracked_assigns) do
    case assigns_changed?(old_scene.assigns, new_scene.assigns, tracked_assigns) do
      true -> draw(new_scene)
      _ -> new_scene
    end
  end

  def maybe_render(old_scene, new_scene, additional_assigns, tracked_assigns) do
    new_scene_assigns = Map.merge(new_scene.assigns, additional_assigns)

    case assigns_changed?(old_scene.assigns, new_scene_assigns, tracked_assigns) do
      true -> draw(new_scene, new_scene_assigns)
      _ -> new_scene
    end
  end

  @spec draw(Scenic.Scene.t()) :: Scenic.Scene.t()
  def draw(scene) do
    graph_list = apply(scene.assigns.module, :render, [scene.assigns])

    graph =
      graph_list
      |> SnapFramework.Engine.Compiler.Scrubber.scrub()
      |> SnapFramework.Engine.Compiler.compile_graph()

    graph =
      if is_nil(Map.get(scene.assigns, :graph)) do
        graph
      else
        Scenic.Graph.map(graph, &map_scene_ids(&1, scene))
      end

    scene
    |> Scenic.Scene.assign(graph: graph)
    |> Scenic.Scene.push_graph(graph)
  end

  @spec draw(Scenic.Scene.t(), map) :: Scenic.Scene.t()
  def draw(scene, additional_assigns) do
    assigns = Map.merge(scene.assigns, additional_assigns)
    graph_list = apply(scene.assigns.module, :render, [assigns])

    graph =
      graph_list
      |> SnapFramework.Engine.Compiler.Scrubber.scrub()
      |> SnapFramework.Engine.Compiler.compile_graph()

    graph =
      if is_nil(Map.get(scene.assigns, :graph)) do
        graph
      else
        Scenic.Graph.map(graph, &map_scene_ids(&1, scene))
      end

    scene
    |> Scenic.Scene.assign(graph: graph)
    |> Scenic.Scene.push_graph(graph)
  end

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

  defp map_scene_ids(
         %{
           module: Scenic.Primitive.Component,
           data: {new_module, data, _scene_id},
           opts: opts
         } = prim,
         scene
       ) do
    ref = opts[:ref]
    old_prims = find_primitives(scene.assigns.graph, ref)
    old_prim = find_primitive(old_prims, new_module)

    if is_nil(old_prim) do
      prim
    else
      %{module: Scenic.Primitive.Component, data: {_old_module, _data, scene_id}} = old_prim

      %{prim | data: {new_module, data, scene_id}}
    end
  end

  defp map_scene_ids(prim, _scene) do
    prim
  end

  def find_primitives(graph, ref) do
    Scenic.Graph.find(graph, fn
      %{
        opts: opts
      } ->
        opts[:ref] == ref
    end)
  end

  def find_primitive(primitives, module) do
    Enum.find(primitives, fn
      %{
        data: {prim_module, _, _}
      } ->
        module == prim_module
    end)
  end
end
