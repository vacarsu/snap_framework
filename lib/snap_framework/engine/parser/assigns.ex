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

  defp parse({:@, meta, [{name, _, _atom}]}, state) do
    register_assigns(name, state.caller.module)

    quote line: meta[:line] || 0 do
      var!(assigns)[unquote(name)]
    end
  end

  defp parse(ast, _state), do: ast

  defp register_assigns(assign_name, target_module) do
    tracked_assigns = Module.get_attribute(target_module, :assigns_to_track)

    if assign_name not in tracked_assigns do
      Module.put_attribute(target_module, :assigns_to_track, [assign_name | tracked_assigns])
    end
  end
end
