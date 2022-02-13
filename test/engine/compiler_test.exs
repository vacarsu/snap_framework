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

  test "compile_string returns correctly compiled graph from button" do
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

  test "compile_string returns correctly compiled graph from grid > row, > col > (Button)" do
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

  @template_string_grid_large """
  <%= graph font_size: 20 %>


  <%= grid item_width: 150, item_height: 50, rows: 2, cols: 10 do %>
    <%= row do %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
      <%= component Scenic.Component.Button, "test", id: :btn %>
    <%= end %>
  <% end %>
  """

  test "compile_string returns correctly compiled graph from large grid > row > (Button)" do
    graph =
      Compiler.compile_string(
        @template_string_grid_large,
        [assigns: @no_assigns],
        @no_info,
        __ENV__
      )

    btns = Graph.get(graph, :btn)
    {_, data, _} = List.first(btns).data

    assert length(btns) == 10 and data == "test"
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

  test "compile_string returns correctly compiled graph if > grid > row (Button)" do
    graph =
      Compiler.compile_string(
        @template_string_if_grid,
        [assigns: @if_grid_assigns],
        @if_grid_info,
        __ENV__
      )

    btns = Graph.get(graph, :btn)
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

  test "compile_string returns correctly compiled graph if > (Button)" do
    graph =
      Compiler.compile_string(
        @template_string_if,
        [assigns: @if_grid_assigns],
        @if_grid_info,
        __ENV__
      )

    btns = Graph.get(graph, :btn)
    {_, data, _} = List.first(btns).data

    assert length(btns) == 3 and data == "test"
  end

  @if_for_assigns [show: true, labels: ["test", "test", "test"]]

  @if_for_info [assigns: @if_for_assigns, engine: SnapFramework.Engine, trim: true]

  @template_string_if_for """
  <%= graph font_size: 20 %>
  <%= if @show do %>
    <%= for label <- @labels do %>
      <%= component Scenic.Component.Button, label, id: :btn %>
    <% end %>
  <% end %>
  """

  test "compile_string returns correctly compiled graph if > for > (Button)" do
    graph =
      Compiler.compile_string(
        @template_string_if_for,
        [assigns: @if_for_assigns],
        @if_for_info,
        __ENV__
      )

    btns = Graph.get(graph, :btn)
    {_, data, _} = List.first(btns).data

    assert length(btns) == 3 and data == "test"
  end
end
