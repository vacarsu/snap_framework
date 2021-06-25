defmodule SnapFramework.Compiler do
  require EEx

  def compile(template, assigns \\ [], context) do
    quoted = EEx.compile_file(template, assigns: assigns, engine: SnapFramework.Engine)
    ast = Code.eval_quoted(quoted, [assigns: assigns], context)
    [graph] = elem(ast, 0)
    graph
  end
end
