defmodule SnapFramework.Engine.Compiler do
  alias Macro.Env
  alias SnapFramework.Engine.Compiler.Scrubber
  alias SnapFramework.Engine.Builder

  def compile_file(path, assigns, info, _env) do
    {result, _binding} =
      path
      |> EEx.compile_file(info)
      |> Code.eval_quoted(assigns)

    result
    |> Scrubber.scrub()
    |> compile_graph()
  end

  def compile_string(string, info) do
    EEx.compile_string(string, info)
  end

  def compile_graph(result) do
    Builder.build_graph(result)
  end
end
