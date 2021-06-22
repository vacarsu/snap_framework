defmodule SnapFramework.Engine do
  @moduledoc """
  Pulled this from phoenix
  """

  @behaviour EEx.Engine
  alias Scenic.Graph
  require Logger

  def encode_to_iodata!({:safe, body}), do: body
  def encode_to_iodata!(body) when is_binary(body), do: body

  @doc false
  def init(_opts) do
    %{
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
    handle_body(quoted)
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
    ast = traverse(ast)
    %{iodata: iodata, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)
    ast = quote do: unquote(var) = unquote(ast)
    %{state | dynamic: [ast | dynamic], iodata: [var | iodata], vars_count: vars_count + 1}
  end

  def handle_expr(state, "", ast) do
    ast = traverse(ast)
    %{dynamic: dynamic} = state
    %{state | dynamic: [ast | dynamic]}
  end

  def handle_expr(state, marker, ast) do
    EEx.Engine.handle_expr(state, marker, ast)
  end

  ## Traversal

  defp traverse(expr) do
    expr
    |> Macro.prewalk(&handle_graph/1)
    |> Macro.prewalk(&handle_assign/1)
    |> Macro.prewalk(&handle_component/1)
    |> Macro.prewalk(&handle_primitive/1)
  end

  defp handle_assign({:@, meta, [{name, _, atom}]}) when is_atom(name) and is_atom(atom) do
    quote line: meta[:line] || 0 do
      SnapFramework.Engine.fetch_assign!(var!(assigns), unquote(name))
    end
  end

  defp handle_assign(arg), do: arg

  defp handle_graph({:graph, meta, [opts]}) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = Graph.build(unquote(opts))
    end
  end

  defp handle_graph(arg), do: arg

  defp handle_component({:component, meta, [name, data, opts]}) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), unquote(opts))
    end
  end

  defp handle_component({:component, meta, [name, data]}) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data))
    end
  end

  defp handle_component(arg), do: arg

  defp handle_primitive({:primitive, meta, [name, data, opts]}) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), unquote(opts))
    end
  end

  defp handle_primitive({:primitive, meta, [name, data]}) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data))
    end
  end

  defp handle_primitive(arg), do: arg

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
