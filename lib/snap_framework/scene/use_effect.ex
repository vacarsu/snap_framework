defmodule SnapFramework.UseEffect do
  def do_process(
        old_scene,
        new_scene,
        caller_file,
        caller_line,
        template_file,
        watch_registry,
        effects_registry,
        controller
      ) do
    diff = diff_state(old_scene.assigns, new_scene.assigns)

    new_scene =
      process_effects(
        new_scene,
        diff,
        caller_file,
        caller_line,
        template_file,
        watch_registry,
        effects_registry,
        controller
      )

    if old_scene.assigns.graph != new_scene.assigns.graph do
      Scenic.Scene.push_graph(new_scene, new_scene.assigns.graph)
    else
      new_scene
    end
  end

  def diff_state(old_state, new_state) do
    MapDiff.diff(old_state, new_state)
  end

  def process_effects(scene, %{changed: :equal}, _, _, _, _, _, _) do
    scene
  end

  def process_effects(
        scene,
        %{changed: :map_change, added: added},
        caller_file,
        caller_line,
        template_file,
        watch_registry,
        effects_registry,
        controller
      ) do
    Enum.reduce(added, scene, fn {key, value}, acc ->
      if Enum.member?(watch_registry, key) do
        SnapFramework.Scene.compile(scene, caller_file, caller_line, template_file)
      else
        acc |> change(key, value, effects_registry, controller)
      end
    end)
  end

  def change(scene, key, value, effects_registry, controller) do
    effect = Map.get(effects_registry, {key, value}) || Map.get(effects_registry, {key, :any})

    if effect do
      run_effect(effect, scene, controller)
    else
      scene
    end
  end

  def run_effect(effect, scene, controller) do
    Enum.reduce(effect, scene, fn {e_key, list}, acc ->
      case e_key do
        :run -> Enum.reduce(list, acc, fn item, s_acc -> run(s_acc, item, controller) end)
        _ -> acc
      end
    end)
  end

  def run(scene, func, controller) do
    apply(controller, func, [scene])
  end
end
