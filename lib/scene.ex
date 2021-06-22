defmodule SnapFramework.Scene do
  alias Scenic.Graph
  require Logger

  defmacro __using__(name: name, template: template, state: state) do
    quote do
      use Scenic.Scene
      alias Scenic.Graph
      alias Scenic.Components
      alias Scenic.Primitives
      # import SnapFramework.Graph
      import SnapFramework.Scene
      require SnapFramework.Macros
      require EEx
      require Logger

      @name unquote(name)
      @using_effects false
      @template unquote(template)
      @components Components
      @primitives Primitives
      @state unquote(state)

      @before_compile SnapFramework.Scene
    end
  end

  defmacro __before_compile__(_env) do
    caller = __CALLER__.module
    quote location: :keep do
      EEx.function_from_file(:def, :render, @template, [:assigns], engine: SnapFramework.Engine)

      def init(_, _) do
        [init_graph] = render(state: @state)
        state =
          @state
          |> Map.put_new(:module, unquote(caller))
          |> Map.put_new(:graph, init_graph)
        {:ok, state, push: state.graph}
      end

      def set_state(patch) do
        send(self(), { :set_state, patch })
      end
    end
  end

  defmacro use_effect(ks, cmp_id, cmp_fun) when is_list(ks) do
    quote location: :keep, bind_quoted: [ks: ks, cmp_id: cmp_id, cmp_fun: cmp_fun] do
      if not @using_effects do
        @using_effects true
        SnapFramework.Macros.scene_handlers()
      end

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
      if not @using_effects do
        @using_effects true
        SnapFramework.Macros.scene_handlers()
      end

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
