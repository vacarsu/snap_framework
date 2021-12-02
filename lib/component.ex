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
      template: "lib/scenes/my_component.eex",
      controller: :none,
      assigns: []

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

  @opts_schema [
    name: [required: false, type: :atom],
    template: [required: true, type: :string],
    controller: [required: true, type: :any],
    assigns: [required: true, type: :any],
    opts: [required: false, type: :any]
  ]

  defmacro __using__(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, opts} ->
        quote do
          use SnapFramework.Scene,
            template: unquote(opts[:template]),
            controller: unquote(opts[:controller]),
            assigns: unquote(opts[:assigns]),
            opts: unquote(opts[:opts]),
            type: :component

          import SnapFramework.Component
          alias Scenic.Primitives
          require SnapFramework.Macros
          require EEx
          require Logger

          Module.register_attribute(__MODULE__, :assigns, persist: true)

          Module.register_attribute(__MODULE__, :preload, persist: true)
        end

      {:error, error} ->
        raise Exception.message(error)
    end
  end

  defmacro defcomponent(name, data_type) do
    quote do
      case unquote(data_type) do
        :string ->
          def validate(data) when is_bitstring(data), do: {:ok, data}

        :number ->
          def validate(data) when is_number(data), do: {:ok, data}

        :list ->
          def validate(data) when is_list(data), do: {:ok, data}

        :map ->
          def validate(data) when is_map(data), do: {:ok, data}

        :atom ->
          def validate(data) when is_atom(data), do: {:ok, data}

        :tuple ->
          def validate(data) when is_tuple(data), do: {:ok, data}

        :any ->
          def validate(data), do: {:ok, data}

        _ ->
          def validate(data), do: {:ok, data}
      end

      def validate(data) do
        {
          :error,
          """
          #{IO.ANSI.red()}Invalid #{__MODULE__} specification
          Received: #{inspect(data)}
          #{IO.ANSI.yellow()}
          The data for a #{__MODULE__} is just the #{inspect(unquote(data_type))} string to be displayed in the button.#{IO.ANSI.default_color()}
          """
        }
      end

      def unquote(name)(graph, data, options \\ [])

      def unquote(name)(%Graph{} = g, data, options) do
        add_to_graph(g, data, options)
      end

      def unquote(name)(
            %Scenic.Primitive{module: Scenic.Primitive.Component, data: {mod, _, id}} = p,
            data,
            options
          ) do
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
end
