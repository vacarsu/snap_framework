defmodule SnapFramework.Scene.Helpers do
  defmacro sigil_G({:<<>>, meta, [expr]}, _) do
    unless Macro.Env.has_var?(__CALLER__, {:assigns, nil}) do
      raise "~G requires a variable named \"assigns\" to exist and be set to a map"
    end

    EEx.compile_string(
      expr,
      engine: SnapFramework.Engine,
      file: __CALLER__.file,
      line: __CALLER__.line,
      caller: __CALLER__,
      indentation: meta[:indentation] || 0,
      source: expr
    )
  end
end
