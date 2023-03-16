defmodule SnapFramework.Engine.Parser.Assigns do
  @moduledoc false

  # def build({:@, _meta, [{name, _, _atom}]}, state) do
  #   %{state | assigns: [name | state.assigns]}
  # end

  # def build(_ast, state), do: state

  def run(ast, state) do
    ast
    |> parse(state)
  end

  defp parse({:@, meta, [{name, _, _atom}]} = ast, state) do
    Module.put_attribute(state.caller.module, :assigns_to_track, [
      name | Module.get_attribute(state.caller.module, :assigns_to_track)
    ])

    IO.inspect(ast)

    quote line: meta[:line] || 0 do
      var!(assigns)[unquote(name)]
    end
  end

  defp parse(ast, _state), do: ast
end
