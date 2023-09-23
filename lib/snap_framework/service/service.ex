defmodule SnapFramework.Service do
  @moduledoc """
  ## Overview

  SnapFramework.Service is a behaviour that can be used to share global app state
  across your components without needing to save copies of the state within every scene.

  ## Usage

  ``` elixir
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

  defmodule Examples.Services.Supervisor do
    use Supervisor

    def start_link(_) do
      Supervisor.start_link(__MODULE__, :ok)
    end

    def init(_) do
      children = [
        Examples.Services.MyService
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  defmodule Examples do

    def start(_type, _args) do
      # load the viewport configuration from config
      main_viewport_config = Application.get_env(:examples, :viewport)
      # start the application with the viewport
      children = [
        {Scenic, [main_viewport_config]},
        Examples.Services.Supervisor
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
    end
  end
  ```

  With that ceremony out of the way, you can now use the service in your scenes:

  ``` elixir
  defmodule Examples.Scene.TestScene do
    use SnapFramework.Scene, services: [Examples.Services.MyService] # <-- add the service here

    alias Examples.Services.MyService

    def render(assigns) do
      ~G\"""
      <%= graph font_size: 20 %>

      <%= primitive Scenic.Primitive.Text,
          "selected value \#{@dropdown_value}", # <-- use the global variables here as if they were local assigns
          translate: {20, 80}
      %>

      <%= component Scenic.Component.Input.Dropdown, {
          @dropdown_opts, # <-- use the global variables here as if they were local assigns
          @dropdown_value
        },
        id: :dropdown
      %>
      \"""
    end

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      MyService.update(:dropdown_value, value) # <-- update the service values here
      {:noreply, scene}
    end
  end
  ```
  """

  @callback setup(any) :: any

  @optional_callbacks setup: 1

  defmacro __using__(_) do
    quote do
      @behaviour SnapFramework.Service
      use GenServer
      import SnapFramework.Service
      import Scenic.PubSub

      @service __MODULE__

      def start_link(opts) do
        GenServer.start_link(@service, opts, name: @service)
      end

      def init(state) do
        Scenic.PubSub.register(@service)

        {:ok, setup(state)}
      end

      def setup(state) do
        state
      end

      def fetch() do
        GenServer.call(@service, :fetch)
      end

      def update(key, val) do
        GenServer.cast(@service, {:update, {key, val}})
      end

      def handle_info(msg, state) do
        Scenic.PubSub.publish(@service, {:state, state})

        {:noreply, state}
      end

      def handle_cast({:update, {key, value}}, state) do
        state = Map.put(state, key, value)
        Scenic.PubSub.publish(@service, {:state, state})

        {:noreply, state}
      end

      def handle_cast(msg, state) do
        Scenic.PubSub.publish(@service, {:state, state})

        {:noreply, state}
      end

      def handle_call(:fetch, from, state) do
        {:reply, state, state}
      end

      def handle_call(msg, from, state) do
        {:reply, state, state}
      end

      defoverridable setup: 1
    end
  end
end
