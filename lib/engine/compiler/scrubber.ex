defmodule SnapFramework.Engine.Compiler.Scrubber do
  require Logger

  def scrub(parsed) do
    # Logger.debug("scrubbing parsed: #{inspect(parsed, pretty: true)}")
    Enum.reduce(parsed, [], &scrub_item/2)
  end

  def scrub(parsed, acc) do
    Logger.debug("scrubbing parsed: #{inspect(parsed, pretty: true)}")
    Enum.reduce(parsed, acc, &scrub_item/2)
  end

  defp scrub_item("\n", acc) do
    acc
  end

  defp scrub_item(%{type: _type, children: [children]} = child, acc) when is_list(children) do
    Logger.debug("Scrubber child children: #{inspect(children)}")
    children = scrub(children, acc)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(%{type: _type, children: children} = child, acc) do
    Logger.debug("Scrubber child children: #{inspect(children)}")
    children = scrub(children)
    List.insert_at(acc, length(acc), Keyword.merge(child, children: children))
  end

  defp scrub_item(%{type: _type} = child, acc) do
    List.insert_at(acc, length(acc), child)
  end

  defp scrub_item(child, acc) do
    if is_list(child) do
      if is_nil(child[:type]) do
        List.insert_at(acc, length(acc), scrub(List.first(child)))
      else
        List.insert_at(acc, length(acc), child)
      end
    else
      List.insert_at(acc, length(acc), child)
    end
  end
end
