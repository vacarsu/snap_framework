defmodule SnapFramework.Component do
  alias Scenic.Graph
  alias Scenic.Primitive
  require Logger

  defmacro __using__([name: name, template: template, assigns: assigns, opts: opts]) do
    quote do
      use SnapFramework.Scene,
        name: unquote(name),
        template: unquote(template),
        assigns: unquote(assigns),
        opts: unquote(opts)

      import SnapFramework.Component
      alias Scenic.Primitives
      require SnapFramework.Macros
      require EEx
      require Logger

      Module.register_attribute(__MODULE__, :assigns, persist: true)

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
        assigns = Keyword.merge(@assigns, [
          module: unquote(caller.module),
          data: data,
          opts: opts,
          children: opts[:children]
        ])
        scene =
          scene
          |> assign(assigns)
          |> setup()

        {:ok, compile(scene)}
      end

      def compile(scene) do
        info =
          Keyword.merge(
            [
              assigns: scene.assigns,
              engine: SnapFramework.Engine
            ],
            [
              file: unquote(caller.file),
              line: unquote(caller.line), trim: true
            ]
          )

        compiled_list =
          SnapFramework.Engine.compile_string(unquote(file), [
            assigns: scene.assigns
          ], info, __ENV__)

        graph = build_graph(compiled_list)

        scene
        |> assign(graph: graph)
        |> push_graph(graph)
      end

      SnapFramework.Macros.effect_handlers()
    end
  end
end
