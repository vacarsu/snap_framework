# defmodule SnapFramework.Test.SceneTest do
#   use ExUnit.Case, async: false

#   alias Scenic.Graph

#   @basic_scene_output [
#     [type: :graph, opts: [font_size: 20]],
#     "\n",
#     [
#       type: :primitive,
#       module: Scenic.Primitive.Text,
#       data: "Hello World",
#       opts: [id: :hello_world, translate: {20, 80}]
#     ]
#   ]

#   test "Basic Scene: renders correctly" do
#     graph = SnapFramework.render(%{})
#     assert graph == @basic_scene_output
#   end

#   @grid_scene_output [
#     [type: :graph, opts: [font_size: 20]],
#     "\n",
#     [
#       type: :grid,
#       item_width: 100,
#       item_height: 100,
#       padding: 0,
#       gutter: 0,
#       rows: 1,
#       cols: 3,
#       translate: {0, 0},
#       children: [
#         [
#           type: :row,
#           padding: 0,
#           children: [
#             [
#               type: :primitive,
#               module: Scenic.Primitive.Text,
#               data: "Hello World",
#               opts: [id: :text_1, translate: {20, 80}]
#             ],
#             [
#               type: :primitive,
#               module: Scenic.Primitive.Text,
#               data: "Hello World",
#               opts: [id: :text_2, translate: {20, 80}]
#             ],
#             [
#               type: :primitive,
#               module: Scenic.Primitive.Text,
#               data: "Hello World",
#               opts: [id: :text_3, translate: {20, 80}]
#             ]
#           ]
#         ]
#       ]
#     ]
#   ]

#   test "Basic Scene Grid: renders correctly" do
#     graph = BasicSceneGrid.render(%{})
#     assert graph == @grid_scene_output
#   end
# end

# defmodule BasicScene do
#   use SnapFramework.Scene

#   def render(assigns) do
#     ~G"""
#     <%= graph font_size: 20 %>

#     <%= primitive Scenic.Primitive.Text,
#       "Hello World",
#       id: :hello_world,
#       translate: {20, 80}
#     %>
#     """
#   end
# end

# defmodule BasicSceneGrid do
#   use SnapFramework.Scene

#   def render(assigns) do
#     ~G"""
#     <%= graph font_size: 20 %>

#     <%= grid item_width: 100, item_height: 100, rows: 1, cols: 3 do %>
#       <%= row do %>
#         <%= primitive Scenic.Primitive.Text,
#           "Hello World",
#           id: :text_1,
#           translate: {20, 80}
#         %>
#         <%= primitive Scenic.Primitive.Text,
#           "Hello World",
#           id: :text_2,
#           translate: {20, 80}
#         %>
#         <%= primitive Scenic.Primitive.Text,
#           "Hello World",
#           id: :text_3,
#           translate: {20, 80}
#         %>
#       <% end %>
#     <% end %>
#     """
#   end
# end
