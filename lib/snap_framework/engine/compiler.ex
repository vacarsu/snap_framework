defmodule SnapFramework.Engine.Compiler do
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

  def compile_string(string, assigns, info, env) do
    {result, _binding} =
      string
      |> EEx.compile_string(info)
      |> Code.eval_quoted(assigns, env)

    result
    |> Scrubber.scrub()
    |> compile_graph()
  end

  defp compile_graph(result) do
    Builder.build_graph(result)
  end
end
