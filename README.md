## Get Started

Add Snap to your application.

``` elixir
{:snap_framework, "~> 0.1.0-alpha.2"}
```

Inital setup is the same as any Scenic app.

## Overview

  SnapFramework.Scene aims to make creating Scenic scenes and components easier as well as add more power overall to graph updates and nesting components,
  and comes with a lot of convenient features. See Scenic.Scene docs for more on scenes.

  Creating a scene is pretty straight forward.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene

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
  end
  ```

  Having just the above should be enough to get the scene rendering.
  Whenever you change one of the variables used in the template SnapFramework will automatically rebuild the graph and push it.

  ## Setup and Mount Callbacks

  If you need to do some special setup, like request input, subscribe to a PubSub service, or add some runtime assigns. You can do that in the setup callback.
  It gives you the scene struct and should return a scene struct.

  The setup callback runs before the graph is initialized. So any added or modified assigns will be included in the template.
  The graph however is not included on the scene yet.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene

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

  If you need to do something after the graph is initialized, you can use the mounted callback.
  Like the setup callback it gives you the scene, and should return a scene.

  Usually this is for sending events to child components.

  ``` elixir
  defmodule Example.Scene.MyScene do
    use SnapFramework.Scene

    use_effect :dropdown_value, :on_dropdown_value_change

    def setup(scene) do
      Scenic.PubSub.subscribe(:pubsub_service)

      assign(scene, new_assign: true)
    end

    def mounted(scene) do
      # do something after graph has been initialized.
    end

    def process_event({:value_changed, :dropdown, value}, _, scene) do
      {:noreply, assign(scene, dropdown_value: value)}
    end
  end
  ```