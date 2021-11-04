defmodule SnapFramework.Parser.Primitive do
  require Logger

  @moduledoc false

  def run(ast) do
    ast
    |> parse()
  end

  def parse({:primitive, meta, [name, data, opts]}) when is_list(opts) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: unquote(name),
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  def parse({:primitive, meta, [name, opts]}) when is_list(opts) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: unquote(name),
        data: nil,
        opts: unquote(opts)
      ]
    end
  end

  def parse({:primitive, meta, [name, data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: unquote(name),
        data: unquote(data),
        opts: []
      ]
    end
  end

  def parse(ast), do: ast
end
