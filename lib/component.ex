defmodule SnapFramework.Component do
  alias Scenic.Graph
  alias Scenic.Primitive
  require SnapFramework.Macros
  require Logger

  @moduledoc """
  ## Overview

  SnapFramework.Component is nearly identical to a Scene. The main different is the addition of the defcomponent macro,
  as well as the addition of the scenic opts key.
  defcomponent build out your scenic validate function and helper functions, automatically so you don't have to.

  ``` elixir
  defmodule Example.Component.MyComponent do
    use SnapFramework.Component,
      name: :my_component,
      template: "lib/scenes/my_component.eex",
      controller: :none,
      assigns: [],
      opts: []

    defcomponent :my_component, :tuple
  end
  ```

  The above example defines a component that takes in a tuple for data. and build your helper function defined as ```my_component/3```

  ## Templates

  Component templates also have an additional feature that primitives or scene templates do not have. You can inject children into them.
  Lets write a basic icon button component that takes an icon child.

  ``` elixir
  # template
  <%= graph font_size: 20 %>

  <%= primitive Scenic.Primitive.Circle,
      15,
      id: :bg,
      translate: {23, 23}
  %>

  @children

  # component module
  defmodule Example.Component.IconButton do
    use SnapFramework.Component,
      name: :icon_button,
      template: "lib/icons/icon_button/icon_button.eex",
      controller: :none,
      assigns: [],
      opts: []

    defcomponent :icon_button, :any
  end
  ```

  Now lets see how to use this component with children in a scene. This assumes we've already made an icon component.

  ``` elixir
    <%= graph font_size: 20 %>

    <%= component Example.Component.IconButton,
        nil,
        id: :icon_button
    do %>
      <%= component Example.Component.Icon,
          @icon,
          id: :icon
      %>
    <% end %>
  ```

  That's all there is to putting children in components!
  """

  defmacro __using__([name: name, template: template, controller: controller, assigns: assigns, opts: opts]) do
    quote do
      use SnapFramework.Scene,
        name: unquote(name),
        template: unquote(template),
        controller: unquote(controller),
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

      def unquote(name)(%Graph{} = g, data, options) do
        add_to_graph(g, data, options)
      end

      def unquote(name)(%Scenic.Primitive{module: Scenic.Primitive.Component, data: {mod, _, id}} = p, data, options) do
        data =
          case mod.validate(data) do
            {:ok, data} -> data
            {:error, msg} -> raise msg
          end

        Primitive.put(p, {__MODULE__, data, id}, options)
      end

      def unquote(name)(%Scenic.Primitive{module: mod} = p, data, opts) do
        data =
          case mod.validate(data) do
            {:ok, data} -> data
            {:error, error} -> raise Exception.message(error)
          end

        Primitive.put(p, data, opts)
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
          |> compile()
          |> mounted()

        {:ok, scene}
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

        graph = SnapFramework.Engine.Builder.build_graph(compiled_list)

        scene
        |> assign(graph: graph)
        |> push_graph(graph)
      end

      # SnapFramework.Macros.effect_handlers()
      SnapFramework.Macros.effect_handlers()
    end
  end
end
