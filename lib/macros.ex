defmodule SnapFramework.Macros do
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
    end
  end
end
