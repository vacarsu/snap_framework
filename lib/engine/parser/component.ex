defmodule SnapFramework.Parser.Component do
  require Logger

  @moduledoc false

  def run(ast) do
    # Logger.debug(inspect(ast))

    ast
    |> parse()
  end

  def parse({:component, meta, [name, data, opts, [do: {:__block__, [], block}]]}) do
    children =
      block
      |> Enum.reduce([], &build_child_list/2)

    quote line: meta[:line] || 0 do
      [
        type: :component,
        module: unquote(name),
        data: unquote(data),
        opts: unquote(opts),
        children: unquote(children)
      ]
    end
  end

  def parse({:component, meta, [name, data, [do: {:__block__, [], block}]]}) do
    children =
      block
      |> Enum.reduce([], &build_child_list/2)

    quote line: meta[:line] || 0 do
      [
        type: :component,
        module: unquote(name),
        data: unquote(data),
        opts: [],
        children: unquote(children)
      ]
    end
  end

  def parse({:component, meta, [name, data, opts]}) when is_list(opts) do
    quote line: meta[:line] || 0 do
      [
        type: :component,
        module: unquote(name),
        data: unquote(data),
        opts: unquote(opts),
        children: []
      ]
    end
  end

  def parse({:component, meta, [name, opts]}) when is_list(opts) do
    quote line: meta[:line] || 0 do
      [
        type: :component,
        module: unquote(name),
        data: nil,
        opts: unquote(opts),
        children: []
      ]
    end
  end

  def parse({:component, meta, [name, data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :component,
        module: unquote(name),
        data: unquote(data),
        opts: [],
        children: []
      ]
    end
  end

  def parse(ast), do: ast

  def build_child_list({:=, [], [_, component]}, acc) do
    List.insert_at(acc, length(acc), component)
  end

  def build_child_list({type, _, [name, data, opts]}, acc) do
    List.insert_at(acc, length(acc), type: type, module: name, data: data, opts: opts)
  end

  def build_child_list({type, _, [name, data]}, acc) do
    List.insert_at(acc, length(acc), type: type, module: name, data: data, opts: [])
  end

  def build_child_list(_ast, acc) do
    acc
  end
end
