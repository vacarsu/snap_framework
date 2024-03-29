defmodule SnapFramework.Engine do
  @moduledoc """
  The EEx template engine.

  # Overview

  The SnapFramework Engine is responsible for parsing EEx templates and building graphs from them.

  You should always start a template with the a graph, and then add any components and primitives immediately after it.

  ``` elixir
  <%= graph font_size: 20 %>

  <%= component Scenic.Component.Button,
      "button text",
      id: :btn
  %>

  <%= primitive Scenic.Primitive.Rectangle,
      {100, 100},
      id: :rect,
      fill: :steel_blue
  %>
  ```

  In the above example you can see how simple it is to render component and primitives.

  # Layouts

  The templating engine also supports layouts.

  ``` elixir
  <%= graph font_size: 20 %>

  <%= layout padding: 100, width: 600, height: 600, translate: {100, 10} do %>
      <%= component Scenic.Component.Button, "test btn", id: :test_btn %>
      <%= component Scenic.Component.Button, "test btn", id: :test_btn %>
      <%= component Scenic.Component.Button, "test btn", id: :test_btn %>
      <%= component Scenic.Component.Button, "test btn", id: :test_btn %>
      <%= component Scenic.Component.Button, "test btn", id: :test_btn %>
      <%= component Scenic.Component.Button, "test btn", id: :test_btn %>

      <%= layout padding: 0, width: 600, height: 300, translate: {10, 10} do %>
          <%= component Scenic.Component.Input.Dropdown, {
                  @dropdown_opts,
                  @dropdown_value
              },
              id: :dropdown_1,
              z_index: 100
          %>

          <%= component Scenic.Component.Input.Dropdown, {
                  @dropdown_opts,
                  @dropdown_value
              },
              id: :dropdown_2
          %>
      <% end %>
  <% end %>
  ```

  The only required options on templates are `width` and `height`.
  Any nested layouts will have the padding and translate of the previous layout added onto it.

  Any components rendered within a layout are added directly to the graph. Which means you can modify them directly in the scene you're working in.
  There is no parent component that is rendered.
  """

  @behaviour EEx.Engine
  require Logger

  def encode_to_iodata!({:safe, body}), do: body
  def encode_to_iodata!(body) when is_binary(body), do: body

  @doc false
  def init(opts) do
    Module.register_attribute(opts[:caller].module, :assigns_to_track, accumulate: false)
    Module.put_attribute(opts[:caller].module, :assigns_to_track, [])

    %{
      caller: opts[:caller],
      iodata: [],
      dynamic: [],
      vars_count: 0
    }
  end

  @doc false
  def handle_begin(state) do
    %{state | iodata: [], dynamic: []}
  end

  @doc false
  def handle_end(quoted) do
    quoted
    |> handle_body()
  end

  @doc false
  def handle_body(state) do
    %{iodata: iodata, dynamic: dynamic} = state
    safe = Enum.reverse(iodata)
    {:__block__, [], Enum.reverse([safe | dynamic])}
  end

  @doc false
  def handle_text(state, text) do
    handle_text(state, [], text)
  end

  @doc false
  def handle_text(state, _meta, text) do
    %{iodata: iodata} = state
    %{state | iodata: [text | iodata]}
  end

  @doc false
  def handle_expr(state, "=", ast) do
    ast = traverse(ast, state)
    %{iodata: iodata, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)
    ast = quote do: unquote(var) = unquote(ast)
    %{state | dynamic: [ast | dynamic], iodata: [var | iodata], vars_count: vars_count + 1}
  end

  def handle_expr(state, "", ast) do
    ast = traverse(ast, state)
    %{dynamic: dynamic} = state
    %{state | dynamic: [ast | dynamic]}
  end

  def handle_expr(state, marker, ast) do
    EEx.Engine.handle_expr(state, marker, ast)
  end

  ## Traversal

  defp traverse(expr, state) do
    expr
    |> Macro.prewalk(&SnapFramework.Engine.Parser.Assigns.run(&1, state))
    |> Macro.prewalk(&SnapFramework.Engine.Parser.Grid.run/1)
    |> Macro.prewalk(&SnapFramework.Engine.Parser.Layout.run/1)
    |> Macro.prewalk(&SnapFramework.Engine.Parser.Graph.run/1)
    |> Macro.prewalk(&SnapFramework.Engine.Parser.Component.run/1)
    |> Macro.prewalk(&SnapFramework.Engine.Parser.Primitive.run/1)
  end

  @doc false
  def fetch_assign!(assigns, key) do
    case Access.fetch(assigns, key) do
      {:ok, val} ->
        val

      :error ->
        raise ArgumentError, """
        assign @#{key} not available in eex template.

        Please make sure all proper assigns have been set. If this
        is a child template, ensure assigns are given explicitly by
        the parent template as they are not automatically forwarded.

        Available assigns: #{inspect(Enum.map(assigns, &elem(&1, 0)))}
        """
    end
  end
end
