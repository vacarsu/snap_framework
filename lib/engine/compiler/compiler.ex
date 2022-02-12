defmodule SnapFramework.Engine.Compiler do
  require Logger
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

    Logger.debug("scrubbing result: #{inspect(result, pretty: true)}")

    result
    |> Scrubber.scrub()
    |> compile_graph()
  end

  defp compile_graph(result) do
    Logger.debug("scrubbed result: #{inspect(result, pretty: true)}")
    Builder.build_graph(result)
  end
end
