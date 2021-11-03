defmodule SnapFramework.Scene do
  alias Scenic.Scene
  require Logger

  @moduledoc """
  ## Overview

  SnapFramework.Scene aims to make creating Scenic scenes easier and comes with a lot of convenient features.
  See Scenic.Scene docs for more on scenes.

  In order to use this module you will first need a template. Templates are just basic EEx files.
  See an example template below

  ``` elixir
  <%= graph font_size: 20 %>

  <%= component Examples.Component.Button, "test btn", id: :test_btn, translate: {200, 20} %>

  <%= primitive Scenic.Primitive.Text,
      "selected value #{@dropdown_value}",
      id: :dropdown_value_text,
      translate: {20, 80}
  %>

  <%= component Scenic.Component.Dropdown, {
          @dropdown_opts,
          @dropdown_value
      },
      id: :dropdown,
      translate: {20, 20}
  %>
  ```

  We always start the template off with ``` <%= graph %> ```. This tells the compiler to build the Scenic graph.
  After that we begin inserting our primitives or components.
  The above is equivilent to writing the following -

  ``` elixir
  Scenic.Graph.build()
  |> Scenic.Primitive.Text.add_to_graph("selected value #{scene.assigns.dropdown_value}", id: :dropdown_value_text, translate: {20, 80})
  |> Scenic.Component.Dropdown({scene.assigns.dropdown_opts, scene.assigns.dropdown_value}, id: :dropdown, translate: {20, 20})
  ```

  Now that we have a template we can use the template in a scene.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene,
      name: :my_scene,
      template: "lib/scenes/my_scene.eex",
      controller: :none,
      assigns: [
        dropdown_opts: [
          {"Dashboard", :dashboard},
          {"Controls", :controls},
          {"Primitives", :primitives}
        ],
        dropdown_value: :dashboard,
      ]
  end
  ```

  Having just the above should be enough to get the scene rendering.
  But as you can see selecting a new dropdown doesn't update the text component text like the template implies that it should.

  To update graphs SnapFrame has the ```use_effect``` macro. This macro comes with a Scene or Component.
  Let's update the above code to catch the event from the dropdown and update the text.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene,
      name: :my_scene,
      template: "lib/scenes/my_scene.eex",
      controller: Example.Scene.MySceneController,
      assigns: [
        dropdown_opts: [
          {"Dashboard", :dashboard},
          {"Controls", :controls},
          {"Primitives", :primitives}
        ],
        dropdown_value: :dashboard,
      ]

    use_effect [assigns: [dropdown_value: :any]], [
      run: [:on_dropdown_value_change],
    ]

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      {:noreply, assign(scene, dropdown_value: value)}
    end
  end
  ```

  Last but not least the controller module.

  ``` elixir
  defmodule Examples.Scene.TestSceneController do
    import Scenic.Primitives, only: [text: 3]
    alias Scenic.Graph

    def on_dropdown_value_change(scene) do
      graph =
        scene.assigns.graph
        |> Graph.modify(:test_btn, &text(&1, "selected value #{scene.assigns.dropdown_value}", []))

      Scenic.Scene.assign(scene, graph: graph)
    end
  end
  ```

  That is the basics to using SnapFrame.Scene. It essentially consist of three pieces, a template, a controller, and a scene module that glues them together.

  ## Setup Function

  If you need to do some special setup, like request input, subscribe to a PubSub service, or add some runtime assigns. You can do that in the setup callback.
  It gives you the scene struct and should return a scene struct.

  The setup callback run before the template is compiled. So any added or modified assigns will be included in the template.
  The graph however is not included on the scene yet.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene,
      name: :my_scene,
      template: "lib/scenes/my_scene.eex",
      controller: Example.Scene.MySceneController,
      assigns: [
        dropdown_opts: [
          {"Dashboard", :dashboard},
          {"Controls", :controls},
          {"Primitives", :primitives}
        ],
        dropdown_value: :dashboard,
      ]

    use_effect [assigns: [dropdown_value: :any]], [
      run: [:on_dropdown_value_change],
    ]

    def setup(scene) do
      Scenic.PubSub.subscribe(:pubsub_service)

      assign(scene, new_assign: true)
    end

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      {:noreply, assign(scene, dropdown_value: value)}
    end
  end
  ```

  If you need to do something after the graph is compile, you can use the mounted callback.
  Like the setup callback it gives you the scene, and should return a scene.

  ```elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene,
      name: :my_scene,
      template: "lib/scenes/my_scene.eex",
      controller: Example.Scene.MySceneController,
      assigns: [
        dropdown_opts: [
          {"Dashboard", :dashboard},
          {"Controls", :controls},
          {"Primitives", :primitives}
        ],
        dropdown_value: :dashboard,
      ]

    use_effect [assigns: [dropdown_value: :any]], [
      run: [:on_dropdown_value_change],
    ]

    def setup(scene) do
      Scenic.PubSub.subscribe(:pubsub_service)

      assign(scene, new_assign: true)
    end

    def mounted(%{assigns: %{graph: graph}} = scene) do
      # do something with the graph
    end

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      {:noreply, assign(scene, dropdown_value: value)}
    end
  end
  ```
  """

  @optional_callbacks setup: 1, mounted: 1

  @callback process_call(msg :: any, from :: GenServer.from, scene :: Scene.t()) ::
    {term :: atom, scene :: Scene.t()}

  @callback process_info(msg :: any, scene :: Scene.t()) ::
    {term :: atom, scene :: Scene.t()}

  @callback process_cast(msg :: any, scene :: Scene.t()) ::
    {term :: atom, scene:: Scene.t()}

  @callback process_input(input :: any, id :: any, scene :: Scene.t()) ::
    {term :: atom, scene :: Scene.t()}

  @callback process_update(data :: any, opts :: List.t, scene :: Scene.t()) ::
    {term :: atom, scene :: Scene.t()}

  @callback process_event(event :: any, from_pid :: any, scene :: Scene.t()) ::
    {term :: atom, scene :: Scene.t()}
    | {term :: atom, scene :: Scene.t(), opts :: list}
    | {term :: atom, event :: any, scene :: Scene.t()}
    | {term :: atom, event :: any, scene :: Scene.t(), opts :: list}

  @callback setup(scene :: Scene.t()) :: Scene.t()
  @callback mounted(scene :: Scene.t()) :: Scene.t()

  defmacro __using__(name: name, template: template, controller: controller, assigns: assigns) do
    quote do
      @behaviour SnapFramework.Scene
      use Scenic.Scene
      alias Scenic.Graph
      alias Scenic.Components
      alias Scenic.Primitives
      import SnapFramework.Scene
      require SnapFramework.Macros
      require EEx
      require Logger

      @name unquote(name)
      @template unquote(template)
      @controller unquote(controller)
      @external_resource @template
      @assigns unquote(assigns)

      @using_effects false
      @effects_registry %{}
      @watch_registry []

      @before_compile SnapFramework.Scene

      def terminate(_, scene), do: {:noreply, scene}
      def process_call(msg, from, scene), do: {:noreply, scene}
      def process_info(msg, scene), do: {:noreply, scene}
      def process_cast(msg, scene), do: {:noreply, scene}
      def process_input(input, id, scene), do: {:noreply, scene}
      def process_update(data, opts, scene) do
        {:noreply, assign(scene, data: data, opts: Keyword.merge(scene.assigns.opts, opts))}
      end
      def process_event(event, from_pid, scene), do: {:cont, event, scene}
      def setup(scene), do: scene
      def mounted(scene), do: scene

      SnapFramework.Macros.input_handler()
      SnapFramework.Macros.scene_handlers()

      defoverridable process_call: 3,
                     process_info: 2,
                     process_cast: 2,
                     process_input: 3,
                     process_update: 3,
                     process_event: 3,
                     setup: 1,
                     mounted: 1
    end
  end

  defmacro __using__([name: name, template: template, controller: controller, assigns: assigns, opts: opts]) do
    quote do
      @behaviour SnapFramework.Scene
      use Scenic.Component, unquote(opts)
      alias Scenic.Graph
      alias Scenic.Components
      alias Scenic.Primitives
      import SnapFramework.Scene
      require SnapFramework.Macros
      require EEx
      require Logger

      @name unquote(name)
      @template unquote(template)
      @controller unquote(controller)
      @external_resource @template
      @assigns unquote(assigns)

      # @using_effects false
      @effects_registry %{}
      @watch_registry []

      def terminate(_, scene), do: {:noreply, scene}
      def process_call(msg, from, scene), do: {:noreply, scene}
      def process_info(msg, scene), do: {:noreply, scene}
      def process_cast(msg, scene), do: {:noreply, scene}
      def process_input(input, id, scene), do: {:noreply, scene}
      def process_update(data, opts, scene) do
        {:noreply, assign(scene, data: data, opts: Keyword.merge(scene.assigns.opts, opts))}
      end
      def process_event(event, from_pid, scene), do: {:cont, event, scene}
      def setup(scene), do: scene
      def mounted(scene), do: scene


      SnapFramework.Macros.input_handler()
      SnapFramework.Macros.scene_handlers()

      defoverridable process_call: 3,
                     process_info: 2,
                     process_cast: 2,
                     process_input: 3,
                     process_update: 3,
                     process_event: 3,
                     setup: 1,
                     mounted: 1
    end
  end

  defmacro use_effect([on_click: ids], term, effects) when is_list(ids) do
    quote location: :keep, bind_quoted: [ids: ids, term: term, effects: effects] do
      # if not @using_effects do
      #   @using_effects true
      #   SnapFramework.Macros.scene_handlers()
      # end

      for cmp_id <- ids do
        def process_event({:click, unquote(cmp_id)} = event, _from_pid, scene) do
          scene =
            Enum.reduce(unquote(effects), scene, fn action, acc ->
              case action do
                {:set, set_actions} ->
                  Enum.reduce(set_actions, acc, fn item, s_acc ->
                    set(s_acc, item)
                  end)
                {:add, add_actions} -> Enum.reduce(add_actions, acc, fn item, s_acc -> add(s_acc, item) end)
                {:modify, mod_actions} ->
                  Enum.reduce(mod_actions, acc, fn item, s_acc ->
                    modify(s_acc, item)
                  end)
                {:delete, del_actions} -> Enum.reduce(del_actions, acc, fn item, s_acc -> delete(s_acc, item) end)
              end
            end)
          case unquote(term) do
            :noreply -> {unquote(term), scene}
            :cont -> {unquote(term), event, scene}
            :halt -> {unquote(term), scene}
            _ -> {unquote(term), scene}
          end
        end
      end
    end
  end

  defmacro use_effect(:on_put) do
    quote do
      # if not @using_effects do
      #   @using_effects true
      #   SnapFramework.Macros.scene_handlers()
      # end

      def process_put(data, _, scene) do
        {:reply, :ok, assign(scene, data: data)}
      end
    end
  end

  defmacro use_effect([assigns: ks], actions) do
    quote location: :keep, bind_quoted: [ks: ks, actions: actions] do
      # if not @using_effects do
      #   @using_effects true
      #   SnapFramework.Macros.scene_handlers()
      # end

      @effects_registry Enum.reduce(ks, @effects_registry, fn
      kv, acc ->
        if Map.has_key?(acc, kv) do
          actions = Enum.reduce(actions, %{}, fn {a_key, a_list}, _a_acc ->
            if Map.has_key?(acc[kv], a_key) do
              Map.put(acc[kv], a_key, [acc[kv][a_key] | a_list])
            else
              Map.put_new(acc[kv], a_key, a_list)
            end
          end)
        else
          actions = Enum.reduce(actions, %{}, fn {a_key, a_list}, a_acc ->
            Map.put_new(a_acc, a_key, a_list)
          end)
          Map.put_new(acc, kv, actions)
        end
      end)
    end
  end

  defmacro watch(ks) do
    quote location: :keep, bind_quoted: [ks: ks] do
      # if not @using_effects do
      #   @using_effects true
      #   SnapFramework.Macros.scene_handlers()
      # end

      @watch_registry List.flatten([ks | @watch_registry])
    end
  end

  defmacro __before_compile__(env) do
    caller = __CALLER__
    template = Module.get_attribute(env.module, :template)
    file = File.read!(template)
    quote location: :keep do
      # EEx.function_from_file(:def, :render, @template, [:assigns], engine: SnapFramework.Engine)

      def init(scene, _, _) do
        assigns = Keyword.merge(@assigns, [module: unquote(caller.module)])
        scene =
          scene
          |> assign(assigns)
          |> setup()
          |> compile()
          |> mounted()

        {:ok, scene}
      end

      def compile(scene) do
        info =
          Keyword.merge(
            [assigns: scene.assigns, engine: SnapFramework.Engine],
            [file: unquote(caller.file), line: unquote(caller.line), trim: true]
          )

        compiled_list =
          SnapFramework.Engine.compile_string(unquote(file), [assigns: scene.assigns], info, __ENV__)

        graph = SnapFramework.Engine.Builder.build_graph(compiled_list)

        scene
        |> assign(graph: graph)
        |> push_graph(graph)
      end

      SnapFramework.Macros.effect_handlers()
    end
  end
end
