defmodule SnapFramework.Engine.Parser.Primitive do
  require Logger

  @moduledoc false

  def run(ast) do
    ast
    |> parse()
  end

  defp parse({:primitive, meta, [name, data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: unquote(name),
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:primitive, meta, [name, data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: unquote(name),
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:text, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Text,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:text, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Text,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:rect, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Rectangle,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:rect, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Rectangle,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:rectangle, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Rectangle,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:rectangle, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Rectangle,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:rrect, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.RoundedRectangle,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:rrect, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.RoundedRectangle,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:rounded_rectangle, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.RoundedRectangle,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:rounded_rectangle, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.RoundedRectangle,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:circle, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Circle,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:circle, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Circle,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:line, meta, data, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Line,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:line, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Line,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:arc, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Arc,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:arc, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Arc,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:triangle, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Triangle,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:triangle, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Triangle,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:ellipse, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Ellipse,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:ellipse, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Ellipse,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:quad, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Quad,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:quad, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Quad,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse({:sector, meta, [data, opts]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Sector,
        data: unquote(data),
        opts: unquote(opts)
      ]
    end
  end

  defp parse({:sector, meta, [data]}) do
    quote line: meta[:line] || 0 do
      [
        type: :primitive,
        module: Scenic.Primitive.Sector,
        data: unquote(data),
        opts: []
      ]
    end
  end

  defp parse(ast), do: ast
end
