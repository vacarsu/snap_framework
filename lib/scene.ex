defmodule SnapFramework.Scene do
  alias Scenic.Graph
  require Logger

  defmacro __using__(name: name, template: template, state: state) do
    quote do
      use Scenic.Scene
      alias Scenic.Graph
      alias Scenic.Components
      alias Scenic.Primitives
      import SnapFramework.Scene
      require EEx
      require Logger

      @name unquote(name)
      @template unquote(template)
      @components Components
      @primitives Primitives
      @state unquote(state)

      @before_compile SnapFramework.Scene

      def handle_info({:set_state, {key, val}}, state) do
        state =
          %{state | key => val}
          |> change(key)
        IO.puts(inspect(state))
        {:noreply, state, push: state.graph}
      end

      def filter_event(event, from_pid, state) do
        Logger.debug("calling parent event handle")
        {response_type, new_state} = state.module.filter_event(event, state)
        diff = diff_state(state, new_state)
        Logger.debug(diff)
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
        Logger.debug("processing effects for changes")
        Enum.reduce(added, state, fn {key, _value}, acc ->
          acc |> change(key)
        end)
      end
    end
  end

  defmacro __before_compile__(_env) do
    caller = __CALLER__.module
    quote do
      EEx.function_from_file(:def, :render, @template, [:assigns], engine: SnapFramework.Engine)

      def init(_, _) do
        [init_graph] = render(graph: @state.graph, state: @state, components: @components, primitives: @primitives)
        state = Map.put_new(@state, :module, unquote(caller))
        state = %{state | graph: init_graph}
        {:ok, state, push: state.graph}
      end

      def set_state(patch) do
        send(self(), { :set_state, patch })
      end
    end
  end

  defmacro use_effect(ks, cmp_id, cmp_fun) when is_list(ks) do
    quote location: :keep, bind_quoted: [ks: ks, cmp_id: cmp_id, cmp_fun: cmp_fun] do
      Enum.map(ks, fn k ->
        def unquote(k)(state) do
          state.graph
          |> Graph.modify(unquote(cmp_id), fn g -> unquote(cmp_fun).(g, state[unquote(k)], []) end)
          |>(&%{state | graph: &1}).()
        end

        def change(state, k) do
          unquote(k)(state)
        end
      end)
    end
  end

  defmacro use_effect(k, cmp_id, cmp_fun) when is_atom(k) do
    quote location: :keep do
      def unquote(k)(state) do
        state.graph
        |> Graph.modify(unquote(cmp_id), fn g -> unquote(cmp_fun).(g, state[unquote(k)], []) end)
        |>(&%{state | graph: &1}).()
      end

      def change(state, k) do
        unquote(k)(state)
      end
    end
  end
end
