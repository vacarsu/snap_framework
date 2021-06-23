defmodule SnapFramework.Macros do
  alias Scenic.Graph
  alias Scenic.Primitive

  defmacro input_handler do
    quote do
      def handle_input(event, context, state) do
        {response_type, new_state} = state.module.process_input(event, context, state)
        diff = diff_state(state, new_state)
        new_state = process_effects(new_state, diff)
        {response_type, new_state, push: new_state.graph}
      end
    end
  end

  defmacro scene_handlers do
    quote do
      def handle_info(msg, state) do
        {response_type, new_state} = state.module.process_info(msg, state)
        diff = diff_state(state, new_state)
        new_state = process_effects(new_state, diff)
        {response_type, new_state, push: new_state.graph}
      end

      def handle_call(msg, from, state) do
        {response_type, new_state} = state.module.process_call(msg, from, state)
        diff = diff_state(state, new_state)
        new_state = process_effects(new_state, diff)
        {response_type, new_state, push: new_state.graph}
      end

      def handle_cast(msg, state) do
        {response_type, new_state} = state.module.process_cast(msg, state)
        diff = diff_state(state, new_state)
        new_state = process_effects(new_state, diff)
        {response_type, new_state, push: new_state.graph}
      end

      def filter_event(event, from_pid, state) do
        {response_type, new_state} = state.module.process_event(event, from_pid, state)
        diff = diff_state(state, new_state)
        new_state = process_effects(new_state, diff)
        {response_type, new_state, push: new_state.graph}
      end
    end
  end

  defmacro effect_handlers() do
    quote do
      defp diff_state(old_state, new_state) do
        MapDiff.diff(old_state, new_state)
      end

      defp process_effects(state, %{changed: :equal}) do
        state
      end

      defp process_effects(state, %{changed: :map_change, added: added}) do
        Enum.reduce(added, state, fn {key, _value}, acc ->
          acc |> change(key)
        end)
      end

      defp change(state, key) do
        effect = Map.get(@effects_registry, key)

        if effect do
          Enum.reduce(effect, state, fn {e_key, list}, acc ->
            case e_key do
              :add -> Enum.reduce(list, acc, fn item, s_acc -> add(s_acc, item) end)
              :modify -> Enum.reduce(list, acc, fn item, s_acc -> modify(s_acc, item) end)
              :delete -> Enum.reduce(list, acc, fn item, s_acc -> delete(s_acc, item) end)
              _ -> acc
            end
          end)
        else
          state
        end
      end

      defp add(state, {cmp_fun, state_key, opts}) do
        state.graph
        |> cmp_fun.(state[state_key], opts)
        |>(&%{state | graph: &1}).()
      end

      defp modify(state, {cmp_id, {cmp_fun, state_key}}) when is_atom(state_key) do
        state.graph
        |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, state[state_key], []) end)
        |>(&%{state | graph: &1}).()
      end

      defp modify(state, {cmp_id, {cmp_fun, state_key, opts}}) when is_atom(state_key) and is_list(opts) do
        state.graph
        |> Graph.modify(cmp_id, fn g -> cmp_fun.(g, state[state_key], opts) end)
        |>(&%{state | graph: &1}).()
      end

      defp modify(state, {cmp_id, {cmp_fun, opts}}) when is_list(opts) do
        state.graph
        |> Graph.modify(cmp_id, fn g -> Primitive.merge_opts(g, opts) end)
        |>(&%{state | graph: &1}).()
      end

      defp delete(state, cmp_id) do
        state.graph
        |> Graph.delete(cmp_id)
        |>(&%{state | graph: &1}).()
      end
    end
  end
end
