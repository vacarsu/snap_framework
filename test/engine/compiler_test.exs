defmodule SnapFramework.Engine.CompilerTest do
  use ExUnit.Case, async: false
  require EEx
  alias SnapFramework.Engine.Compiler
  alias Scenic.Graph

  doctest SnapFramework.Engine.Compiler

  @assigns []

  @info [assigns: @assigns, engine: SnapFramework.Engine, trim: true]

  @template_string """
  <%= graph font_size: 20 %>

  <%= component Scenic.Component.Button, "test", id: :btn %>
  """

  test "compile_string returns correctly compiled graph from string" do
    graph =
      Compiler.compile_string(
        @template_string,
        [assigns: @assigns],
        @info,
        __ENV__
      )

    [btn] = Graph.get(graph, :btn)
    %{data: {btn_module, data, _}} = btn

    assert btn_module == Scenic.Component.Button and data == "test"
  end
end
