defmodule SnapFramework.Engine.CompilerTest do
  use ExUnit.Case, async: false
  require EEx
  alias SnapFramework.Engine.Compiler
  alias Scenic.Graph

  doctest SnapFramework.Engine.Compiler

  @no_assigns []

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
    <% end %>
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

  @if_grid_assigns [show: true]

  @if_grid_info [assigns: @if_grid_assigns, engine: SnapFramework.Engine, trim: true]

  @template_string_if_grid """
  <%= graph font_size: 20 %>
  <%= if @show do %>
    <%= grid item_width: 150, item_height: 50, rows: 1, cols: 3 do %>
      <%= row do %>
        <%= component Scenic.Component.Button, "test", id: :btn %>
        <%= component Scenic.Component.Button, "test", id: :btn %>
        <%= component Scenic.Component.Button, "test", id: :btn %>
      <% end %>
    <% end %>
  <% end %>
  """

  test "compile_string returns correctly compiled graph if > grid > row (Button, Button, Button)" do
    graph =
      Compiler.compile_string(
        @template_string_if_grid,
        [assigns: @if_grid_assigns],
        @if_grid_info,
        __ENV__
      )

    IO.inspect(graph)
    btns = Graph.get(graph, :btn)
    IO.inspect(btns)
    {_, data, _} = List.first(btns).data

    assert length(btns) == 3 and data == "test"
  end

  @template_string_if """
  <%= graph font_size: 20 %>
  <%= if @show do %>
    <%= component Scenic.Component.Button, "test", id: :btn %>
    <%= component Scenic.Component.Button, "test", id: :btn %>
    <%= component Scenic.Component.Button, "test", id: :btn %>
  <% end %>
  """

  test "compile_string returns correctly compiled graph if > (Button, Button, Button)" do
    graph =
      Compiler.compile_string(
        @template_string_if,
        [assigns: @if_grid_assigns],
        @if_grid_info,
        __ENV__
      )

    IO.inspect(graph)
    btns = Graph.get(graph, :btn)
    IO.inspect(btns)
    {_, data, _} = List.first(btns).data

    assert length(btns) == 3 and data == "test"
  end
end
