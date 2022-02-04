defmodule SnapFramework.Scene do
  @moduledoc ~S"""
  ## Overview

  SnapFramework.Scene aims to make creating Scenic scenes easier and comes with a lot of convenient features.
  See Scenic.Scene docs for more on scenes.

  In order to use this module you will first need a template. Templates are just basic EEx files.
  See an example template below

    ``` elixir
  <%= graph font_size: 20 %>

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

  To update a graph SnapFramework has the ```use_effect``` macro. This macro comes with a Scene or Component.
  Let's update the above code to catch the event from the dropdown and update the text.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene,
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
  defmodule Examples.Scene.MySceneController do
    import Scenic.Primitives, only: [text: 3]
    alias Scenic.Graph

    def on_dropdown_value_change(scene) do
      graph =
        scene.assigns.graph
        |> Graph.modify(:dropdown_value_text, &text(&1, "selected value #{scene.assigns.dropdown_value}", []))

      Scenic.Scene.assign(scene, graph: graph)
    end
  end
  ```

  That is the basics to using SnapFramework.Scene. It essentially consist of three pieces, a template, a controller, and a scene module that glues them together.

  ## Setup and Mounted Callbacks

  If you need to do some special setup, like request input, subscribe to a PubSub service, or add some runtime assigns. You can do that in the setup callback.
  It gives you the scene struct and should return a scene struct.

  The setup callback run before the template is compiled. So any added or modified assigns will be included in the template.
  The graph however is not included on the scene yet.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene,
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

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene,
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

  @doc """
  Invoked when the `Scene` receives input from a driver.

  Input is messages sent directly from a driver, usually based on some action by the user.
  This is opposed to "events", which are generated by other scenes.

  When input arrives at a scene, you can consume it, or pass it along to the scene above
  you in the ViewPort's supervision structure.

  To consume the input and have processing stop afterward, return either a `{:halt, ...}` or
  `{:noreply, ...}` value. They are effectively the same thing.

  To allow the scene's parent to process the input, return `{:cont, input, state, ...}`. Note
  that you can pass along the input unchanged or transform it in the process if you wish.

  The callback supports all the return values of the
  [`init`](https://hexdocs.pm/elixir/GenServer.html#c:handle_cast/2)
  callback in [`Genserver`](https://hexdocs.pm/elixir/GenServer.html).

  In addition to the normal return values defined by GenServer, a `Scene` can
  add an optional `{push: graph}` term, which pushes the graph to the viewport.

  This has replaced push_graph() as the preferred way to push a graph.
  """
  @callback process_input(input :: Scenic.ViewPort.Input.t(), id :: any, scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene}
              | {:noreply, scene, timeout}
              | {:noreply, scene, :hibernate}
              | {:noreply, scene, term()}
              | {:halt, scene}
              | {:halt, scene, timeout}
              | {:halt, scene, :hibernate}
              | {:halt, scene, term()}
              | {:cont, input, scene}
              | {:cont, input, scene, timeout}
              | {:cont, input, scene, :hibernate}
              | {:cont, input, scene, term()}
              | {:stop, reason, scene}
            when scene: Scene.t(), reason: term, input: term

  @doc """
  Invoked when the `Scene` receives an event from another scene.

  Events are messages generated by a scene, that are passed backwards up the ViewPort's
  scene supervision tree. This is opposed to "input", which comes directly from the drivers.

  When an event arrives at a scene, you can consume it, or pass it along to the scene above
  you in the ViewPort's supervision structure.

  To consume the input and have processing stop afterward, return either a `{:halt, ...}` or
  `{:noreply, ...}` value. They are effectively the same thing.

  To allow the scene's parent to process the input, return `{:cont, event, state, ...}`. Note
  that you can pass along the event unchanged or transform it in the process if you wish.

  The callback supports all the return values of the
  [`init`](https://hexdocs.pm/elixir/GenServer.html#c:handle_cast/2)
  callback in [`Genserver`](https://hexdocs.pm/elixir/GenServer.html).

  In addition to the normal return values defined by GenServer, a `Scene` can
  add an optional `{push: graph}` term, which pushes the graph to the viewport.

  This has replaced push_graph() as the preferred way to push a graph.
  """
  @callback process_event(event :: term, from :: pid, scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene}
              | {:noreply, scene, timeout}
              | {:noreply, scene, :hibernate}
              | {:noreply, scene, term()}
              | {:halt, scene}
              | {:halt, scene, timeout}
              | {:halt, scene, :hibernate}
              | {:halt, scene, term()}
              | {:cont, event, scene}
              | {:cont, event, scene, timeout}
              | {:cont, event, scene, :hibernate}
              | {:cont, event, scene, term()}
              | {:stop, reason, scene}
            when scene: Scene.t(), reason: term, event: term

  @doc """
  Invoked when the `Scene` is started.

  `args` is the argument term you passed in via config or ViewPort.set_root.

  `options` is a list of information giving you context about the environment
  the scene is running in. If an option is not in the list, then it should be
  treated as nil.
    * `:viewport` - This is the pid of the ViewPort that is managing this dynamic scene.
      It will be not set, or nil, if you are managing the Scene in a static
      supervisor yourself.
    * `:styles` - This is the map of styles that your scene can choose to inherit
      (or not) from its parent scene. This is typically used by a child control that
      wants to visually fit into its parent's look.
    * `:id` - This is the :id term that the parent set a component when it was invoked.

  The callback supports all the return values of the
  [`init`](https://hexdocs.pm/elixir/GenServer.html#c:init/1)
  callback in [`Genserver`](https://hexdocs.pm/elixir/GenServer.html).

  In addition to the normal return values defined by GenServer, a `Scene` can
  return two new ones that push a graph to the viewport

  Returning `{:ok, state, push: graph}` will push the indicated graph
  to the ViewPort. This is preferable to the old push_graph() function.
  """

  @callback init(scene :: Scene.t(), args :: term(), options :: Keyword.t()) ::
              {:ok, scene}
              | {:ok, scene, timeout :: non_neg_integer}
              | {:ok, scene, :hibernate}
              | {:ok, scene, term()}
              | :ignore
              | {:stop, reason}
            when scene: Scene.t(), reason: term()

  @doc """
  Get the current \"value\" associated with the scene and return it to the caller.

  If this callback is not implemented, the caller with receive nil.
  """
  @callback process_get(from :: GenServer.from(), scene :: Scene.t()) ::
              {:reply, reply, scene}
              | {:reply, reply, scene, timeout() | :hibernate | {:continue, term()}}
            when reply: term(), scene: Scene.t()

  @doc """
  Put the current \"value\" associated with the scene .

  Does nothing if this callback is not implemented.
  """
  @callback process_put(value :: any, scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene, timeout() | :hibernate | {:continue, term()}}
            when scene: Scene.t()

  @doc """
  Retrieve the current data associated with the scene and return it to the caller.

  If this callback is not implemented, the caller with get an {:error, :not_implemented}.
  """
  @callback process_fetch(from :: GenServer.from(), scene :: Scene.t()) ::
              {:reply, reply, scene}
              | {:reply, reply, scene, timeout() | :hibernate | {:continue, term()}}
            when reply: term(), scene: Scene.t()

  @doc """
  Update the data and options of a scene. Usually implemented by Components.

  If this callback is not implemented, then changes to the component in the parent's
  graph will have no affect.
  """
  @callback process_update(data :: any, opts :: Keyword.t(), scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene, timeout() | :hibernate | {:continue, term()}}
            when scene: Scene.t()

  # @doc """
  # Called when a scene receives a call message.
  # The returned state is diffed, and effects are run.
  # """
  # @callback process_call(term, GenServer.from(), Scene.t()) ::
  #             {atom, term, Scene.t()}
  #             | {atom, Scene.t()}

  # @doc """
  # Called when a scene receives a message.
  # The returned state is diffed, and effects are run.
  # """
  # @callback process_info(any, Scene.t()) ::
  #             {atom, Scene.t()}

  # @doc """
  # Called when a scene receives a cast message.
  # The returned state is diffed, and effects are run.
  # """
  # @callback process_cast(any, Scene.t()) ::
  #             {atom, Scene.t()}

  # @doc """
  # Called when a scene receives an input messsage.
  # The returned state is diffed, and effects are run.
  # """
  # @callback process_input(term, term, Scene.t()) ::
  #             {atom, Scene.t()}

  # @doc """
  # Called when a scene receives an update message.
  # Use this to update data and options on your state.
  # The returned state is diffed, and effects are run.
  # """
  # @callback process_update(term, List.t(), Scene.t()) ::
  #             {atom, Scene.t()}

  # @doc """
  # Called when a scene receives an event message.
  # The returned state is diffed, and effects are run.
  # """
  # @callback process_event(term, pid, Scene.t()) ::
  #             {atom, Scene.t()}
  #             | {atom, Scene.t(), list}
  #             | {atom, term, Scene.t()}
  #             | {atom, term, Scene.t(), list}

  @doc """
  Called when a first starts, before the graph is compiled. Use this to do any startup logic.
  Any assigns set or updated here will be included in the compiled graph.
  If you need to subscribe to a PubSub service do that here.
  """
  @callback setup(Scene.t()) :: Scene.t()

  @doc """
  Called after graph is compiled.
  If you need to do any post setup changes on your graph
  do that here.
  """
  @callback mounted(Scene.t()) :: Scene.t()

  @optional_callbacks process_event: 3,
                      process_input: 3,
                      process_get: 2,
                      process_put: 2,
                      process_fetch: 2,
                      process_update: 3,
                      setup: 1,
                      mounted: 1

  @opts_schema [
    name: [required: false, type: :atom],
    template: [required: true, type: :string],
    controller: [required: true, type: :any],
    assigns: [required: true, type: :any],
    opts: [required: false, type: :any],
    type: [required: false, type: :atom]
  ]

  alias Scenic.Scene
  require Logger

  defmacro __before_compile__(env) do
    caller = __CALLER__
    template = Module.get_attribute(env.module, :template)
    file = File.read!(template)
    Module.put_attribute(env.module, :file, file)

    quote do
      def init(scene, data, opts) do
        assigns =
          Keyword.merge(@assigns,
            module: unquote(caller.module),
            data: data,
            opts: opts,
            children: opts[:children] || []
          )

        scene =
          scene
          |> assign(assigns)
          |> setup()
          |> compile()
          |> mounted()

        {:ok, scene}
      end

      def compile(scene) do
        compile(scene, unquote(file))
      end

      unquote(effect_defs())
    end
  end

  defmacro __using__(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, opts} ->
        quote do
          unquote(prelude(opts))
          unquote(deps())
          unquote(defs(opts))
        end

        {:error, error} ->
          raise Exception.message(error)
    end
  end

  @spec compile(Scenic.Scene.t(), binary) :: Scenic.Scene.t()
  def compile(scene, file) do
    info =
      Keyword.merge(
        [assigns: scene.assigns, engine: SnapFramework.Engine],
        # file: unquote(caller.file),
        # line: unquote(caller.line),
        trim: true
      )

    graph =
      file
      |> SnapFramework.Engine.compile_string(
        [assigns: scene.assigns],
        info,
        __ENV__
      )
      |> SnapFramework.Engine.Builder.build_graph()

    scene
    |> Scene.assign(graph: graph)
    |> Scene.push_graph(graph)
  end

  defmacro use_effect([assigns: ks], actions) do
    register_effects(ks, actions)
  end

  defmacro use_effect(ks, actions) do
    register_effects(ks, actions)
  end

  @doc """
  The watch macro will recompile the template with the most up to date assigns, whenever one of the watched keys changes.
  This macro is not recommended for large scene or components.

  use_effect is always preferred.

  ``` elixir
  watch [:dropdown_value]
  ```
  """
  defmacro watch(ks) do
    quote bind_quoted: [ks: ks] do
      @watch_registry List.flatten([ks | @watch_registry])
    end
  end

  defp prelude(opts) do
    case opts[:type] do
      :component ->
        quote do
          @behaviour SnapFramework.Scene
          use Scenic.Component, unquote(opts[:opts])
        end
      _ ->
        quote do
          @behaviour SnapFramework.Scene
          use Scenic.Scene, unquote(opts[:opts])
        end
    end
  end

  defp deps() do
    quote do
      import Scenic.Scene
      require EEx
      require Logger
      import SnapFramework.Scene
    end
  end

  defp defs(opts) do
    quote do
      @name unquote(opts[:name])
      @template unquote(opts[:template])
      @controller unquote(opts[:controller])
      @external_resource @template
      @assigns unquote(opts[:assigns])

      @using_effects false
      Module.register_attribute(__MODULE__, :effects_registry, [])
      Module.register_attribute(__MODULE__, :watch_registry, [])
      @effects_registry %{}
      @watch_registry []
      @before_compile SnapFramework.Scene

      def setup(scene), do: scene
      def mounted(scene), do: scene
      def terminate(_, scene), do: {:noreply, scene}
      def process_call(msg, from, scene), do: {:noreply, scene}
      def process_info(msg, scene), do: {:noreply, scene}
      def process_cast(msg, scene), do: {:noreply, scene}
      def process_input(input, id, scene), do: {:noreply, scene}
      def process_event(event, from_pid, scene), do: {:cont, event, scene}
      def process_update(data, opts, scene) do
        {:noreply,
          assign(scene, data: data, opts: Keyword.merge(scene.assigns.opts, opts))}
      end

      defoverridable process_call: 3,
                    process_info: 2,
                    process_cast: 2,
                    process_input: 3,
                    process_update: 3,
                    process_event: 3,
                    setup: 1,
                    mounted: 1

      def handle_input(input, id, scene) do
        {response_type, new_scene} = scene.module.process_input(input, id, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_info(msg, scene) do
        {response_type, new_scene} = scene.module.process_info(msg, scene)
        {response_type, scene.module.do_process(scene, new_scene)}
      end

      def handle_cast(msg, scene) do
        {response_type, new_scene} = scene.module.process_cast(msg, scene)
        {response_type, scene.module.do_process(scene, new_scene)}
      end

      def handle_call(msg, from, scene) do
        {response_type, res, new_scene} = scene.module.process_call(msg, from, scene)
        {response_type, res, scene.module.do_process(scene, new_scene)}
      end

      def handle_update(msg, opts, scene) do
        {response_type, new_scene} = scene.module.process_update(msg, opts, scene)
        {response_type, scene.module.do_process(scene, new_scene)}
      end

      def handle_event(event, from_pid, scene) do
        case scene.module.process_event(event, from_pid, scene) do
          {:noreply, new_scene} ->
            {:noreply, scene.module.do_process(scene, new_scene)}

          {:noreply, new_scene, opts} ->
            {:noreply, scene.module.do_process(scene, new_scene), opts}

          {:halt, new_scene} ->
            {:halt, scene.module.do_process(scene, new_scene)}

          {:halt, new_scene, opts} ->
            {:halt, scene.module.do_process(scene, new_scene), opts}

          {:cont, event, new_scene} ->
            {:cont, event, scene.module.do_process(scene, new_scene)}

          {:cont, event, new_scene, opts} ->
            {:cont, event, scene.module.do_process(scene, new_scene), opts}

          {res, new_scene} ->
            {res, scene.module.do_process(scene, new_scene)}

          {res, new_scene, opts} ->
            {res, scene.module.do_process(scene, new_scene), opts}

          response ->
            response
        end
      end
    end
  end

  defp effect_defs() do
    quote do
      def do_process(old_scene, new_scene) do
        # unquote(do_process(old_scene, new_scene, Module.get_attribute(__MODULE__, :watch_registry), Module.get_attribute(__MODULE__, :effects_registry), Module.get_attribute(__MODULE__, :controller), Module.get_attribute(__MODULE__, :file)))
        diff = diff_state(old_scene.assigns, new_scene.assigns)
        new_scene = process_effects(new_scene, diff)

        if old_scene.assigns.graph != new_scene.assigns.graph do
          Scene.push_graph(new_scene, new_scene.assigns.graph)
        else
          new_scene
        end
      end

      def diff_state(old_state, new_state) do
        MapDiff.diff(old_state, new_state)
      end

      def process_effects(scene, %{changed: :equal}) do
        scene
      end

      def process_effects(scene, %{changed: :map_change, added: added} = changes) do
        Enum.reduce(added, scene, fn {key, value}, acc ->
          if Enum.member?(@watch_registry, key) do
            scene = compile(scene)
          else
            acc |> change(key, value)
          end
        end)
      end

      def change(scene, key, value) do
        effect =
          Map.get(@effects_registry, {key, value}) || Map.get(@effects_registry, {key, :any})

        if effect do
          run_effect(effect, scene)
        else
          scene
        end
      end

      def run_effect(effect, scene) do
        Enum.reduce(effect, scene, fn {e_key, list}, acc ->
          case e_key do
            :run -> Enum.reduce(list, acc, fn item, s_acc -> run(s_acc, item) end)
            _ -> acc
          end
        end)
      end

      def run(scene, func) do
        apply(@controller, func, [scene])
      end
    end
  end

  defp register_effects(ks, actions) do
    quote bind_quoted: [ks: ks, actions: actions] do
      # effects_registry = Module.get_attribute(__MODULE__, :effects_registry, %{})
      @effects_registry Enum.reduce(ks, @effects_registry, fn
        kv, acc ->
          if Map.has_key?(acc, kv) do
            actions =
              Enum.reduce(actions, %{}, fn {a_key, a_list}, _a_acc ->
                if Map.has_key?(acc[kv], a_key) do
                  Map.put(acc[kv], a_key, [acc[kv][a_key] | a_list])
                else
                  Map.put_new(acc[kv], a_key, a_list)
                end
              end)
          else
            actions =
              Enum.reduce(actions, %{}, fn {a_key, a_list}, a_acc ->
                Map.put_new(a_acc, a_key, a_list)
              end)

            Map.put_new(acc, kv, actions)
          end
      end)
    end
  end
end
