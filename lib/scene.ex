defmodule SnapFramework.Scene do
  require Logger
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

    use_effect :dropdown_value, :on_dropdown_value_change

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

    use_effect :dropdown_value, :on_dropdown_value_change

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

    use_effect :dropdown_value, :on_dropdown_value_change

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
  Called when a scene receives a call message.
  The returned state is diffed, and effects are run.
  """
  @callback process_call(term, GenServer.from(), Scene.t()) ::
              {atom, term, Scene.t()}
              | {atom, Scene.t()}

  @doc """
  Called when a scene receives a message.
  The returned state is diffed, and effects are run.
  """
  @callback process_info(any, Scene.t()) ::
              {atom, Scene.t()}

  @doc """
  Called when a scene receives a cast message.
  The returned state is diffed, and effects are run.
  """
  @callback process_cast(any, Scene.t()) ::
              {atom, Scene.t()}

  @doc """
  Called when a scene receives an input messsage.
  The returned state is diffed, and effects are run.
  """
  @callback process_input(term, term, Scene.t()) ::
              {atom, Scene.t()}

  @doc """
  Called when a scene receives an update message.
  Use this to update data and options on your state.
  The returned state is diffed, and effects are run.
  """
  @callback process_update(term, List.t(), Scene.t()) ::
              {atom, Scene.t()}

  @doc """
  Called when a scene receives a get message.
  Use this to return data to the caller.
  The returned state is diffed, and effects are run.
  """
  @callback process_get(GenServer.from(), Scene.t()) :: {atom, Scene.t()}

  @doc """
  Called when a scene receives a put message.
  Use this to update data on your state.
  The returned state is diffed, and effects are run.
  """
  @callback process_put(term, Scene.t()) :: {atom, Scene.t()}

  @doc """
  Called when a scene receives a fetch message.
  Use this to return data to the caller.
  The returned state is diffed, and effects are run.
  """
  @callback process_fetch(GenServer.from(), Scene.t()) :: {atom, Scene.t()}

  @doc """
  Called when a scene receives an event message.
  The returned state is diffed, and effects are run.
  """
  @callback process_event(term, pid, Scene.t()) ::
              {atom, Scene.t()}
              | {atom, Scene.t(), list}
              | {atom, term, Scene.t()}
              | {atom, term, Scene.t(), list}

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

  @optional_callbacks process_call: 3,
                      process_info: 2,
                      process_cast: 2,
                      process_input: 3,
                      process_put: 2,
                      process_get: 2,
                      process_fetch: 2,
                      process_update: 3,
                      process_event: 3,
                      setup: 1,
                      mounted: 1

  @opts_schema [
    template: [required: true, type: :string],
    controller: [required: true, type: :any],
    assigns: [required: true, type: :any],
    opts: [required: false, type: :any, default: []],
    type: [required: false, type: :atom, default: :scene]
  ]

  defmacro use_effect([assigns: ks], [run: list] = actions) when is_list(list) do
    register_effects(ks, actions)
  end

  defmacro use_effect([assigns: ks], action) when is_list(ks) and is_atom(action) do
    register_effects(ks, [run: [action]])
  end

  defmacro use_effect([assigns: ks], actions) when is_list(ks) and is_list(actions) do
    register_effects(ks, [run: actions])
  end

  defmacro use_effect(ks, [run: list] = actions) when is_list(ks) and is_list(list) do
    register_effects(ks, actions)
  end

  defmacro use_effect(ks, action) when is_list(ks) and is_atom(action) do
    register_effects(ks, [run: [action]])
  end

  defmacro use_effect(ks, actions) when is_list(ks) and is_list(actions) do
    register_effects(ks, [run: actions])
  end

  defmacro use_effect(k, [run: list] = actions) when is_atom(k) and is_list(list) do
    register_effects(Keyword.put_new([], k, :any), actions)
  end

  defmacro use_effect(k, action) when is_atom(k) and is_atom(action) do
    register_effects(Keyword.put_new([], k, :any), [run: [action]])
  end

  defmacro use_effect(k, actions) when is_atom(k) and is_list(actions) do
    register_effects(Keyword.put_new([], k, :any), [run: actions])
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

  defmacro __before_compile__(env) do
    caller = __CALLER__
    template = Module.get_attribute(env.module, :template)
    file = File.read!(template)
    Module.put_attribute(env.module, :tmp_file, file)

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
          |> compile(unquote(file))
          |> mounted()

        {:ok, scene}
      end

      defp do_process(scene, new_scene) do
        SnapFramework.UseEffect.do_process(scene, new_scene, @tmp_file, @watch_registry, @effects_registry, @controller)
      end

      # unquote(scene_handlers())
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
      SnapFramework.Engine.compile_string(
        file,
        [assigns: scene.assigns],
        info,
        __ENV__
      )
      |> SnapFramework.Engine.Builder.build_graph()

    scene
    |> Scenic.Scene.assign(graph: graph)
    |> Scenic.Scene.push_graph(graph)
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
      import SnapFramework.Scene
    end
  end

  defp defs(opts) do
    quote do
      @name unquote(opts[:name])
      @template unquote(opts[:template])
      @tmp_file Module.get_attribute(__MODULE__, :tmp_file)
      @controller unquote(opts[:controller])
      @external_resource @template
      @assigns unquote(opts[:assigns])
      @effects_registry %{}
      @watch_registry []
      @before_compile SnapFramework.Scene

      def setup(scene), do: scene
      def mounted(scene), do: scene
      def terminate(_, scene), do: {:noreply, scene}
      def process_call(_msg, _from, scene), do: {:reply, scene, scene}
      def process_info(_msg, scene), do: {:noreply, scene}
      def process_cast(_msg, scene), do: {:noreply, scene}
      def process_input(_input, _id, scene), do: {:noreply, scene}
      def process_event(event, _from_pid, scene), do: {:cont, event, scene}
      def process_put({k, v}, scene), do: {:noreply, assign(scene, Keyword.put_new(Keyword.new(), k, v))}
      def process_get(_, scene), do: {:reply, scene, scene}
      def process_fetch(_, scene), do: {:reply, scene, scene}
      def process_update(data, opts, scene) do
        {:noreply,
          assign(scene, data: data, opts: Keyword.merge(scene.assigns.opts, opts))}
      end

      unquote(scene_handlers())

      defoverridable  setup: 1,
                      mounted: 1,
                      process_call: 3,
                      process_info: 2,
                      process_cast: 2,
                      process_input: 3,
                      process_put: 2,
                      process_get: 2,
                      process_fetch: 2,
                      process_update: 3,
                      process_event: 3
    end
  end

  defp scene_handlers() do
    quote do
      def handle_input(input, id, scene) do
        {response_type, new_scene} = scene.module.process_input(input, id, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_info(msg, scene) do
        {response_type, new_scene} = scene.module.process_info(msg, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_cast(msg, scene) do
        {response_type, new_scene} = scene.module.process_cast(msg, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_call(msg, from, scene) do
        {response_type, res, new_scene} = scene.module.process_call(msg, from, scene)
        {response_type, res, do_process(scene, new_scene)}
      end

      def handle_update(msg, opts, scene) do
        {response_type, new_scene} = scene.module.process_update(msg, opts, scene)
        {response_type, do_process(scene, new_scene)}
      end

      def handle_event(event, from_pid, scene) do
        case scene.module.process_event(event, from_pid, scene) do
          {:cont, event, new_scene} ->
            {:cont, event, do_process(scene, new_scene)}

          {:cont, event, new_scene, opts} ->
            {:cont, event, do_process(scene, new_scene), opts}

          {res, new_scene} ->
            {res, do_process(scene, new_scene)}

          {res, new_scene, opts} ->
            {res, do_process(scene, new_scene), opts}

          response ->
            response
        end
      end
    end
  end

  defp register_effects(ks, actions) do
    quote bind_quoted: [ks: ks, actions: actions] do
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
