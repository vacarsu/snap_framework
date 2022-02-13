defmodule SnapFramework.Engine.Parser.AssignsTest do
  use ExUnit.Case, async: false
  require EEx
  alias SnapFramework.Engine.Parser.Assigns
  alias Scenic.Graph

  doctest SnapFramework.Engine.Parser.Assigns

  @assign_value {:@, [], [{:text, [], nil}]}

  @p_assign_value "text"

  test "Can parse assigned variables" do
    assert Assigns.run(@assign_value, text: "text") == @p_assign_value
  end
end
