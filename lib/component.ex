defmodule SnapFramework.Component do
  alias Scenic.Graph
  alias Scenic.Primitive
  require Logger

  defmacro __using__([name: name, template: template, state: state, opts: opts]) do
    quote do
      use SnapFramework.Scene,
        name: unquote(name),
        template: unquote(template),
        state: unquote(state),
        opts: unquote(opts)

      import SnapFramework.Component
      alias Scenic.Primitives
      require SnapFramework.Macros
      require EEx
      require Logger

      @preload unquote(opts[:preload]) || true

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
        Primitive.put(p, {__MODULE__, data}, options)
      end
    end
  end

  defmacro __before_compile__(env) do
    caller = __CALLER__
    template = Module.get_attribute(env.module, :template)
    preload = Module.get_attribute(env.module, :preload)
    file = if preload, do: File.read!(template), else: nil
    quote location: :keep do

      def init(data, opts \\ []) do
        state =
          @state
          |> Map.put_new(:module, unquote(caller.module))
          |> Map.put_new(:data, data)
          |> Map.put_new(:opts, opts)
          |> setup()

        context = [file: unquote(caller.file), line: unquote(caller.line)]
        info = Keyword.merge([assigns: [state: state], engine: SnapFramework.Engine], [file: unquote(caller.file), line: unquote(caller.line)])
        # quoted = EEx.compile_file(@template, info)
        # Logger.debug(inspect quoted, pretty: true)
        # ast =
        #   Code.eval_quoted(quoted, [state: state], __ENV__)

        # [graph] = elem(ast, 0)
        graph =
          if not @preload do
            Logger.info("not preloaded")
            SnapFramework.Engine.compile(@template, [assigns: [state: state]], info, __ENV__)
          else
            Logger.info("preloaded")
            SnapFramework.Engine.compile_string(unquote(file), [assigns: [state: state]], info, __ENV__)
          end

        state =
          state
          |> Map.put_new(:graph, graph)
        {:ok, state, push: state.graph}
      end

      SnapFramework.Macros.effect_handlers()
    end
  end
end
