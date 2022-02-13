defmodule SnapFramework.Engine.Parser.PrimitiveTest do
  use ExUnit.Case, async: false
  require EEx
  alias SnapFramework.Engine.Parser.Primitive
  alias Scenic.Graph

  doctest SnapFramework.Engine.Parser.Primitive

  @text_long_form_ast_all_params {:primitive, [], [Scenic.Primitive.Text, "text", []]}

  @p_text_long_form_ast_all_params [
    type: :primitive,
    module: Scenic.Primitive.Text,
    data: "text",
    opts: []
  ]

  test "Can parse text long form from ast with all parameters" do
    assert Primitive.run(@text_long_form_ast_all_params) == @p_text_long_form_ast_all_params
  end

  @text_short_form_ast_all_params {:text, [], ["text", []]}

  @p_text_short_form_ast_all_params [
    type: :primitive,
    module: {:__aliases__, [line: 0, alias: false], [:Scenic, :Primitive, :Text]},
    data: "text",
    opts: []
  ]

  test "Can parse text short form with all parameters" do
    assert Primitive.run(@text_short_form_ast_all_params) == @p_text_short_form_ast_all_params
  end
end
