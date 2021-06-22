defmodule SnapFramework.Component do
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitives

  defmacro __using__(name: name, template: template, state: state) do
    quote do
      use Scenic.Component
      alias Scenic.Graph
      alias Scenic.Components
      alias Scenic.Primitive
      alias Scenic.Primitives
      import SnapFramework.Component
      require SnapFramework.Macros
      require EEx
      require Logger

      @name unquote(name)
      @using_effects false
      @template unquote(template)
      @components Components
      @primitives Primitives
      @state unquote(state)

      @before_compile SnapFramework.Component
    end
  end

  defmacro __before_compile__(_env) do
    caller = __CALLER__.module
    quote location: :keep do
      @using_effects false
      EEx.function_from_file(:def, :render, @template, [:assigns], engine: SnapFramework.Engine)

      def init(data, _) do
        state =
          @state
          |> Map.put_new(:module, unquote(caller))
          |> Map.put_new(:data, data)
        [init_graph] = render(state: state)
        state =
          state
          |> Map.put_new(:graph, init_graph)
        {:ok, state, push: state.graph}
      end
    end
  end

  defmacro defcomponent(name, data_type) do
    quote location: :keep do
      case unquote(data_type) do
        :string ->
          def verify(data) when is_bitstring(data), do: {:ok, data}
          def verify(_), do: :invalid_data
        :number ->
          def verify(data) when is_number(data), do: {:ok, data}
          def verify(_), do: :invalid_data
        :list ->
          def verify(data) when is_list(data), do: {:ok, data}
          def verify(_), do: :invalid_data
        :map ->
          def verify(data) when is_map(data), do: {:ok, data}
          def verify(_), do: :invalid_data
        :atom ->
          def verify(data) when is_atom(data), do: {:ok, data}
          def verify(_), do: :invalid_data
        :tuple ->
          def verify(data) when is_tuple(data), do: {:ok, data}
          def verify(_), do: :invalid_data
        :any ->
          def verify(data), do: {:ok, data}
        _ ->
          def verify(data), do: {:ok, data}
      end

      def unquote(name)(graph, data, options \\ [])

      def unquote(name)(%unquote(Graph){} = g, data, options) do
        add_to_graph(g, data, options)
      end

      def unquote(name)(%unquote(Primitive){module: SceneRef} = p, data, options) do
        Primitives.modify(p, {__MODULE__, data}, options)
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
