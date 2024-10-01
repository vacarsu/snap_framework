defmodule Examples.State.MyState do
  use SnapFramework.State

  def setup(state) do
    assign(state,
      dropdown_opts: [
        {"Option 1", "Option 1"},
        {"Option 2", "Option 2"},
        {"Option 3", "Option 3"}
      ],
      dropdown_value: "Option 1"
    )
  end
end
