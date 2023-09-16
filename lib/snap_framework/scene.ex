defmodule SnapFramework.Scene do
  require Logger

  @moduledoc ~S"""
  ## Overview

  SnapFramework.Scene aims to make creating Scenic scenes and components easier as well as add more power overall to graph updates and nesting components,
  and comes with a lot of convenient features. See Scenic.Scene docs for more on scenes.

  Creating a scene is pretty straight forward.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene

    def setup(scene) do
      assign(scene,
        dropdown_opts: [{"Option 1", "Option 1"}, {"Option 2", "Option 2"}, {"Option 3", "Option 3"}],
        dropdown_value: "Option 1"
      )
    end

    def render(assigns) do
      ~G\"""
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
      \"""
    end

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      {:noreply, assign(scene, dropdown_value: value)}
    end
  end
  ```

  Having just the above should be enough to get the scene rendering.
  Whenever you change one of the variables used in the template SnapFramework will automatically rebuild the graph and push it.

  ## Setup and Mount Callbacks

  If you need to do some special setup, like request input, subscribe to a PubSub service, or add some runtime assigns. You can do that in the setup callback.
  It gives you the scene struct and should return a scene struct.

  These callbacks do not trigger redraws.

  The setup callback runs before the graph is initialized. So any added or modified assigns will be included in the template.
  The graph however is not included on the scene yet.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene

    def setup(scene) do
      assign(scene,
        dropdown_opts: [{"Option 1", "Option 1"}, {"Option 2", "Option 2"}, {"Option 3", "Option 3"}],
        dropdown_value: "Option 1"
      )
    end

    def render(assigns) do
      ~G\"""
      <%= graph font_size: 20 %>

      <%= primitive Scenic.Primitive.Text,
          "selected value #{@dropdown_value}",
          id: :dropdown_value_text,
          translate: {20, 80}
      %>

      <%= component Scenic.Component.Input.Dropdown, {
              @dropdown_opts,
              @dropdown_value
          },
          id: :dropdown,
          translate: {20, 20}
      %>
      \"""
    end

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      {:noreply, assign(scene, dropdown_value: value)}
    end
  end
  ```

  If you need to do something after the graph is initialized, you can use the mounted callback.
  Like the setup callback it gives you the scene, and should return a scene.

  Usually this is for sending events to child components.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene

    def setup(scene) do
      assign(scene,
        dropdown_opts: [{"Option 1", "Option 1"}, {"Option 2", "Option 2"}, {"Option 3", "Option 3"}],
        dropdown_value: "Option 1"
      )
    end

    def mounted(scene) do
      send_event(scene, :dropdown, :set_value, "Option 2")
    end

    def render(assigns) do
      ~G\"""
      <%= graph font_size: 20 %>

      <%= primitive Scenic.Primitive.Text,
          "selected value #{@dropdown_value}",
          id: :dropdown_value_text,
          translate: {20, 80}
      %>

      <%= component Scenic.Component.Input.Dropdown, {
              @dropdown_opts,
              @dropdown_value
          },
          id: :dropdown,
          translate: {20, 20}
      %>
      \"""
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
  @callback process_get(GenServer.from(), Scene.t()) :: {atom, term, Scene.t()}

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
  @callback process_fetch(GenServer.from(), Scene.t()) :: {atom, term, Scene.t()}

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
  Called before graph is initialized.
  This is for setting up assigns used by your graph or subscribing to input or PubSub messages.
  """
  @callback setup(Scene.t()) :: Scene.t()

  @doc """
  Called after graph is initialized.
  Usually for sending events to child components.
  """
  @callback mount(Scene.t()) :: Scene.t()

  @callback render(assign :: map) :: list()

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
                      mount: 1,
                      render: 1

  @opts_schema [
    opts: [required: false, type: :any, default: []],
    type: [required: false, type: :atom, default: :scene],
    services: [required: false, type: :any, default: []]
  ]

  defmacro __before_compile__(_env) do
    caller = __CALLER__

    quote do
      def init(scene, data, opts) do
        scene =
          scene
          |> assign(
            module: unquote(caller.module),
            data: data,
            opts: opts,
            children: opts[:children] || []
          )
          |> subscribe_to_services(@services)
          |> setup()
          |> draw(@services)
          |> mount()

        {:ok, scene}
      end

      defp draw(scene, nil) do
        SnapFramework.Scene.Renderer.draw(scene)
      end

      defp draw(scene, services) do
        additional_assigns = fetch_services_data(services)

        SnapFramework.Scene.Renderer.draw(scene, additional_assigns)
      end

      defp redraw(old_scene, new_scene, nil) do
        SnapFramework.Scene.Renderer.maybe_render(old_scene, new_scene, @assigns_to_track)
      end

      defp redraw(old_scene, new_scene, services) do
        additional_assigns = fetch_services_data(services)

        SnapFramework.Scene.Renderer.maybe_render(
          old_scene,
          new_scene,
          additional_assigns,
          @assigns_to_track
        )
      end

      defp subscribe_to_services(scene, nil) do
        scene
      end

      defp subscribe_to_services(scene, services) do
        Enum.each(services, fn service ->
          Scenic.PubSub.subscribe(service)
        end)

        scene
      end

      defp fetch_services_data(services) do
        Enum.reduce(services, %{}, fn service, acc ->
          Map.merge(acc, service.fetch())
        end)
      end
    end
  end

  defmacro __using__(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, opts} ->
        quote do
          @services unquote(opts[:services])
          unquote(prelude(opts))
          unquote(deps())
          unquote(defs())
        end

      {:error, error} ->
        raise Exception.message(error)
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
      require IEx
      import SnapFramework.Scene
      import SnapFramework.Scene.Helpers
    end
  end

  defp defs() do
    quote do
      @before_compile SnapFramework.Scene
      def setup(scene), do: scene
      def mount(scene), do: scene
      def terminate(_, scene), do: {:noreply, scene}
      def process_call(_msg, _from, scene), do: {:reply, scene, scene}
      def process_info(_msg, scene), do: {:noreply, scene}
      def process_cast(_msg, scene), do: {:noreply, scene}
      def process_input(_input, _id, scene), do: {:noreply, scene}
      def process_event(event, _from_pid, scene), do: {:cont, event, scene}

      def process_put({k, v}, scene),
        do: {:noreply, assign(scene, Keyword.put_new(Keyword.new(), k, v))}

      def process_get(_, scene), do: {:reply, scene, scene}
      def process_fetch(_, scene), do: {:reply, scene, scene}

      def process_update(data, opts, scene) do
        {:noreply, assign(scene, data: data, opts: Keyword.merge(scene.assigns.opts, opts))}
      end

      unquote(scene_handlers())

      defoverridable setup: 1,
                     mount: 1,
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

        {response_type, redraw(scene, new_scene, @services)}
      end

      def handle_info({{Scenic.PubSub, :data}, {_, {:state, state}, _}}, scene) do
        {:noreply, redraw(scene, scene, @services)}
      end

      def handle_info(msg, scene) do
        {response_type, new_scene} = scene.module.process_info(msg, scene)

        {response_type, redraw(scene, new_scene, @services)}
      end

      def handle_cast(msg, scene) do
        {response_type, new_scene} = scene.module.process_cast(msg, scene)

        {response_type, redraw(scene, new_scene, @services)}
      end

      def handle_call(msg, from, scene) do
        {response_type, res, new_scene} = scene.module.process_call(msg, from, scene)

        {response_type, res, redraw(scene, new_scene, @services)}
      end

      def handle_update(msg, opts, scene) do
        {response_type, new_scene} = scene.module.process_update(msg, opts, scene)

        {response_type, redraw(scene, new_scene, @services)}
      end

      def handle_event(event, from_pid, scene) do
        case scene.module.process_event(event, from_pid, scene) do
          {:cont, event, new_scene} ->
            {:cont, event, redraw(scene, new_scene, @services)}

          {:cont, event, new_scene, opts} ->
            {:cont, event, redraw(scene, new_scene, @services), opts}

          {res, new_scene} ->
            {res, redraw(scene, new_scene, @services)}

          {res, new_scene, opts} ->
            {res, redraw(scene, new_scene, @services), opts}

          response ->
            response
        end
      end
    end
  end
end
