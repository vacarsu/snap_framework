defmodule SnapFramework.Macros do
  alias Scenic.Graph
  alias Scenic.Primitive

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
        # IO.puts("before push_graph")
        # push_graph(new_scene, new_scene.assigns.graph)
        # IO.puts("after push_graph")
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
        effect = Map.get(@effects_registry, {key, value}) || Map.get(@effects_registry, {key, :any})

        if effect do
          run_effect(effect, scene)
        else
          scene
        end
      end

      defp run_effect(effect, scene) do
        Enum.reduce(effect, scene, fn {e_key, list}, acc ->
          case e_key do
            :set -> Enum.reduce(list, acc, fn item, s_acc -> set(s_acc, item) end)
            :add -> Enum.reduce(list, acc, fn item, s_acc -> add(s_acc, item) end)
            :modify -> Enum.reduce(list, acc, fn item, s_acc -> modify(s_acc, item) end)
            :delete -> Enum.reduce(list, acc, fn item, s_acc -> delete(s_acc, item) end)
            :run -> Enum.reduce(list, acc, fn item, s_acc -> run(s_acc, item) end)
            _ -> acc
          end
        end)
      end

      defp run(scene, func) do
        apply(@controller, func, [scene])
      end

      defp set(scene, {key, value}) do
        assigns = Keyword.put([], key, value)
        new_scene = assign(scene, assigns)
        diff = diff_state(scene.assigns, new_scene.assigns)
        process_effects(new_scene, diff)
      end

      defp add(scene, {cmp_fun, {:assigns, assign_key}, opts}) when is_atom(assign_key) do
        graph =
          scene.assigns.graph
          |> cmp_fun.(scene.assigns[assign_key], opts)

        assign(scene, graph: graph)
      end

      defp add(scene, {cmp_fun, {:assigns, nested_keys}, opts}) do
        value =
          Enum.reduce(nested_keys, nil, fn key, acc ->
            acc = if is_nil(acc), do: scene.assigns[key], else: acc[key]
          end)

        graph =
          scene.assigns.graph
          |> cmp_fun.(value, opts)

        assign(scene, graph: graph)
      end

      defp add(scene, {cmp_fun, data, opts}) do
        graph =
          scene.assigns.graph
          |> cmp_fun.(data, opts)

        assign(scene, graph: graph)
      end

      defp modify(scene, {cmp_id, {cmp_fun, {:assigns, assign_key}}})
      when is_atom(assign_key)
      do
        graph =
          scene.assigns.graph
          |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, scene.assigns[assign_key], []) end)

        assign(scene, graph: graph)
      end

      defp modify(scene, {cmp_id, {cmp_fun, {:assigns, nested_keys}}})
      when is_list(nested_keys)
      do
        value =
          Enum.reduce(nested_keys, nil, fn key, acc ->
            acc = if is_nil(acc), do: scene.assigns[key], else: acc[key]
          end)

        graph =
          scene.assigns.graph
          |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, value, []) end)

        assign(scene, graph: graph)
      end

      defp modify(scene, {cmp_id, {cmp_fun, opts}}) when is_list(opts) do
        graph =
        scene.assigns.graph
        |> Graph.modify(cmp_id, fn g -> Primitive.merge_opts(g, opts) end)

        assign(scene, graph: graph)
      end

      defp modify(scene, {cmp_id, {cmp_fun, value}}) do
        graph =
        scene.assigns.graph
        |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, value, []) end)

        assign(scene, graph: graph)
      end

      defp modify(scene, {cmp_id, {cmp_fun, {:assigns, assign_key}, opts}})
      when is_atom(assign_key) and is_list(opts)
      do
        graph =
          scene.assigns.graph
          |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, scene.assigns[assign_key], opts) end)

        assign(scene, graph: graph)
      end

      defp modify(scene, {cmp_id, {cmp_fun, {:assigns, nested_keys}, opts}})
      when is_list(nested_keys) and is_list(opts)
      do
        value =
          Enum.reduce(nested_keys, nil, fn key, acc ->
            acc = if is_nil(acc), do: scene.assigns[key], else: acc[key]
          end)

        graph =
          scene.assigns.graph
          |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, value, opts) end)

        assign(scene, graph: graph)
      end

      defp modify(scene, {cmp_id, {cmp_fun, value, opts}}) when is_list(opts) do
        graph =
          scene.assigns.graph
          |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, value, opts) end)

        assign(scene, graph: graph)
      end

      defp delete(scene, cmp_id) do
        graph =
        scene.assigns.graph
        |> Graph.delete(cmp_id)

        assign(scene, graph: graph)
      end
    end
  end
end
