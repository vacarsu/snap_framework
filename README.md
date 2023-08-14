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