defmodule SnapFramework.Engine do
  @moduledoc """
  Pulled this from phoenix
  """

  @behaviour EEx.Engine
  require Logger

  def encode_to_iodata!({:safe, body}), do: body
  def encode_to_iodata!(body) when is_binary(body), do: body

  def compile(path, assigns, info, _env) do
    quoted = EEx.compile_file(path, info)
    {result, _binding} = Code.eval_quoted(quoted, assigns)
    List.last(result)
  end

  def compile_string(string, assigns, info, env) do
    quoted = EEx.compile_string(string, info)
    {result, _binding} = Code.eval_quoted(quoted, assigns, env)
    Logger.debug(inspect List.last(result), pretty: true)
    List.last(result)
  end

  @doc false
  def init(opts) do
    Logger.info(inspect(opts, pretty: true))
    %{
      iodata: [],
      dynamic: [],
      vars_count: 0,
      assigns: opts[:assigns] || []
    }
  end

  @doc false
  def handle_begin(state) do
    Macro.var(:assigns, __MODULE__)
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
    Logger.debug(inspect expr, pretty: true)
    expr
    |> Macro.prewalk(&SnapFramework.Parser.Assigns.run(&1, assigns))
    |> Macro.prewalk(&SnapFramework.Parser.Enumeration.run/1)
    |> Macro.prewalk(&SnapFramework.Parser.Graph.run/1)
    |> Macro.prewalk(&SnapFramework.Parser.Component.run/1)
    |> Macro.prewalk(&SnapFramework.Parser.Primitive.run/1)
    |> Macro.prewalk(&SnapFramework.Parser.Outlet.run(&1, assigns))
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
