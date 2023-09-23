defmodule SnapFramework.Component do
  @moduledoc """
  ## Overview

  SnapFramework.Component is nearly identical to a Scene. The main difference is it automatically generates some helper functions and validation functions based
  on the options you add when ```use``` is called.

  ``` elixir
  defmodule Example.Component.MyComponent do
    use SnapFramework.Component,
      name: :my_component,
      type: :tuple
  end
  ```

  The above example defines a component that takes in a tuple for data and builds your helper function defined as ```my_component/3```

  Component templates also have an additional feature that primitives or scene templates do not have. You can inject children into them.
  Lets write a basic icon button component that takes an icon child.

  ``` elixir
  defmodule Example.Component.IconButton do
    use SnapFramework.Component,
      name: :icon_button

    def render(assigns) do
      ~G\"""
      <%= graph font_size: 20 %>

      <%= primitive Scenic.Primitive.Circle,
          15,
          id: :bg,
          translate: {23, 23}
      %>

      @children
      \"""
    end
  end
  ```

  Now lets see how to use this component with children in a scene. This assumes we've already made an icon component.
  As you can see we are nesting a component within another component. The compiler will pass any nested components onto the scene of the parent
  component as children.

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

  Additionally because children are assigns in the engine whenever you change them at the top level, the graphs all the way down your component tree will be update.

  That's all there is to putting children in components!
  """

  @opts_schema [
    name: [required: true, type: :atom],
    type: [required: false, type: :atom, default: nil],
    services: [required: false, type: :any, default: []],
    opts: [required: false, type: :any]
  ]

  defmacro __using__(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, opts} ->
        quote do
          unquote(prelude(opts))
          unquote(deps())
          unquote(defs())
          unquote(helpers(opts))
        end

      {:error, error} ->
        raise Exception.message(error)
    end
  end

  defp prelude(opts) do
    quote do
      use SnapFramework.Scene,
        type: :component,
        services: unquote(opts[:services])
    end
  end

  defp deps() do
    quote do
      alias Scenic.Graph
      import SnapFramework.Component
    end
  end

  defp defs() do
    quote do
      Module.register_attribute(__MODULE__, :assigns, persist: true)
    end
  end

  defp helpers(opts) do
    name = opts[:name]
    data_type = opts[:type]

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

        nil ->
          def validate(data) when is_nil(data), do: {:ok, data}

        _ ->
          nil
      end

      if unquote(data_type) != :any and unquote(data_type) != :custom do
        def validate(data) do
          {
            :error,
            """
            #{IO.ANSI.red()}Invalid #{__MODULE__} specification
            Received: #{inspect(data)}
            #{IO.ANSI.yellow()}
            The data for #{__MODULE__} must be a #{inspect(unquote(data_type))}.#{IO.ANSI.default_color()}
            """
          }
        end
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

        Scenic.Primitive.put(p, {__MODULE__, data, id}, options)
      end

      def unquote(name)(%Scenic.Primitive{module: mod} = p, data, opts) do
        data =
          case mod.validate(data) do
            {:ok, data} -> data
            {:error, error} -> raise Exception.message(error)
          end

        Scenic.Primitive.put(p, data, opts)
      end
    end
  end
end
