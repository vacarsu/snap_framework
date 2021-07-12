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

      Module.register_attribute(__MODULE__, :state, persist: true)

      Module.register_attribute(__MODULE__, :preload, persist: true)
      @preload unquote(opts[:preload]) || true

      @before_compile SnapFramework.Component

      SnapFramework.Macros.input_handler()
    end
  end

  defmacro defcomponent(name, data_type) do
    quote location: :keep do
      case unquote(data_type) do
        :string ->
          def validate(data) when is_bitstring(data), do: {:ok, data}
          def validate(_), do: :invalid_data
        :number ->
          def validate(data) when is_number(data), do: {:ok, data}
          def validate(_), do: :invalid_data
        :list ->
          def validate(data) when is_list(data), do: {:ok, data}
          def validate(_), do: :invalid_data
        :map ->
          def validate(data) when is_map(data), do: {:ok, data}
          def validate(_), do: :invalid_data
        :atom ->
          def validate(data) when is_atom(data), do: {:ok, data}
          def validate(_), do: :invalid_data
        :tuple ->
          def validate(data) when is_tuple(data), do: {:ok, data}
          def validate(_), do: :invalid_data
        :any ->
          def validate(data), do: {:ok, data}
        _ ->
          def validate(data), do: {:ok, data}
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
      def init(scene, data, opts \\ []) do
        Logger.debug(inspect data, pretty: true)
        scene =
          scene
          |> assign(
            state: @state
            |> Map.put_new(:module, unquote(caller.module))
            |> Map.put_new(:data, data)
            |> Map.put_new(:opts, opts)
            |> setup()
          )

        scene = recompile(scene)

        # graph =
        #   if not @preload do
        #     SnapFramework.Engine.compile(@template, [assigns: scene.assigns], info, __ENV__)
        #   else
        #     SnapFramework.Engine.compile_string(unquote(file), [assigns: scene.assigns], info, __ENV__)
        #   end

        {:ok, scene}
      end

      def recompile(scene) do
        info =
          Keyword.merge(
            [assigns: [state: scene.assigns.state], engine: SnapFramework.Engine],
            [file: unquote(caller.file), line: unquote(caller.line), trim: true]
          )

        graph =
          SnapFramework.Engine.compile_string(unquote(file), [assigns: [state: scene.assigns.state]], info, __ENV__)

        scene
        |> assign(graph: graph)
        |> push_graph(graph)
      end

      SnapFramework.Macros.effect_handlers()
    end
  end
end
