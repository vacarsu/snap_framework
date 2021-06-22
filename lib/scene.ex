defmodule SnapFramework.Scene do
  require Logger

  defmacro __using__(name: name, template: template, state: state) do
    quote do
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
      @components Components
      @primitives Primitives
      @state unquote(state)

      @using_effects false
      @effects_registry %{}

      @before_compile SnapFramework.Scene
    end
  end

  defmacro use_effect([on_click: ids], term, effects) when is_list(ids) do
    quote location: :keep, bind_quoted: [ids: ids, term: term, effects: effects] do
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

  defmacro use_effect([on_changed: ks], actions) do
    quote location: :keep, bind_quoted: [ks: ks, actions: actions] do
      @effects_registry Enum.reduce(ks, @effects_registry, fn k, acc ->
        if Map.has_key?(acc, k) do
          actions = Enum.reduce(actions, %{}, fn {a_key, a_list}, a_acc ->
            if Map.has_key?(acc[k], a_key) do
              Map.put(acc[k], a_key, [acc[k][a_key] | a_list])
            else
              Map.put_new(acc[k], a_key, a_list)
            end
          end)
        else
          actions = Enum.reduce(actions, %{}, fn {a_key, a_list}, a_acc ->
            Map.put_new(a_acc, a_key, a_list)
          end)
          Map.put_new(acc, k, actions)
        end
      end)

      if not @using_effects do
        SnapFramework.Macros.scene_handlers()
        @using_effects true
      end
    end
  end

  defmacro __before_compile__(_env) do
    caller = __CALLER__.module
    quote location: :keep do
      EEx.function_from_file(:def, :render, @template, [:assigns], engine: SnapFramework.Engine)

      def init(_, _) do
        [init_graph] = render(state: @state)
        state =
          @state
          |> Map.put_new(:module, unquote(caller))
          |> Map.put_new(:graph, init_graph)
        {:ok, state, push: state.graph}
      end

      if @using_effects do
        SnapFramework.Macros.effect_handlers()
      end
    end
  end
end
