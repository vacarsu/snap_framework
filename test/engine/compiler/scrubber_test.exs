defmodule SnapFramework.Engine.Compiler.ScrubberTest do
  use ExUnit.Case, async: false
  require EEx
  alias SnapFramework.Engine.Compiler
  alias Scenic.Graph

  doctest SnapFramework.Engine.Compiler.Scrubber

  @before_scrub_simple [
    [type: :graph, opts: [font_size: 20]],
    "\n",
    [
      [
        "\n",
        [type: :component, module: Scenic.Component.Button, data: "test", opts: [], children: []],
        "\n"
      ]
    ]
  ]

  @after_scrub_simple [
    [type: :graph, opts: [font_size: 20]],
    [type: :component, module: Scenic.Component.Button, data: "test", opts: [], children: []]
  ]

  test "Scrubber removes whitespaces" do
    assert Compiler.Scrubber.scrub(@before_scrub_simple) == @after_scrub_simple
  end

  @before_scrub_nils [
    [type: :graph, opts: [font_size: 20]],
    "\n",
    [
      [
        "\n",
        [type: :component, module: Scenic.Component.Button, data: "test", opts: [], children: []],
        "\n"
      ],
      "\n",
      nil,
      "\n",
      [
        "\n",
        [type: :component, module: Scenic.Component.Button, data: "test", opts: [], children: []],
        "\n"
      ]
    ]
  ]

  @after_scrub_nils [
    [type: :graph, opts: [font_size: 20]],
    [type: :component, module: Scenic.Component.Button, data: "test", opts: [], children: []],
    [type: :component, module: Scenic.Component.Button, data: "test", opts: [], children: []]
  ]

  test "Scrubber removes nil values" do
    assert Compiler.Scrubber.scrub(@before_scrub_nils) == @after_scrub_nils
  end
end
