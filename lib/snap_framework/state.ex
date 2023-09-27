defmodule SnapFramework.State do
  @moduledoc """
  ## Overview

  SnapFramework.State is a behaviour that can be used to share global app state
  across your components without needing to save copies of the state within every scene.

  ## Usage

  ``` elixir
  defmodule Examples.States.MyState do
    use SnapFramework.State

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

  defmodule Examples.States.Supervisor do
    use Supervisor

    def start_link(_) do
      Supervisor.start_link(__MODULE__, :ok)
    end

    def init(_) do
      children = [
        Examples.States.MyState
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
        Examples.States.Supervisor
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
    end
  end
  ```

  With that ceremony out of the way, you can now use the state in your scenes:

  ``` elixir
  defmodule Examples.Scene.TestScene do
    use SnapFramework.Scene, States: [Examples.States.MyState] # <-- add the state here

    alias Examples.States.MyState

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
      MyState.update(:dropdown_value, value) # <-- update the state values here
      {:noreply, scene}
    end
  end
  ```
  """
  import Scenic.PubSub

  defstruct __meta__: %{},
            assigns: %{}

  @callback setup(any) :: any

  @optional_callbacks setup: 1

  defmacro __using__(_) do
    quote do
      @behaviour SnapFramework.State
      use GenServer
      import SnapFramework.State
      import Scenic.PubSub

      @name __MODULE__

      def start_link(_) do
        GenServer.start_link(
          @name,
          %SnapFramework.State{__meta__: %{name: @name}, assigns: %{}},
          name: @name
        )
      end

      def init(state) do
        register(@name)
        {:ok, setup(state)}
      end

      def setup(state) do
        state
      end

      def get() do
        get(@name)
      end

      def assign(key_vals) do
        assign(@name, key_vals)
      end

      def handle_info(msg, state) do
        {:noreply, state}
      end

      def handle_cast(msg, state) do
        {:noreply, state}
      end

      def handle_call({:assign, key_vals}, _, state) do
        state = assign(state, key_vals)

        {:reply, state, state}
      end

      def handle_call(msg, from, state) do
        {:reply, state, state}
      end

      defoverridable setup: 1, handle_info: 2, handle_cast: 2, handle_call: 3
    end
  end

  def assign(name, key_vals) when is_atom(name) do
    GenServer.call(name, {:assign, key_vals})
  end

  def assign(%__MODULE__{__meta__: %{name: name}, assigns: assigns} = state, key_vals) do
    assigns =
      Enum.reduce(key_vals, assigns, fn {key, val}, acc ->
        Map.put(acc, key, val)
      end)

    publish(name, assigns)
    %__MODULE__{state | assigns: assigns}
  end
end
