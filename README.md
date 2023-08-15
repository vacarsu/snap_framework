## Get Started

Add Snap to your application.

``` elixir
{:snap_framework, "~> 0.2.0-beta.1"}
```

Inital setup is the same as any Scenic app.

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
      ~G"""
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
      """
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
      ~G"""
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
      """
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

    def mount(scene) do
      update_child(scene, :dropdown, {scene.assigns.dropdown_opts, "Option 2"})
      scene
    end

    def render(assigns) do
      ~G"""
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
      """
    end

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      {:noreply, assign(scene, dropdown_value: value)}
    end
  end
  ```

  ## Components

    SnapFramework.Component works similarly to Scenes, with the adition of a name and type option. The name option is used to build a helper function for use when adding the component to a non SnapFramework managed scene or component. Type is used to build define the type of data that should be passed to the component, and build the necessary validation functions.

    Below is an example of a button component that renders children. We give it a name of button and a type of tuple. The tuple type means that the component will expect a tuple of the form `{width, height}`. The data is then used to define the size of the rounded rectangle.
    SnapFramework automatically attaches the data to the scene assigns.

    ``` elixir
    defmodule Examples.Component.Button do
      use SnapFramework.Component,
        name: :button,
        type: :tuple,
        opts: []

      @impl true
      def mount(scene) do
        send_parent(scene, {:test, :test})
        scene
      end

      @impl true
      def process_event({:click, :btn}, _, scene) do
        {:noreply, assign(scene, button_text: "clicked")}
      end

      def process_event(_, _, scene) do
        {:noreply, scene}
      end

      @impl true
      def render(assigns) do
        ~G"""
        <%= graph font_size: 20 %>

        <%= primitive Scenic.Primitive.RoundedRectangle,
            @data,
            translate: {0, 0},
            id: :bg
        %>

        <%= @children %>
        """
      end
    end
    ```

    The component can then be used in a scene like so.

    ``` elixir
    defmodule Example.Scene.MyScene do
      use SnapFramework.Scene

      def setup(scene) do
        assign(scene,
          button_text: "click me"
        )
      end

      def render(assigns) do
        ~G"""
        <%= graph font_size: 20 %>

        <%= component Examples.Component.Button, {100, 50} do %>
          <%= primitive Scenic.Primitive.Text,
              @button_text,
              id: :button_text,
              translate: {20, 20}
          %>
        <% end %>
        """
      end

      def process_event({:click, :button}, _, scene) do
        {:noreply, assign(scene, button_text: "clicked")}
      end
    end
    ```

    To pass a Text primitive to the component we use the `do` block. The component will then render the children in the `@children` variable.

    The beautiful thing about having the text in the assigns is that we can change it in the process_event callback and it will automatically update the graph, even though the primitive is technically in the Button's scene. This is because when assigns change we simply rebuild the graph and let scenic handle the graph diffing.

    ## Grids and Layouts

    The SnapFramework Engine has a few helpers for building grids and layouts. These helpers are not required, but they do make it easier to build complex layouts.

    ### Grid

    Grid requires to intermediary blocks called `row` and `col`. You can place components and primitives within these to build grids.

    Let's make a grid of button components using scenics provided button component.

    ``` elixir
    defmodule Example.Component.Grid do
      use SnapFramework.Component,
        name: :grid

      def setup(scene) do
        assign(scene,
          btn_text: "Button"
        )
      end

      def render(assigns) do
        ~G"""
        <%= graph font_size: 20 %>

        <%= grid item_width: 300, item_height: 300, padding: 2, rows: 4, cols: 3 do %>
          <%= row do %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_1 %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_2 %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_3 %>
          <% end %>
          <%= row do %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_4 %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_5 %>
          <% end %>
          <%= row do %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_6 %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_7 %>
            <%= component Scenic.Component.Button, @btn_text, id: :btn_8 %>
          <% end %>
        <% end %>
        """
      end
    end
    ```

    We define a grid with 4 rows and 3 columns. We then define 3 rows, each with some buttons. The Grid will automatically position the buttons in the grid. Optionally you can provide the grid with a `translate` option to position the grid.

    ### Layout

    Layout is similar to grid, but instead of defining the width and height each item take up in the grid, you define the overall width and height of the layout and the width and height of each individual component on the components themselves. This allows you to have different sized components and the layout will automatically position them without overlap.

    ``` elixir
    defmodule Example.Component.Layout do
      use SnapFramework.Component,
        name: :layout

      def setup(scene) do
        assign(scene,
          btn_text: "Button"
        )
      end

      def render(assigns) do
        ~G"""
        <%= graph font_size: 20 %>

        <%= layout width: 300, height: 300, padding: 1 do %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_1, width: 80, height: 40 %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_2, width: 80, height: 40 %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_3, width: 80, height: 40 %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_4, width: 80, height: 40 %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_5, width: 80, height: 40 %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_6, width: 80, height: 40 %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_7, width: 80, height: 40 %>
          <%= component Scenic.Component.Button, @btn_text, id: :btn_8, width: 80, height: 40 %>
        <% end %>
        """
      end
    end
    ```

    ## Caveats

    ### IDs

    The the above you may have noticed ids were used on every primitive/component in a template. SnapFramework has this requirement that every "element" have a unique id due to how Scenic handles rebuilds of graphs. Scenic assigns unique ids to scenes which are used to determine whether or not a scene should be taken down or not among other things. This means when SnapFramework rebuilds a graph scenic will take down the entire tree of genservers then start them back up due to the reassignation of unique ids. This leads to sever performance issues as well as errors when trying to send messages to genservers that are still reinitializing.

    SnapFramework works around this by requiring unique ids on every element to reassign the old scene uids back onto the rebuilt graph. This means that if you have a component that is used in multiple places you will need to provide a unique id for each instance of that component. This is a bit of a pain, but it is the only way to get around the performance issues and errors.

    I am open to suggestions on how to improve this.