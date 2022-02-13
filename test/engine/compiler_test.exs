defmodule SnapFramework.Engine.CompilerTest do
  use ExUnit.Case, async: false
  require EEx
  alias SnapFramework.Engine.Compiler
  alias Scenic.Graph

  doctest SnapFramework.Engine.Compiler

  @assigns [text: "text"]

  @no_assigns []

  @info [assigns: @assigns, engine: SnapFramework.Engine, trim: true]

  @no_info [assigns: @no_assigns, engine: SnapFramework.Engine, trim: true]

  @template_string_button """
  <%= graph font_size: 20 %>

  <%= component Scenic.Component.Button, "test", id: :btn %>
  """

  test "compile_string returns correctly compiled graph from string with button component" do
    graph =
      Compiler.compile_string(
        @template_string_button,
        [assigns: @no_assigns],
        @no_info,
        __ENV__
      )

    [btn] = Graph.get(graph, :btn)
    %{data: {btn_module, data, _}} = btn

    assert btn_module == Scenic.Component.Button and data == "test"
  end

  @template_string_grid """
  <%= graph font_size: 20 %>

  <%= grid item_width: 150, item_height: 50, rows: 2, cols: 3 do %>
    <%= row do %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
    <%= end %>

    <%= col do %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
    <%= end %>
  <% end %>
  """

  test "compile_string returns correctly compiled graph from string with grid and row" do
    graph =
      Compiler.compile_string(
        @template_string_grid,
        [assigns: @no_assigns],
        @no_info,
        __ENV__
      )

    btns = Graph.get(graph, :btn)
    {_, data, _} = List.first(btns).data

    assert length(btns) == 6 and data == "test"
  end

  # @template_string_layout """
  # <%= graph font_size: 20 %>

  # <%= layout width: 150, height: 50 do %>
  #   <%= component Scenic.Component.Button, "test", id: :btn %>
  #   <%= component Scenic.Component.Button, "test", id: :btn %>
  #   <%= component Scenic.Component.Button, "test", id: :btn %>
  # <% end %>
  # """

  # test "compile_string returns correctly compiled graph from layout" do
  #   graph =
  #     Compiler.compile_string(
  #       @template_string_layout,
  #       [assigns: @no_assigns],
  #       @no_info,
  #       __ENV__
  #     )

  #   btns = Graph.get(graph, :btn)
  #   {_, data, _} = List.first(btns).data

  #   assert length(btns) == 3 and data == "test"
  # end
end
