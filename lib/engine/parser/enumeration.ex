defmodule SnapFramework.Parser.Enumeration do
  require Logger

  @moduledoc false

  def run(ast) do
    ast
    |> parse()
  end

  def parse(
        {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _,
         [
           list,
           {:fn, _,
            [
              {:->, _,
               [
                 [_var],
                 {:__block__, [], block}
               ]}
            ]}
         ]}
      ) do
    for cmp_data <- Macro.expand(list, SnapFramework.Engine) do
      Macro.prewalk(block, &handle_block(&1, cmp_data))
    end
  end

  def parse({:for, _meta, [{:<-, _, [_var, arg]}, [do: {:__block__, [], block}]]}) do
    for cmp_data <- Macro.expand(arg, SnapFramework.Engine) do
      Macro.prewalk(block, &handle_block(&1, cmp_data))
    end
  end

  def parse(ast), do: ast

  defp handle_block({:slot, meta, [cmp, _cmp_data]}, cmp_data) do
    quote line: meta[:line] || 0 do
      {:slot, [unquote(cmp), unquote(cmp_data)]}
    end
  end

  defp handle_block({:slot, meta, [cmp, _cmp_data, opts]}, cmp_data) do
    quote line: meta[:line] || 0 do
      {:slot, [unquote(cmp), unquote(cmp_data), unquote(opts)]}
    end
  end

  defp handle_block({:arg3, [], SnapFrameWork.Engine}, _cmp_data) do
    quote do
    end
  end

  defp handle_block(ast, _), do: ast
end
