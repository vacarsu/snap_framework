defmodule SnapFramework.Parser.Component do
  require Logger

  def run(ast) do
    ast
    |> parse()
  end

  def parse({:component, meta, [name, data, opts]}) when is_list(opts) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), unquote(opts))
    end
  end

  def parse({:component, meta, [name, opts]}) when is_list(opts) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), nil, unquote(opts))
    end
  end

  def parse({:component, meta, [name, data]}) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(unquote(graph_val), unquote(data), [])
    end
  end

  def parse({:component, meta, [name, data, opts, [do: {:__block__, [], block}]]}) do
    graph_val = Macro.var(:graph_val, SnapFramework.Engine)
    Logger.debug("block after enumeration #{inspect block}}")
    slots =
      block
      |> Enum.flat_map(fn ast ->
        Logger.debug(inspect ast)
        ast
        |> build_slot_list()
      end)

    Logger.debug(inspect slots)

    data = [slots: slots, data: data]
    quote line: meta[:line] || 0 do
      unquote(graph_val) = unquote(name)(
        unquote(graph_val),
        unquote(Macro.escape(data)),
        unquote(opts)
      )
    end
  end

  def parse(ast), do: ast

  def build_slot_list({:slot, _, [name, data]}) do
    Keyword.put([], :slot, {name, data, nil})
  end

  def build_slot_list({:slot, _, [name, data, opts]}) when is_list(opts) do
    Keyword.put([], :slot, {name, data, opts})
  end

  def build_slot_list({:slot, _, [slot_name, name, data]}) do
    Keyword.put([], slot_name, {name, data, nil})
  end

  def build_slot_list({:slot, _, [slot_name, name, data, opts]}) do
    Keyword.put([], slot_name, {name, data, opts})
  end

  def build_slot_list([{:=, [], [_, {:slot, [name, data]}]}, _]) do
    Keyword.put([], :slot, {name, data, nil})
  end

  def build_slot_list([{:=, [], [_, {:slot, [name, data, opts]}]}, _]) when is_list(opts) do
    Keyword.put([], :slot, {name, data, opts})
  end

  def build_slot_list([{:=, [], [_, {:slot, [slot_name, name, data]}]}, _]) do
    Keyword.put([], slot_name, {name, data, nil})
  end

  def build_slot_list([{:=, [], [_, {:slot, [slot_name, name, data, opts]}]}, _]) do
    Keyword.put([], slot_name, {name, data, opts})
  end

  def build_slot_list({:=, [], [{_, _, _}, slots]}) do
    Enum.flat_map(slots, &build_slot_list/1)
  end

  def build_slot_list(_ast) do
    []
  end
end
