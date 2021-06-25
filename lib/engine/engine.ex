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
  def init(opts) do
    IO.puts(inspect(opts))
    %{
      iodata: [],
      dynamic: [],
      vars_count: 0,
      assigns: opts[:assigns] || []
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
    ast = traverse(ast, state.assigns)
    %{iodata: iodata, dynamic: dynamic, vars_count: vars_count} = state
    var = Macro.var(:"arg#{vars_count}", __MODULE__)
    ast = quote do: unquote(var) = unquote(ast)
    %{state | dynamic: [ast | dynamic], iodata: [var | iodata], vars_count: vars_count + 1}
  end

  def handle_expr(state, "", ast) do
    ast = traverse(ast, state.assigns)
    %{dynamic: dynamic} = state
    %{state | dynamic: [ast | dynamic]}
  end

  def handle_expr(state, marker, ast) do
    EEx.Engine.handle_expr(state, marker, ast)
  end

  ## Traversal

  defp traverse(expr, assigns) do
    expr
    |> Macro.prewalk(&handle_assign/1)
    |> Macro.prewalk(&handle_graph/1)
    |> Macro.prewalk(&build_graph(&1, assigns))
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

  defp handle_graph({:graph, meta}) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = Graph.build()
    end
  end

  defp handle_graph(arg), do: arg

  defp build_graph({:outlet, meta, [slot_name, opts]}, assigns) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    {cmp, data} = assigns[:state][:data][:slots][slot_name]
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(cmp)(unquote(graph_val), unquote(data), unquote(opts))
    end
  end

  defp build_graph({:component, meta, [name, opts, [do: {:__block__, [], slots}]]}, _assigns) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    slot_list = Enum.reduce(slots, [], fn {:slot, _meta, [slot_name, cmp_name, data]}, acc ->
      Keyword.put(acc, slot_name, {cmp_name, data})
    end)
    data = [slots: slot_list]
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(
        unquote(graph_val),
        unquote(data),
        unquote(opts)
      )
    end
  end

  defp build_graph({:component, meta, [name, data, opts, [do: {:__block__, [], slots}]]}, _assigns) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    slot_list = Enum.reduce(slots, [], fn {:slot, _meta, [slot_name, cmp_name, data]}, acc ->
      Keyword.put(acc, slot_name, {cmp_name, data})
    end)
    data = [slots: slot_list, data: data]
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(
        unquote(graph_val),
        unquote(data),
        unquote(opts)
      )
    end
  end

  defp build_graph({:component, meta, [name, data, opts]}, _assigns) when is_list(opts) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), unquote(opts))
    end
  end

  defp build_graph({:component, meta, [name, data]}, _assigns) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data))
    end
  end

  defp build_graph({:primitive, meta, [name, data, opts]}, _assigns) when is_list(opts) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), unquote(opts))
    end
  end

  defp build_graph({:primitive, meta, [name, data]}, _assigns) do
    graph_val = Macro.var(:graph_val, __MODULE__)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data))
    end
  end

  defp build_graph(arg, _assigns), do: arg

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
