defmodule SnapFramework.Component do
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitives

  defmacro __using__([name: name, template: template, state: state, opts: opts]) do
    quote do
      use SnapFramework.Scene,
        name: unquote(name),
        template: unquote(template),
        state: unquote(state),
        opts: unquote(opts)

      import SnapFramework.Component
      require SnapFramework.Macros
      require EEx
      require Logger

      @before_compile SnapFramework.Component

      SnapFramework.Macros.input_handler()
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

  defmacro __before_compile__(_env) do
    caller = __CALLER__.module
    quote location: :keep do
      EEx.function_from_file(:def, :render, @template, [:assigns], engine: SnapFramework.Engine)

      def init(data, opts \\ []) do
        state =
          @state
          |> Map.put_new(:module, unquote(caller))
          |> Map.put_new(:data, data)
          |> Map.put_new(:opts, opts)
        [init_graph] = render(state: state)
        state =
          state
          |> Map.put_new(:graph, init_graph)
        {:ok, state, push: state.graph}
      end

      SnapFramework.Macros.effect_handlers()
    end
  end
end
