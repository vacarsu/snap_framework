defmodule Examples.Services.MyService do
  use SnapFramework.Service

  def setup(state) do
    %{
      dropdown_opts: [
        {"Option 1", "Option 1"},
        {"Option 2", "Option 2"},
        {"Option 3", "Option 3"}
      ],
      dropdown_value: "Option 1"
    }
  end
end
