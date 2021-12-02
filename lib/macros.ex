defmodule SnapFramework.Macros do
  @moduledoc false

  defmacro input_handler do
    quote do
      def handle_input(input, id, scene) do
        {response_type, new_scene} = scene.assigns.module.process_input(input, id, scene)
        {response_type, do_process(scene, new_scene)}
      end
    end
  end

  defmacro scene_handlers do
    quote do
      def handle_info(msg, scene) do
        {response_type, new_scene} = scene.assigns.module.process_info(msg, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_cast(msg, scene) do
        {response_type, new_scene} = scene.assigns.module.process_cast(msg, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_call(msg, from, scene) do
        {response_type, res, new_scene} = scene.assigns.module.process_call(msg, from, scene)
        {response_type, res, do_process(scene, new_scene)}
      end

      def handle_update(msg, opts, scene) do
        {response_type, new_scene} = scene.assigns.module.process_update(msg, opts, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_event(event, from_pid, scene) do
        case scene.assigns.module.process_event(event, from_pid, scene) do
          {:noreply, new_scene} ->
            {:noreply, do_process(scene, new_scene)}

          {:noreply, new_scene, opts} ->
            {:noreply, do_process(scene, new_scene), opts}

          {:halt, new_scene} ->
            {:halt, do_process(scene, new_scene)}

          {:halt, new_scene, opts} ->
            {:halt, do_process(scene, new_scene), opts}

          {:cont, event, new_scene} ->
            {:cont, event, do_process(scene, new_scene)}

          {:cont, event, new_scene, opts} ->
            {:cont, event, do_process(scene, new_scene), opts}

          {res, new_scene} ->
            {res, do_process(scene, new_scene)}

          {res, new_scene, opts} ->
            {res, do_process(scene, new_scene), opts}

          response ->
            response
        end
      end
    end
  end

  defmacro effect_handlers() do
    quote do
      defp do_process(old_scene, new_scene) do
        diff = diff_state(old_scene.assigns, new_scene.assigns)
        new_scene = process_effects(new_scene, diff)

        if old_scene.assigns.graph != new_scene.assigns.graph do
          push_graph(new_scene, new_scene.assigns.graph)
        else
          new_scene
        end
      end

      defp diff_state(old_state, new_state) do
        MapDiff.diff(old_state, new_state)
      end

      defp process_effects(scene, %{changed: :equal}) do
        scene
      end

      defp process_effects(scene, %{changed: :map_change, added: added}) do
        Enum.reduce(added, scene, fn {key, value}, acc ->
          if Enum.member?(@watch_registry, key) do
            scene = compile(scene)
          else
            acc |> change(key, value)
          end
        end)
      end

      defp change(scene, key, value) do
        effect =
          Map.get(@effects_registry, {key, value}) || Map.get(@effects_registry, {key, :any})

        if effect do
          run_effect(effect, scene)
        else
          scene
        end
      end

      defp run_effect(effect, scene) do
        Enum.reduce(effect, scene, fn {e_key, list}, acc ->
          case e_key do
            :run -> Enum.reduce(list, acc, fn item, s_acc -> run(s_acc, item) end)
            _ -> acc
          end
        end)
      end

      defp run(scene, func) do
        apply(@controller, func, [scene])
      end
    end
  end
end
