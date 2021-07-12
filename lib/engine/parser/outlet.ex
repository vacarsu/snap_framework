defmodule SnapFramework.Parser.Outlet do
  require Logger

  def run(ast, assigns) do
    ast
    |> parse(assigns)
  end

  # -----------------------------------------------
  # render the list of slot component passed to the
  # outlet component if it matches the slot_name
  # -----------------------------------------------
  def parse({:outlet, meta, [slot_name, opts]}, assigns) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    slot = assigns[:state][:data][:slots][slot_name] || nil
    Logger.debug(inspect slot)
    case slot do
      {nil, _, _} ->
        quote do
          unquote(graph_val)
        end
      {cmp, data, nil} ->
        quote line: meta[:line] || 0 do
          # unquote(graph_val) =
            slot(unquote(graph_val), unquote(cmp), unquote(data), unquote(opts))
        end
      {cmp, data, cmp_opts} ->
        quote line: meta[:line] || 0 do
          # unquote(graph_val) =
            slot(unquote(graph_val), unquote(cmp), unquote(data), unquote(cmp_opts))
        end
      _ ->
        quote do
          unquote(graph_val)
        end
    end
  end

  # -----------------------------------------------
  # render the slot component for unnamed outlet
  # used typically to render a list of components
  # -----------------------------------------------
  def parse({:outlet, _meta, [opts]}, assigns) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    slots = assigns[:state][:data][:slots] || nil
    Logger.debug("made it to parse unnamed outlets #{inspect slots}")
    quoted =
      Enum.reduce(slots, graph_val, fn {:slot, slot}, acc ->
        case slot do
          {nil, _, _} -> quote do unquote(acc) end
          {cmp, data, nil} ->
            quote do
              # var!(cmp) = cmp
              # unquote(cmp)(unquote(acc), unquote(data), unquote(opts))
              slot(unquote(graph_val), unquote(cmp), unquote(data), unquote(opts))
            end
          {cmp, data, cmp_opts} ->
            quote do
              # var!(cmp) = cmp
              # unquote(cmp)(unquote(acc), unquote(data), Vector2.add(unquote(opts), unquote(cmp_opts)))
              slot(unquote(graph_val), unquote(cmp), unquote(data), unquote(cmp_opts))
            end
          _ -> quote do unquote(acc) end
        end
      end)
      Logger.debug("quoted unnamed outlet #{inspect quoted, pretty: true}")
      quoted
    # Enum.map(slots, fn {:slot, slot} ->
    #   Logger.debug(inspect slot)
    #   case slot do
    #     {nil, _, _} ->
    #       quote do
    #         unquote(graph_val)
    #       end
    #     {cmp, data, nil} ->
    #       quote do
    #         # var!(cmp) = unquote(cmp)
    #         unquote(graph_val) =
    #           unquote(cmp)(unquote(graph_val), unquote(data), unquote(opts))
    #       end
    #     {cmp, data, cmp_opts} ->
    #       quote do
    #         # var!(cmp) = unquote(cmp)
    #         unquote(graph_val) =
    #           unquote(cmp)(unquote(graph_val), unquote(data), unquote(cmp_opts))
    #       end
    #     _ ->
    #       quote do
    #         unquote(graph_val)
    #       end
    #   end
    # end)
  end

  def parse(ast, _assigns), do: ast
end
