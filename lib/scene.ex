defmodule SnapFramework.Scene do
  require Logger

  @optional_callbacks setup: 1

  @callback process_call(msg :: map, from :: GenServer.from, scene :: map) :: {term :: atom, scene :: map}
  @callback process_info(msg :: any, scene :: map) :: {term :: atom, scene :: map}
  @callback process_cast(msg :: any, scene :: map) :: {term :: atom, scene:: map}
  @callback process_input(input :: any, id :: atom, scene :: map) :: {term :: atom, scene :: map}
  @callback process_event(event :: any, from_pid :: any, scene :: map) :: {term :: atom, scene :: map}
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
      @external_resource @template
      @state unquote(state)

      @using_effects false
      @effects_registry %{}

      @before_compile SnapFramework.Scene

      def terminate(_, scene), do: {:noreply, scene}
      def process_call(msg, from, scene), do: {:noreply, scene}
      def process_info(msg, scene), do: {:noreply, scene}
      def process_cast(msg, scene), do: {:noreply, scene}
      def process_input(input, id, scene), do: {:noreply, scene}
      def process_event(event, from_pid, scene), do: {:cont, scene}
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
      @external_resource @template
      @state unquote(state)

      @using_effects false
      @effects_registry %{}

      def terminate(_, scene), do: {:noreply, scene}
      def process_call(msg, from, scene), do: {:noreply, scene}
      def process_info(msg, scene), do: {:noreply, scene}
      def process_cast(msg, scene), do: {:noreply, scene}
      def process_input(input, id, scene), do: {:noreply, scene}
      def process_event(event, from_pid, scene), do: {:cont, scene}
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

      def init(scene, _, _) do
        scene =
          scene
          |> assign(
            state: @state
              |> Map.put_new(:module, unquote(caller.module))
              |> setup
          )

        {:ok, recompile(scene)}
      end

      SnapFramework.Macros.effect_handlers()

      def recompile(scene) do
        info =
          Keyword.merge(
            [assigns: [state: scene.assigns.state], engine: SnapFramework.Engine],
            [file: unquote(caller.file), line: unquote(caller.line), trim: true]
          )

        compiled_list =
          SnapFramework.Engine.compile_string(unquote(file), [assigns: [state: scene.assigns.state]], info, __ENV__)

        graph = build_graph(compiled_list)

        scene
        |> assign(graph: graph)
        |> push_graph(graph)
      end
    end
  end

  def build_graph(list) do
    Logger.debug(inspect list, pretty: true)
    Enum.reduce(list, %{}, fn item, acc ->
      if item != "\n" do
        case item do
          [type: :graph, opts: opts] -> Scenic.Graph.build(opts)

          [type: :component, module: module, data: data, opts: opts] ->
            acc |> module.add_to_graph(data, opts)

          [type: :component, module: module, data: data, opts: opts, children: children] ->
            acc |> module.add_to_graph(data, Keyword.put_new(opts, :children, children))

          [type: :primitive, module: module, data: data, opts: opts] ->
            acc |> module.add_to_graph(data, opts)

          list ->
            if is_list(list) do
              Enum.reduce(list, acc, fn child, acc ->
                case child do
                  [type: :graph, opts: opts] -> Scenic.Graph.build(opts)

                  [type: :component, module: module, data: data, opts: opts] ->
                    acc |> module.add_to_graph(data, opts)

                  [type: :component, module: module, data: data, opts: opts, children: children] ->
                    acc |> module.add_to_graph(data, Keyword.put_new(opts, :children, children))

                  [type: :primitive, module: module, data: data, opts: opts] ->
                    acc |> module.add_to_graph(data, opts)

                  _ -> acc
                end
              end)
            else
              acc
            end
        end
      else
        acc
      end
    end)
  end

  # defmacro slot(graph, cmp, data) do
  #   Logger.debug("component slot hit")
  #   Logger.debug(inspect data)
  #   data = Macro.expand_once(data, __CALLER__)
  #   Logger.debug(inspect data)
  #   quote do
  #     var!(graph_val) =
  #       unquote(cmp)(unquote(graph), unquote(data))
  #   end
  # end

  # defmacro slot(graph, cmp, data, opts) do
  #   Logger.debug("component slot hit")
  #   Logger.debug(inspect data)
  #   data = Macro.expand_once(data, __CALLER__)
  #   Logger.debug(inspect data)
  #   quote do
  #     var!(graph_val) =
  #       unquote(cmp)(unquote(graph), unquote(data), unquote(opts))
  #   end
  # end
end
