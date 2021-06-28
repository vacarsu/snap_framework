defmodule SnapFramework.Scene do
  require Logger

  @optional_callbacks setup: 1

  @callback process_call(msg :: map, from :: GenServer.from, state :: map) :: {term :: atom, state :: map}
  @callback process_info(msg :: any, state :: map) :: {term :: atom, state :: map}
  @callback process_cast(msg :: any, state :: map) :: {term :: atom, state:: map}
  @callback process_input(input :: any, context :: any, state :: map) :: {term :: atom, state :: map}
  @callback process_event(event :: any, from_pid :: any, state :: map) :: {term :: atom, state :: map}
  @callback setup(state :: map()) :: map()

  defmacro __using__(name: name, template: template, state: state) do
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
      @state unquote(state)

      @using_effects false
      @effects_registry %{}

      @before_compile SnapFramework.Scene

      def process_call(msg, from, state), do: {:noreply, state}
      def process_info(msg, state), do: {:noreply, state}
      def process_cast(msg, state), do: {:noreply, state}
      def process_input(input, context, state), do: {:noreply, state}
      def process_event(event, from_pid, state), do: {:cont, state}
      def setup(state), do: state

      defoverridable process_call: 3,
                     process_info: 2,
                     process_cast: 2,
                     process_input: 3,
                     process_event: 3,
                     setup: 1
    end
  end

  defmacro __using__([name: name, template: template, state: state, opts: opts]) do
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
      @state unquote(state)

      @using_effects false
      @effects_registry %{}

      def process_call(msg, from, state), do: {:noreply, state}
      def process_info(msg, state), do: {:noreply, state}
      def process_cast(msg, state), do: {:noreply, state}
      def process_input(input, context, state), do: {:noreply, state}
      def process_event(event, from_pid, state), do: {:cont, state}
      def setup(state), do: state

      defoverridable process_call: 3,
                     process_info: 2,
                     process_cast: 2,
                     process_input: 3,
                     process_event: 3,
                     setup: 1
    end
  end

  defmacro use_effect([on_click: ids], term, effects) when is_list(ids) do
    quote location: :keep, bind_quoted: [ids: ids, term: term, effects: effects] do
      if not @using_effects do
        @using_effects true
        SnapFramework.Macros.scene_handlers()
      end

      for cmp_id <- ids do
        def process_event({:click, unquote(cmp_id)} = event, _from_pid, state) do
          state =
            Enum.reduce(unquote(effects), state, fn action, acc ->
              case action do
                {:set, set_actions} ->
                  Enum.reduce(set_actions, acc, fn {key, value}, s_acc ->
                    Map.put(s_acc, key, value)
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
            :noreply -> {unquote(term), state}
            :cont -> {unquote(term), event, state}
            :halt -> {unquote(term), state}
            _ -> {unquote(term), state}
          end
        end
      end
    end
  end

  defmacro use_effect([state: ks], actions) do
    quote location: :keep, bind_quoted: [ks: ks, actions: actions] do
      if not @using_effects do
        @using_effects true
        SnapFramework.Macros.scene_handlers()
      end

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

  defmacro __before_compile__(env) do
    caller = __CALLER__
    template = Module.get_attribute(env.module, :template)
    file = File.read!(template)
    quote location: :keep do
      # EEx.function_from_file(:def, :render, @template, [:assigns], engine: SnapFramework.Engine)

      def init(_, _) do
        # [init_graph] = render(state: state)
        state =
          @state
          |> Map.put_new(:module, unquote(caller.module))
          |> setup()

        info =
          Keyword.merge(
            [assigns: [state: state], engine: SnapFramework.Engine],
            [file: unquote(caller.file), line: unquote(caller.line), trim: true]
          )

        graph =
          SnapFramework.Engine.compile_string(unquote(file), [assigns: [state: state]], info, __ENV__)

        state =
          state
          |> Map.put_new(:graph, graph)

        {:ok, state, push: state.graph}
      end

      SnapFramework.Macros.effect_handlers()
    end
  end
end
